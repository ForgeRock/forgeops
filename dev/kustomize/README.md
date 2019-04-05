# Kustomize POC

This is a POC to experiment with [Kustomize](https://kubectl.docs.kubernetes.io/pages/app_customization/introduction.html)  and how we might organize and structure our assets. 

[ship](https://www.replicated.com/ship/) was used to generate the kustomize from our exiting helm charts.

The organization is experimental - feedback welcome.

If you are not familiar with Kustomize I strongly suggest reading the doc link above - the explanation below will make a lot more sense.

TL;DR; - Kustomize is based on patching (json patch and strategic merge patch) and overlays.
You create base assets (K8S yaml files), and patch those. Those in turn can be used as a new base, and so on. You can nest these to any 
arbitrary depth.

## Organization

Looking at this from the bottom up, we have the foundational product images. Currently for this POC there are:

* frconfig - basic config maps that all products need
* ig, am, idm, ds and amster  - Product K8S artifacts
* idrepo - a copy of the ds/ folder - specifically designed for the DS idrepo instance


The product images are "vanilla" and are not customized for a specific purpose. Within each product folder there is a `base` configuration, plus a number of overlay variants. The variants are there to deploy the product in different configurations. For example, perhaps IG will use vert.x instead of tomcat. We would have two different overlays for those two different configurations.

Moving up a level, we have the `platform` folder which pulls all the products together as a platform. For example, AM, IDM, DS and IG. There
maybe several variants of the platform. For example, SaaS might have an extra UI component. The platform references the product Kustomize overlays to pull together all components in a unit.

Moving up one more level, we have the environment. For exmaple `env/test`. This is where we set the overlays and patches for the final deployment. Things like resource limits (small t-shirt vs. large), namespace, external ingress FQDN, and so on. We can imagine having dev, test, qa, and prod environments.   DIY customers can use the env/ as a starting point for their own deployments.


Starting from the top to the bottom, the bundle that gets deployed is something like this:

```
env/test ---> platform/dev -->  product {am,idm,..} 
```


## Viewing the Kustomize output

You can use `kubectl`  (version 1.14 or higher) or `kustomize`


```bash
cd kustomize/env
# This will show you what is sent to the cluster
kubectl kustomize small
```

## Images

The images referenced in the kustomize files are generic (example: `am`, `ig`), and not
specific to a registry ( `gcr.io/forgerock-io/am:7.0.1` ).


We can not directly deploy these generic images, because we need a docker image
that has the configuration "baked in". This is where skaffold comes in to the picture.
Skaffold will build new docker images that include configuration, and will 
"fix up" the docker image tags in kustomize, replacing the generic names (`am`) with
a specific image name, tagged with a sha hash (dev mode) or a git hash (prod).

See the skaffold [../README.md](../README.md).

## Further Discussion

 * This demonstrates a directory based organization. You can also use git branching. See [this discussion](https://kubectl.docs.kubernetes.io/pages/app_composition_and_deployment/diffing_local_and_remote_resources.html)
