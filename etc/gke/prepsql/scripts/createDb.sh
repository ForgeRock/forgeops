#!/usr/bin/env bash
# This script creates the database for the user passed in via the Env vars.

echo "Create the postgres database for idm user $IDM_USER"
cd /scripts

# Give the proxy time to start...
sleep 5

# Env var PGPASSWORD is set for us to authenticate to Postgres as the super user.
# This creates the IDM user and database
psql --host=localhost --username=postgres --file=createuser.pgsql -v idmuser="${IDM_USER}" -v password=\'"$IDM_PASSWORD"\'

# save the postgres root password for later.
pgpass=$PGPASSWORD

# Subsequent psql commands run as idm user created in the previous step.
export PGPASSWORD="$IDM_PASSWORD"

psql --host=localhost --username="${IDM_USER}" --file=openidm.pgsql

psql --host=localhost --username="${IDM_USER}" --file=audit.pgsql

for file in activiti*
do
    psql --host=localhost --username="${IDM_USER}" --file=$file
done

# This has to be run as super user against the database.
export PGPASSWORD=$pgpass

psql --host=localhost --username=postgres "${IDM_USER}" --file=default_schema_optimization.pgsql

echo "Database creation finished. You can now remove this job"