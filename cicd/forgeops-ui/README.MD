# Forgeops UI

Web app for deploying Forgerock products into Kubernetes cluster. Provides a way to run sample smoke tests and display results.

## Installation 

First you must build a docker image. 
Run following command: `docker build -t <your_registry>/forgeopsui:latest .`

Now you need to configure a helm chart. Edit a `forgeops-ui-helm/values.yaml` and modify image
tag to reflect your built image. 

Do a `helm install --name=forgeopsui forgeops-ui-helm` from this folder.

Look into your namespace and get a pod name:
```
~ kubectl get pods                                                                                                                                          
NAME                                   READY     STATUS    RESTARTS   AGE
ui-forgeops-ui-helm-544dc5dcbd-qg7jh   1/1       Running   0          13m
```

Next use port-forward to expose port and access ui via browser on localhost:5000
`kubectl port-forward ui-forgeops-ui-helm-544dc5dcbd-qg7jh 5000:80`

## Configuring and deploying products

When you access UI, you are presented with option to configure products. You can either configure products 
by hand or load one of predefined configurations and modify it. 

Once you configure products, you must save the config and then proceed to Deployment tab to deploy products.
Optionally, if you use smoke tests config, you can run the smoke tests and wait for results to appear on Tests tab

## Removing deployment

Simply click remove deployment on the Deployment tab

## Notes

- When you deploy products with this ui and remove ui deployer, you won't be able to remove/control products with this ui
anymore
- When setting global domain, make sure that products have global switch enabled to use configured domain