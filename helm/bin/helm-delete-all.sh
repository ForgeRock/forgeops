#!/usr/bin/env bash


releases=`helm list -q`

for r in ${releases}
do
    echo "Deleting release $r"
    helm delete --purge $r
done

