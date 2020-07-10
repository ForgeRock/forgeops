#!/usr/bin/env make
REGISTRY_URL=gcr.io/engineering-devops
VERSION=latest

repo-build:
	docker build -t $(REGISTRY_URL)/repo:$(VERSION) -f docker/cli-tools/repo/Dockerfile .
   
repo: repo-build push/repo/$(VERSION)
	@echo "completed building repo tools"

cdm-build:
	docker build --cache-from $(REGISTRY_URL)/yamkt:$(VERSION) -t $(REGISTRY_URL)/cdm-cli:$(VERSION) -f docker/cli-tools/cdm/Dockerfile .

cdm: yamkt cdm-build push/cdm-cli/$(VERSION)
	@echo "completed building cdk"

cdk-build:
	docker build --cache-from $(REGISTRY_URL)/yamkt:$(VERSION)-skaffold -t $(REGISTRY_URL)/cdk-cli:$(VERSION) -f docker/cli-tools/cdk/Dockerfile .

cdk: yamkt cdk-build push/cdk-cli/$(VERSION)
	@echo "completed building cdk"

toolbox-build:
	$(cd ./docker/cli-tools/toolbox && \
	docker build --cache-from $(REGISTRY_URL)/yamkt:$(VERSION)-skaffold -t $(REGISTRY_URL)/cdk-toolbox:$(VERSION) )

toolbox: yamkt toolbox-build push/cdk-toolbox/$(VERSION)
	@echo "completed building toolbox"

debug-build:
	docker build -t $(REGISTRY_URL)/debug-cli:$(VERSION) -f docker/cli-tools/debug/Dockerfile .

debug: yamkt debug-build push/debug-cli/$(VERSION)
	@echo "completed building cdk"

cli-tools: cdm cdk toolbox debug
	@echo "completed building cli tools"

yamkt-build/%:
	docker build -t $(REGISTRY_URL)/yamkt:$(VERSION)-$(@F) --target $(@F) -f docker/cli-tools/base/Dockerfile .

yamkt-build:
	docker build -t $(REGISTRY_URL)/yamkt:$(VERSION) -f docker/cli-tools/base/Dockerfile .

yamkt: yamkt-build push/yamkt/$(VERSION) yamkt-build/skaffold push/yamkt/$(VERSION)-skaffold
	@echo "completed building Yet Another Multicloud Kubernetes Toolkit"

push/%:
	docker push $(REGISTRY_URL)/$(*D):$(@F)

all: cli-tools
