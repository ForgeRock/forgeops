#!/usr/bin/env make

# wrapper to the docker/cli-tools/repo/Makefile but runs the command in a container for portability
%:
	@docker run --rm \
		-v $(shell pwd):/opt/workspace \
			us-docker.pkg.dev/engineering-devops/images/repo:latest \
				make -f docker/cli-tools/repo/Makefile $@
