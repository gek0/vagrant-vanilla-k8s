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

### Install Vault resources
`helm install vault hashicorp/vault --values helm-vault-raft-values.yaml`


## Vault configuration

### Initialize vault-0 with one key share and one key threshold
```
kubectl exec vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > cluster-keys.json
```

# https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-raft
# https://github.com/hashicorp/vault-helm/issues/85
