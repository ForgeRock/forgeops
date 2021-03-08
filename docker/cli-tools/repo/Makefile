#!/usr/bin/env make
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

RELEASE_REVS := $(shell forgeops release-revlist)
ACTIVE_TAG := $(shell forgeops current-tag)

BASE_COMPONENTS = 7.0/ingress secrets git-server ../dev/scripts
DS_COMPONENTS = ds-idrepo ds-cts 
APP_COMPONENTS = am amster idm rcs-agent
UI_COMPONENTS = admin-ui end-user-ui login-ui
.PHONY: $(BASE_COMPONENTS) $(DS_COMPONENTS) $(APP_COMPONENTS) $(UI_COMPONENTS) quickstart

branch-notes:
	@gitchangelog master..HEAD

changelog.md:
	gitchangelog  $(RELEASE_REVS) > changelog.md
	# debug TODO remove later
	cat changelog.md


clean_artifacts:
	@rm -rf dist && mkdir -p dist

artifacts: clean_artifacts $(BASE_COMPONENTS) $(DS_COMPONENTS) $(APP_COMPONENTS) $(UI_COMPONENTS)

ingress: 7.0/ingress

$(BASE_COMPONENTS):
	$(eval $@_OUT := dist/base.yaml)
	$(eval $@_DIR := dist/kustomize/base)
	@mkdir -p $($@_DIR)
	@(cd $($@_DIR) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null || true
	@(cd $($@_DIR) && kustomize edit add resource ../../../kustomize/dev/kustomizeConfig) 2> /dev/null
	@(cd $($@_DIR) && kustomize edit add resource ../../../kustomize/base/$@) 
	@if [[ "$@" == "git-server" ]]; then \
		(cd $($@_DIR) && kustomize edit set image $@=${DOCKER_REPO}/$@); \
	fi
	kustomize build $($@_DIR) > $($@_OUT)

$(DS_COMPONENTS):
	$(eval $@_OUT := dist/ds.yaml)
	$(eval $@_DIR := dist/kustomize/ds)
	$(eval $@_OUT_INDV := dist/$@.yaml)
	$(eval $@_DIR_INDV := dist/kustomize/tmp)
	@mkdir -p $($@_DIR)
	@rm -rf $($@_DIR_INDV) && mkdir -p $($@_DIR_INDV)
	@(cd $($@_DIR) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null || true
	@(cd $($@_DIR) && kustomize edit add resource ../../../kustomize/base/$@)
	@(cd $($@_DIR) && kustomize edit set image .*$@.*=${DOCKER_REPO}/$@:${IMAGE_TAG})
	@if [ "$@" = "ds-cts" ]; then (cd $($@_DIR) && kustomize edit set replicas ds-cts=0) 2> /dev/null || true; fi
	@(cd $($@_DIR_INDV) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null
	@(cd $($@_DIR_INDV) && kustomize edit add resource ../../../kustomize/base/$@)
	@(cd $($@_DIR_INDV) && kustomize edit set image .*$@.*=${DOCKER_REPO}/$@:${IMAGE_TAG})
	kustomize build $($@_DIR) > $($@_OUT)
	kustomize build $($@_DIR_INDV) > $($@_OUT_INDV)

$(APP_COMPONENTS):
	$(eval $@_OUT := dist/apps.yaml)
	$(eval $@_DIR := dist/kustomize/apps)
	$(eval $@_OUT_INDV := dist/$@.yaml)
	$(eval $@_DIR_INDV := dist/kustomize/tmp)
	@mkdir -p $($@_DIR)
	@rm -rf $($@_DIR_INDV) && mkdir -p $($@_DIR_INDV)
	@(cd $($@_DIR) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null || true
	@(cd $($@_DIR_INDV) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null
	@if [[ "$@" == "am" || "$@" == "idm" ]]; then \
		(cd $($@_DIR) && kustomize edit add resource ../../../kustomize/dev/$@); \
		(cd $($@_DIR) && kustomize edit set image $@=${DOCKER_REPO}/$@:${IMAGE_TAG}); \
		(cd $($@_DIR_INDV) && kustomize edit add resource ../../../kustomize/dev/$@); \
		(cd $($@_DIR_INDV) && kustomize edit set image $@=${DOCKER_REPO}/$@:${IMAGE_TAG}); \
	else \
		(cd $($@_DIR) && kustomize edit add resource ../../../kustomize/base/$@); \
		(cd $($@_DIR) && kustomize edit set image .*$@.*=${DOCKER_REPO}/$@:${IMAGE_TAG}); \
		(cd $($@_DIR_INDV) && kustomize edit add resource ../../../kustomize/base/$@); \
		(cd $($@_DIR_INDV) && kustomize edit set image .*$@.*=${DOCKER_REPO}/$@:${IMAGE_TAG}); \
	fi
	kustomize build $($@_DIR) > $($@_OUT)
	kustomize build $($@_DIR_INDV) > $($@_OUT_INDV)

$(UI_COMPONENTS):
	$(eval $@_OUT := dist/ui.yaml)
	$(eval $@_DIR := dist/kustomize/ui)
	$(eval $@_OUT_INDV := dist/$@.yaml)
	$(eval $@_DIR_INDV := dist/kustomize/tmp)
	@mkdir -p $($@_DIR)
	@rm -rf $($@_DIR_INDV) && mkdir -p $($@_DIR_INDV)
	@(cd $($@_DIR) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null || true
	@(cd $($@_DIR) && kustomize edit add resource ../../../kustomize/base/$@)
	@(cd $($@_DIR_INDV) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null || true
	@(cd $($@_DIR_INDV) && kustomize edit add resource ../../../kustomize/base/$@)
	@if [[ "$@" == "end-user-ui" ]]; then \
		(cd $($@_DIR) && kustomize edit set image .*enduser-ui.*=${DOCKER_REPO}/enduser-ui:${IMAGE_TAG}); \
		(cd $($@_DIR_INDV) && kustomize edit set image .*enduser-ui.*=${DOCKER_REPO}/enduser-ui:${IMAGE_TAG}); \
	else \
		(cd $($@_DIR) && kustomize edit set image .*$@.*=${DOCKER_REPO}/$@:${IMAGE_TAG}); \
		(cd $($@_DIR_INDV) && kustomize edit set image .*$@.*=${DOCKER_REPO}/$@:${IMAGE_TAG}); \
	fi
	kustomize build $($@_DIR) > $($@_OUT)
	kustomize build $($@_DIR_INDV) > $($@_OUT_INDV)

quickstart: artifacts
	$(eval $@_OUT := dist/quickstart.yaml)
	$(eval $@_DIR := dist/kustomize/quickstart)
	@mkdir -p $($@_DIR)
	@(cd $($@_DIR) && kustomize init --labels app.kubernetes.io/part-of:forgerock) 2> /dev/null || true
	@(cd $($@_DIR) && kustomize edit add resource ../../../dist/kustomize/base)
	@(cd $($@_DIR) && kustomize edit add resource ../../../dist/kustomize/ds) 
	@(cd $($@_DIR) && kustomize edit add resource ../../../dist/kustomize/apps) 
	@(cd $($@_DIR) && kustomize edit add resource ../../../dist/kustomize/ui) 
	kustomize build $($@_DIR) > $($@_OUT)

release: changelog.md quickstart
	sed -i "0,/FORGEOPS_VERSION/s/FORGEOPS_VERSION=.*/FORGEOPS_VERSION=\"${ACTIVE_TAG}\"/" bin/quickstart.sh
	forgeops create-release-notes \
	--asset=dist/quickstart.yaml --asset=bin/quickstart.sh \
    --asset=dist/admin-ui.yaml \
    --asset=dist/am.yaml \
    --asset=dist/amster.yaml \
    --asset=dist/apps.yaml \
    --asset=dist/base.yaml \
    --asset=dist/ds-cts.yaml \
    --asset=dist/ds-idrepo.yaml \
    --asset=dist/ds.yaml \
    --asset=dist/end-user-ui.yaml \
    --asset=dist/idm.yaml \
    --asset=dist/login-ui.yaml \
    --asset=dist/rcs-agent.yaml \
    --asset=dist/ui.yaml \
    changelog.md

