# Export ldif sample

This is a sample Job that will export DS data to ldif format. You will
need to modify this example for your usage.

The relevant points:

* The PVC containing the directory binary data can either be the STS PVC
 (for example, data-ds-idrepo-0), or a PVC created from a volume snapshot.
  A volume snapshot is provided as an example. If you want to use the STS
  PVC directly, the directory instance must be scaled to 0, as you can not
  mount a PVC on two pods at the same time.
* The Job runs an init container and exports the DS data to a mounted volume.
 The job then runs a final container where you can archive or otherwise save
 the ldif files.
* A sample container is provided just sleeps, and you can use `kubectl cp` to pull the data from the pvc.
* A second sample copies the file to cloud storage

## Sample Usage for export

Export:

* Deploy the directory service
* Take a snapshot of the data-ds-idrepo-0 disk:  `kubectl apply -f volume-snapshot.yaml`
* Run the export ldif job:  `kubectl apply -k .`
* Observe the logs from the pod or job (`stern export`)
* If you have gcs backup enabled, the ldif files will be copied to cloud storage
* When the job completes, the `ldif` PVC will contain the LDIF files. The default is for all non-system backends to be exported
