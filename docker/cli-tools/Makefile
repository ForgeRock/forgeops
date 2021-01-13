#!/usr/bin/env make
.PHONY: base toolbox repo git-server debug

REGISTRY_URL?=gcr.io/engineering-devops
# build master as latest
VERSION?=latest
_VERSION=$(subst master,latest,$(VERSION))
SHELL:=/bin/bash
DOCKER_BUILD:=docker build --build-arg VERSION=$(_VERSION) --build-arg FORGEOPS_REGISTRY=$(REGISTRY_URL)

all: cli-tools

no:
	echo $(VERSION)
git-server:
	$(DOCKER_BUILD) -t $(REGISTRY_URL)/cli-tools/git-server:$(_VERSION) git-server

repo:
	$(DOCKER_BUILD) -t $(REGISTRY_URL)/repo:$(_VERSION) -f repo/Dockerfile repo

toolbox: base
	$(DOCKER_BUILD) --cache-from $(REGISTRY_URL)/cli-tools/base:$(_VERSION) -t $(REGISTRY_URL)/cli-tools/toolbox:$(_VERSION) toolbox

base:
	$(DOCKER_BUILD) -t $(REGISTRY_URL)/cli-tools/base:$(_VERSION) -f base/Dockerfile base

push-base: base
	docker push $(REGISTRY_URL)/cli-tools/base:$(_VERSION)
	@echo "push of base completed"

push-toolbox: toolbox
	docker push $(REGISTRY_URL)/cli-tools/toolbox:$(_VERSION)
	@echo "push of toolbox completed"

push-repo: repo
	docker push $(REGISTRY_URL)/repo:$(_VERSION)
	@echo "push of repo completed"

push-git-server: git-server
	docker push $(REGISTRY_URL)/cli-tools/git-server:$(_VERSION)
	@echo "push of git-server completed"

cli-tools: base repo toolbox git-server
	@echo "completed building cli tools"
