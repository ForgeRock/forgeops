#!/usr/bin/env make
REGISTRY_URL?=gcr.io/engineering-devops
VERSION?=latest
_VERSION=$(subst master,lastest,$(VERSION))
SHELL:=/bin/bash
DOCKER_BUILD:=docker build --build-arg VERSION=$(_VERSION)

check:
	echo $(_VERSION)
	echo $(TAG_NAME)
	echo $(BRANCH_NAME)

repo-build:
	docker build -t $(REGISTRY_URL)/repo:$(_VERSION) -f docker/cli-tools/repo/Dockerfile .

repo: repo-build push/repo/$(_VERSION)
	@echo "completed building repo tools"

cdm-build:
	$(DOCKER_BUILD) --cache-from $(REGISTRY_URL)/yamkt:$(_VERSION) -t $(REGISTRY_URL)/cdm-cli:$(_VERSION) -f docker/cli-tools/cdm/Dockerfile .

cdm: yamkt cdm-build push/cdm-cli/$(_VERSION)
	@echo "completed building cdk"

cdk-build:
	docker build --cache-from $(REGISTRY_URL)/yamkt:$(_VERSION)-skaffold -t $(REGISTRY_URL)/cdk-cli:$(_VERSION) -f docker/cli-tools/cdk/Dockerfile .

cdk: yamkt cdk-build push/cdk-cli/$(_VERSION)
	@echo "completed building cdk"

toolbox-build:
	docker build --cache-from $(REGISTRY_URL)/yamkt:$(_VERSION)-skaffold -t $(REGISTRY_URL)/cdk-toolbox:$(_VERSION) docker/cli-tools/toolbox

toolbox: yamkt toolbox-build push/cdk-toolbox/$(_VERSION)
	@echo "completed building toolbox"

debug-build:
	docker build -t $(REGISTRY_URL)/debug-cli:$(_VERSION) -f docker/cli-tools/debug/Dockerfile .

debug: yamkt debug-build push/debug-cli/$(_VERSION)
	@echo "completed building cdk"

cli-tools: cdm cdk toolbox debug
	@echo "completed building cli tools"

yamkt-build/%:
	docker build -t $(REGISTRY_URL)/yamkt:$(_VERSION)-$(@F) --target $(@F) -f docker/cli-tools/base/Dockerfile .

yamkt-build:
	docker build -t $(REGISTRY_URL)/yamkt:$(_VERSION) -f docker/cli-tools/base/Dockerfile .

yamkt: yamkt-build push/yamkt/$(_VERSION) yamkt-build/skaffold push/yamkt/$(_VERSION)-skaffold
	@echo "completed building Yet Another Multicloud Kubernetes Toolkit"

push/%:
	docker push $(REGISTRY_URL)/$(*D):$(@F)

all: cli-tools
