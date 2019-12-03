#!/bin/sh

. ./util.sh

for i in run/*; do
    if [ -d $i ]; then
        echo Cleaning $i
        $i/bin/stop-ds
        rm -rf $i
    fi
done
