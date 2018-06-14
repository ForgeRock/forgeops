#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

/opt/opendj/bin/dsreplication status \
          --hostname localhost \
          --port 4444 \
          --adminUid admin \
          --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
          --no-prompt \
          --trustAll
