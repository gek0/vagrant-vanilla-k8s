#!/usr/bin/env bash
set -e

componentsDir="/root/k8s/components"

## install Flannel as CNI - custom fix for Vagrant included
##  https://medium.com/@anilkreddyr/kubernetes-with-flannel-understanding-the-networking-part-2-78b53e5364c7
kubectl apply -f ${componentsDir}/flannel/kube-flannel.yaml

## install Metrics Server - for HPA and VPA components
kubectl apply -f ${componentsDir}/metrics-server/components.yaml

## install istioctl and Istio ingress
cd /opt
curl -L https://istio.io/downloadIstio | sh -
istioDir=$(find /opt -maxdepth 1 -name "istio*" -type d)
ln -s $istioDir/bin/istioctl /usr/local/bin/
echo "istioctl is ready at $(which istioctl)"
istioctl install --skip-confirmation
kubectl apply -f ${componentsDir}/istio/gateway.yaml

## install MetalLB (emulated network loadbalancer)
##  https://metallb.universe.tf/installation/
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

kubectl apply -f ${componentsDir}/metallb/metallb-native.yaml
kubectl apply -f ${componentsDir}/metallb/configuration.yaml

echo -e "\nall k8s components installed and ready"