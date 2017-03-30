# Helm Chart for OpenAM 

This chart is the runtime chart for OpenAM. It assumes the configuration store 
is in place and has been configured.

# Getting Started

Edit the values.yaml for your environment. You can use the provided defaults.

If you have not already installed Helm to your Kubernetes cluster, run
```
 helm init
 ```

Then install this chart using:
```
helm install openam-runtime
```

If you want to see what will happen instead, use the --dry-run -debug option
with the helm install command. This will dump the expanded values

An ingress is defined for OpenAM.  You must have an ingress controller
deployed if you want to reach OpenAM via the external ingress route.  Otherwise,
you can use the nodeport (30080). The nginx script in this project (fretes/ingress)
will deploy an ingress controller.

After provisioning, put the IP address of your Kubernetes cluster
in your /etc/hosts file. For example:
```
192.168.2.16 openam.example.com
```
