# Hashicorp Vault example setup (dev environment)

- simple setup of Vault + example deployment to load the Secret from it

### Create namespace and storage class objects
`kubectl apply -f namesapce.yaml`
`kubectl apply -f storage-class.yaml`

### Add the HashiCorp Helm repository
`helm repo add hashicorp https://helm.releases.hashicorp.com`

### Update all the repositories to ensure helm is aware of the latest versions
`helm repo update`

### To verify, search repositories for vault in charts
```shell
helm search repo hashicorp/vault

NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                          
hashicorp/vault                         0.25.0          1.14.0          Official HashiCorp Vault Chart       
hashicorp/vault-secrets-operator        0.3.2           0.3.2           Official Vault Secrets Operator Chart
```

### Create Persistentvolumes (PVs) and Persistentvolumeclaims (PVCs) manually
`kubectl apply -f data-pv.yaml`
 - as HostPath storage is not really supported for Vault and much else, so bind the manually on each Worker node

### Install Vault resources
`helm install vault hashicorp/vault --values helm-vault-raft-values.yaml`
 - after Pods are in **Pending** state, SSH to Worker nodes and run `sudo chmod -R 757 /tmp/vault` to fix permission issues


## Vault configuration

- Initialize vault-0 with one key share and one key threshold
```
kubectl exec vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > cluster-keys.json
```
- store the Vault unseal key to variable
`VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)`
- unseal Vault in first Pod
`kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY`
- join the first Pod to Raft cluster
`kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200`
- and the second Pod
`kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200`
- now unseal the first one
`kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY`
- and the second one
`kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY`

### more info can be found here 
https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-raft


## Working with Vault secrets

- display root token
`jq -r ".root_token" cluster-keys.json`
- authenticate to Vault with it
`kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh`
- and now inside the Pod
`vault login`
- enable an instance of kv-v2 secret at path `secret`
`vault secrets enable -path=secret kv-v2`
- create a sample secret
`vault kv put secret/webapp/config username="user" password="pass"`
- verify that secret is there and its value
`vault kv get secret/webapp/config`
- enable the Kubernetes authentication method
`vault auth enable kubernetes`
- configure authentication for the API server endpoint
`vault write auth/kubernetes/config kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"`
- create the policy so that the secret can be read
`vault policy write webapp - <<EOF
path "secret/data/webapp/config" {
  capabilities = ["read"]
}
EOF`
- create k8s authentication role that connects the k8s Service Account and Vault policy
`vault write auth/kubernetes/role/webapp \
        bound_service_account_names=webapp \
        bound_service_account_namespaces=webapp \
        policies=webapp \
        ttl=24h`
- finally, exit the Vault cli
`exit`

## Create a sample application and test it out
- apply manifest for Namespace, Service Account and Deployment
`kubectl apply -f webapp.yaml`
- create a port-forward
`kubectl port-forward -n webapp $(kubectl get pod -n webapp -l app=webapp -o jsonpath="{.items[0].metadata.name}") 8080:8080`
- and test it
`curl http://localhost:8080`