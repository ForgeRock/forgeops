# ForgeOps Security Profile

The security profile offers a starting point for utilizing pod security policies and network policies with the ForgeRock Identity Platform.

The objects may be added to any cluster, but won't be enforced until the controllers are enabled.

For example, for a GKE cluster:
```
gcloud beta container clusters update mycluster --enable-pod-security-policy

gcloud container clusters update mycluster --enable-network-policy
```

## Pod Security Policies

Enabling the pod security policy controller will require use of the `kustomize/base/security` as well as `kustomize/overlay/security`. The former creates policies, and the latter patches workloads to meet those policies.

The policies are set up such that workloads using the default service account are allowed to run if they operate as the ForgeRock uid `11111` and the `fsGroup` of `11111`, and all workloads have no privilege escalation (or attempt to obtain esclation).

The ForgeRock UI applications use a webserver (NGINX), which requires the use of root. The policy has a limited scope that NGINX can operate with root permissions. The `seccomp` profile limits the system calls that can be completed inside the container. 


## network policies

The supplied network policies are a starting point to use the ForgeRock Identity Platform. They are provided  in the kustomize/base/security profile and don't require the security overlay.

The policies limit only ingress network traffic in the namespace. The provide a "tiered" architecture:

1. UIs are available for public ingress but have no DS access.
2. AM/IDM are available for public ingress and for the UI application.
3. DS ingress can be from another DS (replication), from AM/IDM for the ds-idrepo, and CTS can only be accessed by AM.

We don't limit egress from any of the tiers. Ultimately, the egress configuration depends on:

* The application's configuration.
* Egress rules for social logins.
* External integrations.
* Additionally, access to DS backup storage will be highly variable.

