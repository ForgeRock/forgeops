# Import ldif sample

This is a sample Job that will import DS data in ldif format. You will
need to modify this example for your usage.

The relevant points:
* The job expects the ldif files to be on an `ldif` PVC. You must create a process
 to copy these files to a pvc. An example is provided that copies files from cloud storage
* The DS data pvc can not be in use if you are trying to import ldif data to it. You can either scale DS to zero, and directly mount the pvc
  (for example, data-ds-idrepo-0), or create a new PVC from a volume snapshot
* Once the ldif is imported, you can create a volume snapshot of the pvc, and use this
 snapshot to initialze new DS instances.


To import:

* Assuming you retained the `ldif` and `data-ds-clone` PVC from above, proceed. Otherwise, arrange for the ldif files to be on the PVC
* Run the import job: `kubectl apply -k .`
* Observe the logs. The data should be imported again.

At this point you could create another snapshot from the data-ds-clone, and use that snapshot to reinitialize
a new DS cluster.

