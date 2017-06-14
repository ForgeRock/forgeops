#!/bin/bash
# Script to clean up all gcr.io images
# Use with caution!
#

PROJECT=engineering-devops

gsutil -m rm -r gs://artifacts.${PROJECT}.appspot.com 
