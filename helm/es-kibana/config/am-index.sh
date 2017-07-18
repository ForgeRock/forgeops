#!/usr/bin/env bash

curl \
 --request PUT \
 --header "Content-Type: application/json" \
 --data @am_schema.json \
 http://localhost:9200/openam_audit_index
