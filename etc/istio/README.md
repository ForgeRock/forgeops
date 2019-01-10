# Initital Istio support - Experimental

TODO: This readme will be moved once we finalize istio support.

NOTE: The steps below have already been completed in the eng_shared cluster. This is for reference only:


## Once per cluster tasks:

* Enable the "istio" addon in GKE. This is a managed istio service. See https://cloud.google.com/istio/docs/istio-on-gke/installing.
* Create an SSL cert request using  `kubectl apply -f cluster-cert.yaml`. This provisions a wildcard cert *.iam.forgeops.com

All traffic for istio services will be routed via this wildcard. We use convention: `$namespace.iam.forgeops.com`

## Per namespace tasks

* Make sure you have enabled istio injection on your namespace:  `kubectl label namespace my-namespace istio-injection=enabled`
* Deploy the frconfig chart and enable the istio gateway:

`helm upgrade -i my-frconfig --set domain=".forgeops.com",istio.enabled=true,certmanager.enabled=false`

Notes:

* you can disable cert manager, because we no longer need to install certs per namespace. There is a single wildcard cert for the cluster.
* Dont' use "my-frconfig", this is just an example. Use your own release name that is unique.

## Per service tasks

* Deploy IG (the only service that has been istio enabled so far)

`helm upgrade -i my-ig --set domain=".forgeops.com",istio.enabled=true openig`

Bring up openig:  `https://your-name.iam.forgeops.com/ig`
