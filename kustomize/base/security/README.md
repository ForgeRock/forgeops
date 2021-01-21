# ForgeOps Security Profile

The security profile offers a starting point for utilizing pod security policies
and network policies with the ForgeRock Identity Platform.

The policies may be added to any cluster, but aren't enforced until the 
controllers are enabled.

For example, for a GKE cluster:
```
gcloud beta container clusters update mycluster --enable-pod-security-policy
gcloud container clusters update mycluster --enable-network-policy
```

## Pod Security Policies

Enabling the pod security policy controller requires using the 
`kustomize/base/security` base and the `kustomize/overlay/security` overlay. 
The base creates policies, and the overlay patches workloads to meet those 
policies.

The policies are set up so that workloads using the default service account 
can run if:

* They operate as the ForgeRock uid `11111` and the `fsGroup` of `11111`
* All workloads have no privilege escalation (or attempt to obtain escalation).

The ForgeRock UI applications use the NGINX web server, which requires using
the `root` account. The policy has a limited scope that NGINX can operate with 
root permissions. The `seccomp` profile limits the system calls that can be 
completed inside the container. 

Note that pod security policies are scheduled to be 
[deprecated in version 1.21 of Kubernetes, and will be removed from Kubernetes in version 1.25](https://github.com/kubernetes/kubernetes/pull/97171). 

## Network Policies

The supplied network policies are a starting point to use with the ForgeRock 
Identity Platform. They are provided in the `kustomize/base/security` profile,
and don't require the `security` overlay.

These policies limit only ingress network traffic in the namespace. They provide
a "tiered" architecture:

1. UIs are available for public ingress, but do not have DS access.
1. AM and IDM are available for public ingress, and for the UI application.
1. DS ingress can be from another DS (replication), from AM and IDM (the 
   `ds-idrepo` directory), and by AM only (the `ds-cts` directory)

There's no limit on egress from any of the tiers. Ultimately, the egress 
configuration depends on:

* The application's configuration.
* Egress rules for social logins.
* External integrations.

Additionally, access to DS backup storage will be highly variable.

