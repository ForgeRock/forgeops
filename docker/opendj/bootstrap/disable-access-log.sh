#!/usr/bin/env bash
# Disable access logging. This is done for the CTS - where access logs are typically not required.
# Access logging can impact performance by up to 20%
/opt/opendj/bin/dsconfig set-log-publisher-prop \
    --offline \
    --publisher-name Json\ File-Based\ Access\ Logger \
    --set enabled:false \
    --no-prompt 