# DS Customization and Utilities

## Customized DS Docker Images

There are a number of ways to customize the DS Docker images in order to
contain additional indexes, log configuration, extensions or schema.

1. **Add dsconfig RUN commands in the Dockerfile**. This is the simplest 
   approach. Figure out which configuration changes you'd like to make, and then 
   add them to the Dockerfile's RUN command sequence. Remember to use the 
   `--offline` flag.

2. **Add schema files or extensions into the Dockerfile**. Place schema files  
   in the `docker/ds/(cts|idrepo)/config/schema` directory.

3. **Gitops**. First, mount the Docker source locations into your 
   locally-running Minikube VM:
   
   ```
   minikube mount docker/ds/cts:/tmp/docker-ds-cts &
   minikube mount docker/ds/idrepo:/tmp/docker-ds-idrepo &
   ```

   Next, deploy the platform.
   
   Then, configure a running DS instance using the `dsconfig` command:
   
   ```
   kubectl exec ds-cts-0 -it dsconfig

    >>>> Specify OpenDJ LDAP connection parameters

    Password for user 'uid=admin':

    >>>> OpenDJ configuration console main menu

    What do you want to configure?

        1)   Access Control Handler               22)  Key Manager Provider
        2)   Access Log Filtering Criteria        23)  Log Publisher
        3)   Account Status Notification Handler  24)  Log Retention Policy
    ..
   ```
   
   After you've made all your customizations, quit the `dsconfig` session. 
   
   Review changes in your local workspace:
   
   ```
   git status
   On branch master
   Your branch is up to date with 'origin/master'.

   Changes not staged for commit:
     (use "git add <file>..." to update what will be committed)
     (use "git checkout -- <file>..." to discard changes in working directory)

	   modified:   docker/cts/config/config.ldif

   no changes added to commit (use "git add" and/or "git commit -a")
   ```
   
   Commit your changes and submit a pull request!

## Sample Users

The [make-users.sh](idrepo/bin/make-users.sh) script lets you create sample 
users for benchmarking or other purposes.

Exec into each `ds-idrepo` pod and run the script with the desired number of 
users. For example:

```bash
kubectl exec ds-idrepo-0 -it make-users.sh 1000000
kubectl exec ds-idrepo-1 -it make-users.sh 1000000
kubectl exec ds-idrepo-2 -it make-users.sh 1000000
```

## Utility image (`dsutil`)

The `dsutil` image provides a bash shell into a pod that has all the DS tools 
installed. Utility scripts are located in the `/opt/opendj/bin` directory.

To build the `dsutil` image:

```
gcloud builds submit .
```

To run the `dsutil` image:

```
kubectl run -it dsutil --image=gcr.io/forgeops-public/ds-util --restart=Never -- bash
```

To create a shell alias for the above command:

```
alias fdebug='kubectl run -it dsutil --image=gcr.io/forgeops-public/ds-util --restart=Never -- bash'
```