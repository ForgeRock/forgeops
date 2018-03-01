#!/usr/bin/env bash
# Set up an admin server. This is an instance used for admin functions, including backup and restore
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

#set -x

source /opt/opendj/env.sh


# in env.sh
setup_ds

# Load any optional LDIF files
load_ldif



./bootstrap/schedule_backup.sh

echo "To enable replication, exec into this image and run ./bootstrap/replicate-all.sh"

