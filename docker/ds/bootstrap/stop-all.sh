#!/bin/sh

. ./util.sh

for i in run/*; do
    if [ -d $i ]; then
        echo Stopping $i
        $i/bin/stop-ds
    fi
done
