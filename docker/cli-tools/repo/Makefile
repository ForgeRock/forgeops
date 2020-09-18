#!/usr/bin/env make
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

RELEASE_REVS := $(shell forgeops release-revlist)

branch-notes:
	@gitchangelog master..HEAD

changelog.md:
	gitchangelog  $(RELEASE_REVS) > changelog.md

release: changelog.md
	forgeops create-release-notes changelog.md

