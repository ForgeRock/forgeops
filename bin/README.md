First copy and edit your providers env file. For example
```
$ cp ../etc/gke-eng.template ../etc/gke-eng.cfg
$ vi ../etc/gke-env.cfg
```
If you have an existing kubernetes cluster that you want to use then edit the gke-up.sh cript and comment the create-cluster.sh line, otherwise continue to the next step

Run the gke-up.sh wrapper script
- This scripts creates the kubernes cluster for you
- It also adds a storage class
- It also adds a namespace
- It also creates a helm tiller and the associated RBAC object
- And finally it also adds any kubernetes secrets
