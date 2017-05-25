#!/bin/sh
#
echo "Command is $1"
if [ "$1" = 'init' ]; then
    exec /git-init.sh
fi

# else .... 
exec /sync.sh 



