#!/usr/bin/env bash
# Script to update the postgres SQL schema for IDM.
# Copies schema files from the IDM zip to the Helm postgres chart and the Docker postgres image
# Run this when the schema changes (TODO: Automate this). The schema usually only changes between major releases.
# Before running this make sure openidm/openidm.zip exists.


set -x
rm -fr /tmp/openidm
unzip openidm/openidm.zip -d /tmp/

TMP_PG=/tmp/openidm/db/postgresql/scripts


target=/tmp/helm

mkdir -p $target


cp $TMP_PG/openidm.pgsql $target/01_init.sql
cp $TMP_PG/default_schema_optimization.pgsql $target/02_optimize.sql
cp $TMP_PG/audit.pgsql $target/03_audit.sql

cp $TMP_PG/activiti.postgres.create.*.sql  $target

cp $target/*  ../helm/postgres-openidm/sql
cp $target/*  openidm-postgres/sql

rm -fr $target
rm -fr /tmp/openidm

