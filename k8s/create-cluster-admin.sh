#!/usr/bin/env bash
set -e

## install k8s components
./install-k8s-components.sh

export SERVICE_ACCOUNT="mb-cluster-admin"
export DEFAULT_NAMESPACE="kube-system"

kubectl apply -f ./mb-cluster-admin-sa.yaml
kubectl apply -f ./mb-cluster-admin-rbac.yaml
kubectl apply -f ./mb-cluster-admin-secret.yaml

echo -e "\nPress enter to continue with the setup..."
read

export USER_TOKEN_VALUE=$(kubectl -n $DEFAULT_NAMESPACE get secret "${SERVICE_ACCOUNT}-token-secret" -o=go-template='{{.data.token}}' | base64 --decode)
export CURRENT_CONTEXT=$(kubectl config current-context)
export CURRENT_CLUSTER=$(kubectl config view --raw -o=go-template='{{range .contexts}}{{if eq .name "'''${CURRENT_CONTEXT}'''"}}{{ index .context "cluster" }}{{end}}{{end}}')
export CLUSTER_CA=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}"{{with index .cluster "certificate-authority-data" }}{{.}}{{end}}"{{ end }}{{ end }}')
export CLUSTER_SERVER=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}{{ .cluster.server }}{{end}}{{ end }}')

cat << EOF > k8s-mb-cluster-admin-config.yaml
apiVersion: v1
kind: Config
current-context: ${CURRENT_CONTEXT}
contexts:
- name: ${CURRENT_CONTEXT}
  context:
    cluster: ${CURRENT_CONTEXT}
    user: ${SERVICE_ACCOUNT}
    namespace: ${DEFAULT_NAMESPACE}
clusters:
- name: ${CURRENT_CONTEXT}
  cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
users:
- name: ${SERVICE_ACCOUNT}
  user:
    token: ${USER_TOKEN_VALUE}
EOF

echo -e "k8s resources created and kube-config generated. run: 'converge-kube-config.sh' script locally\n"

kubeadm token create --print-join-command
echo "join worker nodes using the command above ^"

sudo ip neigh flush all
echo "ARP cache cleared"