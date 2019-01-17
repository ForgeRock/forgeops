#!/usr/bin/env bash

# Helper script for google cloud build to keep it simple to run tests
# while having stdout in file to send to slack

export PYTHONUNBUFFERED=x
python3 forgeops-tests.py --suite tests/smoke/ &> res.txt
tail -n 4 res.txt > results.txt
