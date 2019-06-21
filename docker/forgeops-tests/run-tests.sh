#!/usr/bin/env bash
echo "Running wait for products"
python3 wait-for-deployment.py
# IDM can be alive but not quite ready. Give it another 30 seconds
sleep 30
echo "Running AM tests"
python3 forgeops-tests.py tests/smoke/
