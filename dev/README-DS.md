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
