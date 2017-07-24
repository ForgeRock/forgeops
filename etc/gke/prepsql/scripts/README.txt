Copyright
=============
Copyright 2013-2017 ForgeRock AS. All Rights Reserved

Use of this code requires a commercial software license with ForgeRock AS.
or with one of its affiliates. All use shall be exclusively subject
to such license between the licensee and ForgeRock AS.

Postgres
========

To initialize your PostgreSQL 9.3 (or greater) OpenIDM repository, follow these steps:

First, edit "createuser.pgsql" and set a proper password for the openidm user.

After saving the file, execute "createuser.pgsql" script like so:

$ psql -U postgres < db/postgresql/scripts/createuser.pgsql

Next execute the "openidm.pgsql" script using the openidm user that was just created:

$ psql -U openidm < db/postgresql/scripts/openidm.pgsql

Your database is now initialized. Now copy the repo and datasource configs.  These 
commands assume copying to the default project.  Adjust them to refer to wherever
your project conf directory is.

$ cp db/postgresql/conf/repo.jdbc.json conf/repo.jdbc.json
$ cp db/postgresql/conf/datasource.jdbc-default.json conf/datasource.jdbc-default.json

Edit your project's conf/datasource.jdbc.json file to set the value for "password" to be
whatever password you set for the openidm user in the first step.

You should now have a functional PostreSQL-based OpenIDM. If you are using the default project 
configuration, you should also run the "default_schema_optimization.sql" file to have indexes 
for the expected fields. Read the comments in that file for more details.

$ psql -U postgres openidm < db/postgres/scripts/default_schema_optimization.pgsql
