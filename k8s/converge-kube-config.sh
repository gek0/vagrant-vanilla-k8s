#!/usr/bin/env bash

cp ~/.kube/config ~/.kube/config-backup

echo -e "\nKube config backup created. Press enter to continue with the setup..."
read

export KUBECONFIG=~/.kube/config:$(pwd)/k8s-mb-cluster-admin-config.yaml
kubectl config view --flatten > all-in-one-kubeconfig.yaml
mv all-in-one-kubeconfig.yaml ~/.kube/config

echo "kube config generated and ready!"