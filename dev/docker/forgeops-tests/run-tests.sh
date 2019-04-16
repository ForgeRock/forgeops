#!/usr/bin/env bash
echo "Running wait for products"
python3 wait-for-deployment.py
echo "Running AM tests"
python3 forgeops-tests.py tests/smoke/am 
