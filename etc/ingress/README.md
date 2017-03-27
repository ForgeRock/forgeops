
# Ingress

Depending on where you run Kubernetes, there may or may not be an ingress controller
provided. On GKE and AWS, Kubernetes uses the native load balancers. If you
are deploying on bare metal or VirtualBox, etc. you may need to create your own. Note
that Minikube now includes a load balancer which you can enable using: 

```minikube addons ingress enable```

There is a controller here based on nginx here:

https://github.com/kubernetes/ingress