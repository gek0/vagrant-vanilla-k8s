# Vanilla K8s in Vagrant
![vag](https://github.com/gek0/vagrant-vanilla-k8s/assets/8794964/187cf698-ebfb-4dec-8d09-3582fb0ca795)

- latest K8s install (v1.28 at the time) using containerd runtime on Vagrant nodes

## Vagrant part
- run `vagrant up` in root directory to provision a single master Node (control-plane)
  - by default 2 (two) worker Nodes will be provisioned (can be modified with `WorkerNodeCount` variable)
  - `master-provision.sh` is used to configure the control-plane node and `worker-provision.sh` for worker Nodes
  - **master-node** has needed tools + some additional testing/debugging tools and binaries for administrative work

## Scripts and configuration part
- connect to **master-node** using `vagrant ssh master-node`
- run `sudo -i` and inside /root/k8s/ directory run `./create-cluster-admin.sh`
  - this will configure Admin user for cluster and install all needed components
    - Flannel CNI
    - Metrics Server
    - Istio ingress + istioctl
    - MetalLB
- [OPTIONAL]: if you'd like to manage the cluster from host using your tools run `./converge-kube-config.sh` to update local ./kube/config file
  - `k9s` and `kubectl` are also installed in **master-node** so cluster can be configured from there directly
- join worker Nodes using the token provided with first script

## K8s part
- use manifests in `k8s/manifests` directory per your liking, everything provided as learning examples

## Troubleshooting part
- [ISSUE]: Vagrant network sometimes is known to hang with "protocol not supported" error and prevents guest-to-guest communication and even host-to-guest one
  - only ICMP works at that moment
  - can prevent joining worker Nodes to k8s cluster
  - can prevent managing the cluster from host
  - [FIX]: run `sudo ip neigh flush all` on **master-node** to clear ARP cache and try again
