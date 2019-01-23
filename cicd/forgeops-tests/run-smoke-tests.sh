#!/usr/bin/env bash

# Helper script for google cloud build to keep it simple to run tests
# while having stdout in file to send to slack

export PYTHONUNBUFFERED=x
python3 forgeops-tests.py tests/smoke $@
