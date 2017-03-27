#!/bin/bash
# Script to clean up all gcr.io images
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#

PROJECT=engineering-devops

gsutil -m rm -r gs://artifacts.${PROJECT}.appspot.com 

