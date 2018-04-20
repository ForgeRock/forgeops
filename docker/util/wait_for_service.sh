#!/bin/sh
# Wait for service and port

while true
do
    echo "Waiting for $1:$2 (errors are expected if the service is not yet up)"
    nc $1 $2
    if [ $? -ne 0 ];
    then
        sleep 10
    else
        echo "Service $1:$2 is up"
        exit 0
    fi
done