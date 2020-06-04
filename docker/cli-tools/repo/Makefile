#!/usr/bin/env make
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

RELEASE_REVS := $(shell forgeops release-revlist)

# bins
COMMITSTAR=/usr/local/bin/commitsar
TSLINT=tslint

# TODO incorporate more from poc-pr branch
#SHELL_SCRIPTS = $(wildcard **/*.sh)
#TS_SCRIPTS = $(shell find cluster/pulumi/{aws,azure,gcp} -name "*.ts")
#KUSTOMIZE_YAML = $(shell find kustomize -name "*.yaml")
# .PHONY: $(SHELL_SCRIPTS) $(KUSTOMIZE_YAML) $(TS_SCRIPTS)
#$(KUSTOMIZE_YAML):
#	-yamllint -f parsable $@
#
#ts:
#	-@$(TSLINT) -t verbose -p cluster/pulumi/tsconfig.json
#	@echo "linted ts"
#
#$(SHELL_SCRIPTS):
#	-shellcheck -f gcc $@
#
#yaml: $(KUSTOMIZE_YAML)
#	@echo "linted yaml"
#
#sh: $(SHELL_SCRIPTS)
#	@echo "linted shell scripts"
#
#
#lint: ts yaml sh
#	@echo "linted"
#
#commit:
#	$(COMMITSTAR)

branch-notes:
	@gitchangelog master..HEAD

changelog.md:
	gitchangelog  $(RELEASE_REVS) > changelog.md

release: changelog.md
	forgeops create-release-notes changelog.md

