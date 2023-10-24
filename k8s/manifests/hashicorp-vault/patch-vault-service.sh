#!/usr/bin/env bash

kubectl patch service vault -n vault -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch service vault -n vault -p '{"metadata": {"annotations": {"metallb.universe.tf/loadBalancerIPs": "192.168.56.53"}}}'
