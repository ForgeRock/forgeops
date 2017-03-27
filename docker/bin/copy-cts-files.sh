#!/usr/bin/env bash
# Copies the CTS files from an OpenAM distribution to the opendj directory.

rm -fr /tmp/openam
unzip openam/openam.war -d /tmp/openam

SRC=/tmp/openam/WEB-INF/template/ldif/sfha
DEST=opendj/bootstrap/cts/sfha

rm -f $DEST/*ldif

cp $SRC/cts-add-schema.ldif $DEST
cp $SRC/cts-indices.ldif $DEST
cp $SRC/cts-container.ldif $DEST
cp $SRC/cts-add-multivalue.ldif $DEST
cp $SRC/cts-add-multivalue-indices.ldif $DEST
git