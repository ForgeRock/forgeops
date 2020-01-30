#!/usr/bin/env make
REGISTRY_URL=gcr.io/engineering-devops
VERSION=latest

cdm/%:
	docker build --progress=plain -t $(REGISTRY_URL)/cdm-cli:$(VERSION)-$(@F) --target $(@F) -f docker/cli-tools/cdm/Dockerfile .

cdm: cdm/aws cdm/azure cdm/gcp
	docker build -t $(REGISTRY_URL)/cdm-cli:latest -f docker/cli-tools/cdm/Dockerfile .

cdk:
	docker build -t $(REGISTRY_URL)/cdk-cli:latest -f docker/cli-tools/cdk/Dockerfile .

yamkt/%:
	docker build -t $(REGISTRY_URL)/yamkt:$(VERSION)-$(@F) --target $(@F) -f docker/cli-tools/base/Dockerfile .
	docker push $(REGISTRY_URL)/yamkt:$(VERSION)-$(@F)

yamkt: yamkt/skaffold yamkt/aws yamkt/azure yamkt/gcp
	docker build -t $(REGISTRY_URL)/yamkt:$(VERSION) -f docker/cli-tools/base/Dockerfile .
	docker push $(REGISTRY_URL)/yamkt:$(VERSION)

push/%:
	# docker push $(REGISTRY_URL)/yamkt:$(VERSION)-$(@F)
	docker push $(REGISTRY_URL)/cdm-cli:$(VERSION)-$(@F)

push: push/aws push/azure push/gcp
	docker push $(REGISTRY_URL)/yamkt:$(VERSION)
	docker push $(REGISTRY_URL)/cdm-cli:$(VERSION)
	docker push $(REGISTRY_URL)/cdk-cli:$(VERSION)

all: yamkt cdm cdk push
