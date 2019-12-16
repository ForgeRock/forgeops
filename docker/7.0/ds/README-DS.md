# Customizing DS Docker images

There are a number of ways to customize the DS Docker images in order to
contain additional indexes, log configuration, extensions or schema.

1. Add dsconfig RUN commands in the Dockerfile: this is perhaps the
   simplest approach. Figure out which configuration changes you'd like
   to make and add them to the Dockerfile's RUN command sequence.
   Remember to use the --offline flag.

2. Add schema files or extensions into the Dockerfile. Schema files
   should go in docker/ds/(cts|idrepo)/config/schema.

3. Gitops: first mount the Docker source locations into your locally
   running Minikube:
   ```
   $ minikube mount docker/ds/cts:/tmp/docker-ds-cts &
   $ minikube mount docker/ds/idrepo:/tmp/docker-ds-idrepo &
   ```
   Then deploy forgeops to Minikube:
   ```
   # Or use 'skaffold run -p dev' if you want to perform multiple changes
   $ skaffold dev -p dev
   ```
   Then configure a running DS instance like this:
   ```
   $ kubectl exec ds-cts-0 -it dsconfig

    >>>> Specify OpenDJ LDAP connection parameters

    Password for user 'uid=admin':

    >>>> OpenDJ configuration console main menu

    What do you want to configure?

        1)   Access Control Handler               22)  Key Manager Provider
        2)   Access Log Filtering Criteria        23)  Log Publisher
        3)   Account Status Notification Handler  24)  Log Retention Policy
    ..
   ```
   Once customizations are complete, quit dsconfig and review changes in
   your local workspace:
   ```
   $ git status
   On branch master
   Your branch is up to date with 'origin/master'.

   Changes not staged for commit:
     (use "git add <file>..." to update what will be committed)
     (use "git checkout -- <file>..." to discard changes in working directory)

	   modified:   docker/cts/config/config.ldif

   no changes added to commit (use "git add" and/or "git commit -a")
   ```
   Commit your changes and submit pull-request!

## Creating sample users for the idrepo

The script [idrepo/bin/make-users.sh](idrepo/bin/make-users.sh) creates sample users for benchmarking.

Run skaffold with [idrepo/skaffold.yaml](idrepo/skaffold.yaml) to create sample users:

```bash
# Edit the idrepo/bin/make-users.sh script to set the default # of users
cd idrepo
# Run skaffold with the make-users profile. Set your own --default-repo here
skaffold --default-repo gcr.io/engineering-devops -p make-users dev
# Scale up to the eventual number of desired pods - this will prime each backend pvc
kubectl scale --replicas=3  statefulset ds-idrepo

# When you are done, kill skaffold - the PVC volumes are now initialized with sample data
```

It should take approx. 10 minutes to create 10M users. When you are done make sure 
you retain the pvc volumes. These volumes now contain sample users - and when 
you run the idrepo statefulset it will attach the existing pvcs.

Note that the PVC volume size you select during the intialization must match the desired size 
when you run the benchmark.  Set the PVC volume size in
the [idrepo-make-users statefulset](../../../../kustomize/base/7.0/ds/idrepo-make-users) 

## Running the ds micro benchmark

```bash
cd dsutil
# Edit k8s/bench-job.yaml paramters with the number of users, benchmark time, etc.
skaffold dev  --default-repo gcr.io/engineering-devops -p ds-bench

```

## Running the utility image

The dsutil image gives you a bash shell into a pod that has all the ds tools installed.

To run:

```bash
cd dsutil
skaffold dev  --default-repo gcr.io/engineering-devops
# You can now exec into the dsutil pod
kubectl exec dsutil-xxxx -it bash
# Run ldap util commands...
```