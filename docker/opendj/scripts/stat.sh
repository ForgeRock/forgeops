#!/usr/bin/env bash

/opt/opendj/bin/status --bindPasswordFile "${DIR_MANAGER_PW_FILE}" --trustAll -D "cn=Directory Manager"
