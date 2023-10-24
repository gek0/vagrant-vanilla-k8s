# ArgoCD deployment

- initial ArgoCD setup

- includes resource:
  - Namespace
  - all ArgoCD resources
  - Istio ingress configuration
    - VirtualService
    - DestinationRule
  - ConfigMap to start Istio in insecure mode (fixes Istio issue)

### setup
- apply ordering: namespace -> install.yaml -> all other resources
- run `./patch-argocd-service.sh` for exposing the service using Metallb
- add "192.168.56.52   argocd.local.io" to your `/etc/hosts` file
- open http://argocd.local.io in your browser
- run `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d` to get the initial password

### sample application deployment with ArgoCD
- apply resources in `sample-app` directory -> TODO / WIP