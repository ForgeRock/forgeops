#!/bin/sh

. ./util.sh

for i in run/*; do
    if [ -d $i ]; then
        echo Starting $i
        $i/bin/start-ds
    fi
done
