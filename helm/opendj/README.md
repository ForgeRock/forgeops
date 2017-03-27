# OpenDJ Helm chart

Deploy one or more OpenDJ instances using Persistent disk claims
and StatefulSets. 

If replicas is set > 1, each new DJ node will be configured 
to replicate to the first node.  This is a very simple topology
that will only support a small number (say 3) OpenDJ nodes. It
should be acceptable for testing and small installations. 

# Notes

By default, Minikube
uses a "host path" provisioner. This does not survive Minikube 
restarts! If you are on GKE, the default provisioner will create
persistent disk volumes (PDs). 

If you are benchmarking on GKE, use an SSD storage class,
and keep in mind that PD IOPS scale based on the size of the volume.
Anecdotally, you need to allocate at least 50 GB to get equivalent
performance to a MacBook Pro with SSD.


