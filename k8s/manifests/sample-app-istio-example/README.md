# sample Flask application

- uses `digitalocean/flask-helloworld` to test out Istio functionality

- includes resource:
  - Namespace
  - Deployment
  - Service
  - Istio ingress configuration
    - VirtualService

### setup
- apply ordering: namespace -> all other resources
- add "192.168.56.51   sample-app.local.io" to your `/etc/hosts` file
- run ` curl -i sample-app.local.io`
  - sample respond:
```shell
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 13
server: istio-envoy
date: Fri, 13 Oct 2023 13:40:46 GMT
x-envoy-upstream-service-time: 2
x-envoy-decorator-operation: sample-app.sample-app.svc.cluster.local:80/*

Hello, World!
```