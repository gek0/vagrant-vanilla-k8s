#!/usr/bin/env bash

kubectl patch service argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch service argocd-server -n argocd -p '{"metadata": {"annotations": {"metallb.universe.tf/loadBalancerIPs": "192.168.56.52"}}}'
