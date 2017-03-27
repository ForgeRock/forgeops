# openidm-postgres PostgreSQL DB for OpenIDM

Extends the base PostgreSQL image with the schema required for OpenIDM.

# Notes

If you are using the Kubernetes Helm project files (fretes) you do *not* need this Docker image,
because the generic PostgreSQL image is used.

The SQL files are copied from OpenIDM 5.5 snapshot. You need to update them for
different OpenIDM releases.

The createuser.psql script is not really needed as the Docker image creates the openidm user by setting
POSTGRES_USER=openidm

# Sample commands to start

```
#  Runs PostgreSQL as OpenIDM db, uses data volume on hosts /var/tmp/pg
docker run --name pg -e POSTGRES_PASSWORD=openidm -e POSTGRES_USER=openidm  \
-e PGDATA=/var/lib/postgresql/data/pgdata -v /var/tmp/pg:/var/lib/postgresql/data/pgdata \
-d  openidm-postgres

# Log in to the image to test.
docker exec -i -t pg /bin/bash

# Try psql.
psql -U openidm
select * from openidm.managedobjects;
INSERT INTO openidm.internaluser (objectid, rev, pwd, roles) VALUES ('foo', '0', 'bar', '["openidm-reg"]');
select * from openidm.internaluser;

```
Alternative strategy using Docker data volumes

```
# Create the data container - dont delete this!
docker run --name pgdata postgres echo "data only"

# Run this image.
docker run --name idmpg -e POSTGRES_PASSWORD=openidm -e POSTGRES_USER=openidm  \
--volumes-from pgdata  \
--rm=true wstrange/openidm-postgres
```
