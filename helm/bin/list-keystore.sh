#!/usr/bin/env bash
# Utility to list the keystore contents. Use this to verify you have the right storepass and keystore entries.
# Run this from the directory that contains secrets/.

if [ $# == 1 ]; then
  cd $1
else
    cd secrets
fi

pass=`cat .storepass`

echo "storepass is $pass"

keytool -list -keystore keystore.jceks -storetype jceks -storepass $pass

echo "JKS"

keytool -list -keystore keystore.jks -storetype jks -storepass $pass

