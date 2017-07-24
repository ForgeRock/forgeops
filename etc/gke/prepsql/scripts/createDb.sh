#!/usr/bin/env bash

echo "Create the PG database"
cd /scripts

# Give the proxy time to start...
sleep 5

echo "PG password is $PGPASSWORD"

env


# env var PGPASSWORD is set for us..
psql --host=localhost --username=postgres --file=createuser.pgsql

# Subsequent commands can run as idm user
export PGPASSWORD="$IDM_PASSWORD"

psql --host=localhost --username="${IDM_USER}" --file=openidm.pgsql

psql --host=localhost --username="${IDM_USER}" --file=audit.pgsql

for file in activiti*
do
    psql --host=localhost --username="${IDM_USER}" --file=$file
done

psql --host=localhost --username="${IDM_USER}" --file=default_schema_optimization.pgsql

echo "Database creation finished. You can now remove this job"