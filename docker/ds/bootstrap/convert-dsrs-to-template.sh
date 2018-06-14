#!/bin/sh

./stop-all.sh

cd run/$1

for i in changelogDb/*.dom/*.server; do
    rm -rf $i
done

rm -rf changelogDb/changenumberindex/*

# update config.ldif
./bin/ldifmodify -c -o config/config.ldif.new config/config.ldif ../../config-changes.ldif
mv config/config.ldif.new config/config.ldif

# update admin/admin-backend.ldif
# Currently not working due to lack of commons config support for the admin backend
# ./bin/ldifmodify -o db/admin/admin-backend.ldif.new db/admin/admin-backend.ldif ../../admin-changes.ldif
# cat db/admin/admin-backend.ldif.new
# mv db/admin/admin-backend.ldif.new db/admin/admin-backend.ldif

cd ../../

