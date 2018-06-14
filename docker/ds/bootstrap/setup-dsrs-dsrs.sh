#!/bin/sh


echo "127.0.0.1 dsrs1.example.com" >>/etc/hosts
echo "127.0.0.1 dsrs2.example.com" >>/etc/hosts


echo "##### Cleaning servers..."
./clean-all.sh


echo "##### Configuring directory server DSRS 1..."
./setup-ds.sh dsrs 1 1000

# echo "##### Configuring directory server DSRS 2..."
# ./setup-ds.sh dsrs 2

# echo "##### Configuring replication between DSRS 1 and DSRS 2..."
# ./run/dsrs1/bin/dsreplication configure \
#     -I admin -w password -X \
#     --bindDn1 "cn=directory manager" --bindPassword1 password \
#     --bindDn2 "cn=directory manager" --bindPassword2 password \
#     --baseDn o=userstore \
#     --baseDn o=cts \
#     --host1 dsrs1.example.com --port1 1444 --replicationPort1 1989 \
#     --host2 dsrs2.example.com --port2 2444 --replicationPort2 2989 \
#     --no-prompt

# echo "##### Initializing replication between DSRS 1 and DSRS 2..."
# ./run/dsrs1/bin/dsreplication initialize-all \
#     -I admin -w password -X \
#     --baseDn o=userstore \
#     --baseDn o=cts \
#     --hostname dsrs1.example.com --port 1444 \
#     --no-prompt
