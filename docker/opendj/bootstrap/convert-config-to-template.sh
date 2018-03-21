#!/usr/bin/env bash
# Converts the configuration backend to templated values.


# todo: Ask Matt why we need this.
for i in changelogDb/*.dom/*.server; do
    rm -rf $i
done

rm -rf changelogDb/changenumberindex/*


bin/ldifmodify --continueOnError --outputLdif config.ldif.new config/config.ldif bootstrap/ldif/config-change-serverid.ldif


echo "Templated config.ldif "

mv config/config.ldif config/config.ldif.old
cp config.ldif.new config/config.ldif
