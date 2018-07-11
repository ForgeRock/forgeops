#!/bin/sh

# Set this to configuration replication at docker build time. Comment out to configure just a single server.
#CONFIG_REPLICATION="yes"

# Add hostnames to the docker containers /etc/hosts - needed only for building.
echo "127.0.0.1 dsrs1.example.com" >>/etc/hosts
echo "127.0.0.1 dsrs2.example.com" >>/etc/hosts
echo "127.0.0.1 dsrs3.example.com" >>/etc/hosts


echo "##### Cleaning servers..."
./clean-all.sh

echo "##### Configuring directory server DSRS 1..."
./setup-ds.sh dsrs 1 10

if [ -n "$CONFIG_REPLICATION" ]; then 

    echo "##### Configuring directory server DSRS 2..."
    ./setup-ds.sh dsrs 2

    echo "##### Configuring replication between DSRS 1 and DSRS 2..."
    ./run/dsrs1/bin/dsreplication configure \
        -I admin -w password -X \
        --bindDn1 "cn=directory manager" --bindPassword1 password \
        --bindDn2 "cn=directory manager" --bindPassword2 password \
        --baseDn o=userstore \
        --baseDn o=cts \
        --host1 dsrs1.example.com --port1 1444 --replicationPort1 1989 \
        --host2 dsrs2.example.com --port2 2444 --replicationPort2 2989 \
        --no-prompt

    echo "##### Initializing replication between DSRS 1 and DSRS 2..."
    ./run/dsrs1/bin/dsreplication initialize-all \
        -I admin -w password -X \
        --baseDn o=userstore \
        --baseDn o=cts \
        --hostname dsrs1.example.com --port 1444 \
        --no-prompt
fi


./stop-all.sh


convert_to_template()
{
    echo "Converting $1 config.ldif to use commons configuration"
    cd run/$1

    echo "Rebuilding indexes"
    ./bin/rebuild-index --offline --baseDN "${BASE_DN}" --rebuildDegraded
    ./bin/rebuild-index --offline --baseDN "o=cts" --rebuildDegraded
    ./bin/rebuild-index --offline --baseDN "o=idm" --rebuildDegraded

    for i in changelogDb/*.dom/*.server; do
        rm -rf $i
    done

    rm -rf changelogDb/changenumberindex/*

    # update config.ldif. continue on error is set so we keep applying the changes
    # Some of the configuration changes won't apply if replication is not being configured.
    ./bin/ldifmodify -c -o config/config.ldif.new config/config.ldif ../../config-changes.ldif
    mv config/config.ldif.new config/config.ldif


    cd ../../
}


convert_to_template dsrs1

