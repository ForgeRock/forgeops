#!/usr/bin/env bash

# Helper script for google cloud build to keep it simple to run tests
# while having stdout in file to send to slack

python3 forgeops-tests.py --suite tests/smoke/am &> res.txt
tail -n 7 res.txt > results.txt
