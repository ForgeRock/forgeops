#!/usr/bin/env bash
# Script to update the postgres SQL schema for IDM.
# Copies schema files from the IDM zip to the Helm postgres chart.
# Run this when the schema changes (TODO: Automate this). The schema usually only changes between major releases.
# Before running this make sure openidm/openidm.zip exists.


set -x
rm -fr /tmp/openidm
rm -fr /tmp/helm

unzip openidm.zip -d /tmp/

TMP_PG=/tmp/openidm/db/postgresql/scripts


target=/tmp/helm

mkdir -p $target


# This copies and renames the sql files in alphabetical order so they can be loaded in the proper sequence.\
cp $TMP_PG/openidm.pgsql $target/01_openidm.sql
cp $TMP_PG/default_schema_optimization.pgsql $target/02_default_schema_optimization.sql
cp $TMP_PG/audit.pgsql $target/03_audit.sql

cp $TMP_PG/activiti.postgres.create.*.sql  $target

cp $target/*  ../../helm/postgres-openidm/sql

# We no longer maintain a separate docker image.
#cp $target/*  openidm-postgres/sql

rm -fr $target

