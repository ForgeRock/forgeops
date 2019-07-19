# ForgeRock DevOps and Cloud Deployment

Kubernetes deployment for the ForgeRock platform.

** IMPORTANT: The current supported branch is release/6.5.2. The master branch is under development **

Please refer to the [Platform Documentation for 6.5](https://backstage.forgerock.com/docs/platform/6.5). In
particular refer to the [What's New section of the release notes.](https://backstage.forgerock.com/docs/platform/6.5/release-notes/#chap-rnotes-whats-new)

This GitHub repository is a read-only mirror of 
ForgeRock's [https://stash.forgerock.org/projects/CLOUD/repos/forgeops] (Bitbucket Server repository). Users
with BackStage accounts can make pull requests on our Bitbucket Server repository. ForgeRock does not 
accept pull requests on this GitHub mirror.

## Disclaimer

These samples are provided on an “as is” basis, without warranty of any kind, to the fullest extent
permitted by law. ForgeRock does not warrant or guarantee the individual success developers
may have in implementing the code on their development platforms or in
production configurations. ForgeRock does not warrant, guarantee or make any representations
regarding the use, results of use, accuracy, timeliness or completeness of any data or
information relating to these samples. ForgeRock disclaims all warranties, expressed or implied, and
in particular, disclaims all warranties of merchantability, and warranties related to the code, or any
service or software related thereto. ForgeRock shall not be liable for any direct, indirect or
consequential damages or costs of any type arising out of any action taken by you or others related
to the samples.

## Branches

The master branch targets
features that are still in development and may not be stable. Please checkout the
 branch that matches the targeted release.


For example, if you have the source checked out from git:

```bash
git checkout release/6.5.2
```

## Skaffold preview branch

The branch `skaffold-6.5` is a preview of the upcoming 7.x workflow that simplifies deployment
by bundling the product configuration into the docker image for deployment. This workflow speeds iterative
development and greatly simplifies the Kubernetes runtime manifests. It eliminates the need for "git" init containers
and the complexity around configuring different git repositories and branches in the helm charts.

The new workflow combines the previously 
independent `forgeops` and `forgeops-init` into a single git repository that holds configuration and Kubernetes
manifests.  See [README-skaffold.md](README-skaffold.md).

Documentation for this workflow is in progress. Please
 see  the [early access documentation](https://ea.forgerock.com/docs/platform/devops-guide-minikube/#devops-guide-minikube).

This preview branch enables the use of supported ForgeRock binaries in your 
 deployment. Adopting this workflow is recommended as it will ease transition to the 7.x platform. 


## Contents 

* `kustomize` - Kustomize manifests for deploying the platform. See [README-skaffold.md](README-skaffold.md)
* `helm/` - contains Kubernetes helm charts to deploy those containers. See the helm/README.md
* `etc/` - contains various scripts and utilities
* `bin/`  - Utility shell scripts to deploy the helm charts and create and manage clusters.



## Documentation 

The [Draft ForgeRock DevOps Guide](https://ea.forgerock.com/docs/platform/devops-guide-minikube/index.html#devops-implementation-env-about-the-env)
tracks the master branch, including information on the newer Kustommize/ Skaffold workflow.

The documentation for the current release can be found on
[backstage](https://backstage.forgerock.com/docs/platform).


## Setting a namespace

If you do not want to use the 'default' namespace, set your namespace using:
```
kubectl config set-context $(kubectl config current-context) --namespace=<insert-namespace-name-here>
```

The `kubectx` and `kubens` utilities are recommended.

## Troubleshooting

Refer to the toubleshooting chapter in the [DevOps Guide](https://backstage.forgerock.com/docs/platform/6/devops-guide/#chap-devops-troubleshoot).

Troubleshooting suggestions:

* The script `bin/debug-log.sh` will generate an HTML file with log output. Useful for troubleshooting.
* Simplify. Deploy a single product at a time (for example, ds), and make sure it is working correctly before deploying the next product. 
* Describe a failing pod using `kubectl get pods; kubectl describe pod pod-xxx`
    1. Look at the event log for failures. For example, the image can't be pulled.
    2. Examine all the init containers. Did each init container complete with a zero (success) exit code? If not, examine the logs from that failed init container using `kubectl logs pod-xxx -c init-container-name`
    3. Did the main container enter a crashloop? Retrieve the logs using `kubectl logs pod-xxx`.
    4. Did a docker image fail to be pulled?  Check for the correct docker image name and tag. If you are using a private registry, verify your image pull secret is correct.
    5. You can use `kubectl logs -p pod-xxx` to examine the logs of previous (exited) pods.
* If the pods are coming up successfully, but you can't reach the service, you likely have ingress issues:
    1. Use `kubectl describe ing` and `kubectl get ing ingress-name -o yaml` to view the ingress object.
    2. Describe the service using `kubectl get svc; kubectl describe svc xxx`.  Does the service have an `Endpoint:` binding? If the service endpoint binding is not present, it means the service did not match any running pods.
* Determine if your cluster is having issues (not enough memory, failing nodes). Watch for pods killed with OOM (Out of Memory). Commands to check:
    1. `kubectl describe node`
    2. `kubectl get events -w`
* Most images provide the ability to exec into the pod using bash, and examine processes and logs.  Use `kubectl exec pod-name -it bash`.
* If you wish to backup the directory server, the Kubernetes cluster must support a read-write-many (RWX) volume type, such as NFS, or Minikube's hostpath provisioner. You can describe persistent volumes using `kubectl describe pvc`. If a PVC is in a pending state, your cluster may not support the required storage class.
