#!/usr/bin/env make
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

RELEASE_REVS := $(shell forgeops release-revlist)
ACTIVE_TAG := $(shell forgeops current-tag)

branch-notes:
	@gitchangelog master..HEAD

changelog.md:
	gitchangelog  $(RELEASE_REVS) > changelog.md

release: changelog.md
	sed -i "0,/FORGEOPS_VERSION/s/FORGEOPS_VERSION=.*/FORGEOPS_VERSION=\"${ACTIVE_TAG}\"/" bin/quickstart.sh
	skaffold render --digest-source=remote -p docker-image-tag --default-repo=${DOCKER_REPO} --output=quickstart.yaml
	forgeops create-release-notes --asset=quickstart.yaml --asset=bin/quickstart.sh changelog.md

