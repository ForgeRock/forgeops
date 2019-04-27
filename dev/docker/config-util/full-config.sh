#!/usr/bin/bash
# Custom script to run both initial installation & runtime configuration for AM at once 
#
echo "Running AM initial config script"
python3 install_am.py
echo "Running AM runtime configuration"
python3 am_runtime_config.py

# This last echo sets the exit status to 0, which prevents k8s from trying to restart the job 
# on failure
echo "Done"