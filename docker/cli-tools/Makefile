#!/usr/bin/env make



cdk:
	docker build -t cdk-cli:latest -f ~/projects/forgeops/docker/cli-tools/cdk/Dockerfile ~/projects/forgeops/docker/cli-tools/cdk

skaffold:
	docker build -t yamkt:skaffold --target skaffold -f ~/projects/forgeops/docker/cli-tools/base/Dockerfile .


