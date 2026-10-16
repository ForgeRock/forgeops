#!/bin/sh

BITS=${BITS:-4096}
KEY_TYPE=${KEY_TYPE:-rsa}
SSH_KG_CMD=$(command -v ssh-keygen)
if [ -x "$SSH_KG_CMD" ] ; then
	$SSH_KG_CMD -t $KEY_TYPE -b $BITS -N "" -m pem -f /ssh_key/id_${KEY_TYPE}
else
	echo "ERROR!! Can't find ssh-keygen"
	exit 1
fi
