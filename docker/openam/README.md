# OpenAM Dockerfile 


This is designed to be a flexible OpenAM image that can be used in 
different deployment styles.

# Volumes 

You can mount optional volumes to control the behavior of the image:

* /root/openam: Mount a volume to persist the bootstrap configuration.
If the container is restarted it will retain it bootstrap config.
* /var/secrets/openam/{key*, .keypass, .storepass}  - optional key
material copied into the /root/openam/openam directory. These files 
can be copied using something like an Kubernetes init container. If you
wanted all OpenAM instances to have the same keystores, you would mount
mount a Kubernetes secret volume with these files.

# Building and Boostrapping Process

* The Dockerfile assumes that the openam.war file is pre-downloaded in this directory.
* If no bootstrap file (/root/openam/boot.json) exists, OpenAM will come up in installation mode. 
If you want to persist the installation, ensure that /root/openam is mounted as a persistent volume. 
* If you have an existing configuration store, you can configre OpenAM to use it by creating 
an appropriate boot.json file with boot passwords in keystore.jceks.





