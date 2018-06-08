#!/usr/bin/env bash
# Helper script to save last commit username to file.
# Used in cloudbuilder to send notifications.
git log -1 --pretty=format:'%an' > uname-lastcommit.txt
