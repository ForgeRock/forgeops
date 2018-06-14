Steps to create a templated 2-way replication topology:

* set the location of ARCHIVE in util.sh to point to a recent build of DJ 6.0.0. E.g:
```
ARCHIVE=~/workspace/opendj/opendj-server/target/opendj-6.0.0-SNAPSHOT.zip
```
* ensure that your /etc/hosts has records for dsrs1.example.com and dsrs2.example.com:
```
127.0.0.1 dsrs1.example.com
127.0.0.1 dsrs2.example.com
```
* setup a 2-way replication topology:
```
./setup-dsrs-dsrs.sh 
```
* stop the servers:
``` 
./stop-all.sh 
```
* remove the second server because we won't need it. The same template will be used for both replicas:
``` 
rm -rf run/dsrs2/
``` 
* convert the first server to a template. Key config properties like the port, hostnames, and server ID will be 
parameterized using commons config:
```
./convert-dsrs-to-template.sh dsrs1
```
* the instance in run/dsrs1 is now fully prepared. It could be used as the basis of a Docker image. Let's pretend 
that it is and create two separate DJ instances from the same base image:
```
cp -r run/dsrs1 run/dsrs2
SERVER_ID=1 SERVER_FQDN=dsrs1.example.com DS_CHANGELOG_HOSTPORTS=dsrs1.example.com:1989,dsrs2.example.com:2989 ./run/dsrs1/bin/start-ds 
SERVER_ID=2 SERVER_FQDN=dsrs2.example.com DS_CHANGELOG_HOSTPORTS=dsrs1.example.com:1989,dsrs2.example.com:2989 ./run/dsrs2/bin/start-ds 
```
* it is possible to switch off different base DNs before starting the DJ instances. In this example we can switch off
 the sample "userstore" backend and "cts" backend using DS_ENABLE_USERSTORE and DS_ENABLE_CTS environment variables:
```
./stop-all.sh 
SERVER_ID=1 SERVER_FQDN=dsrs1.example.com DS_ENABLE_USERSTORE=false DS_ENABLE_CTS=true DS_CHANGELOG_HOSTPORTS=dsrs1.example.com:1989,dsrs2.example.com:2989 ./run/dsrs1/bin/start-ds 
SERVER_ID=2 SERVER_FQDN=dsrs2.example.com DS_ENABLE_USERSTORE=false DS_ENABLE_CTS=true DS_CHANGELOG_HOSTPORTS=dsrs1.example.com:1989,dsrs2.example.com:2989 ./run/dsrs2/bin/start-ds 
```
