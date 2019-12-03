#!/usr/bin/env bash
# Sample script to test the prometheus metrics endpoint.

PW=`cat /var/run/secrets/opendj/monitor.pw`

curl -u monitor:$PW http://localhost:8080/metrics/prometheus
