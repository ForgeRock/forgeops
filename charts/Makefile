.PHONY: install install-local clean

ifndef CHART_REPO
CHART_REPO=oci://us-docker.pkg.dev/forgeops-public/charts
endif
ifndef CHART_NAME
CHART_NAME=identity-platform
endif
ifndef CHART_VERSION
CHART_VERSION=$(shell grep ^version: $(CHART_NAME)/Chart.yaml | awk '{print $$2}')
endif
CHART_PACKAGE=$(CHART_NAME)-$(CHART_VERSION).tgz

ifndef HELM_RELEASE
HELM_RELEASE=$(CHART_NAME)
endif
ifndef HELM_NAMESPACE
HELM_NAMESPACE=$(HELM_RELEASE)
endif
ifndef HELM_CHART_DIRECTORY
HELM_CHART_DIRECTORY=$(CHART_NAME)
endif

all: package

# Package chart for push to helm repository
$(CHART_PACKAGE): $(shell find $(CHART_NAME) -type f)
	helm package $(CHART_NAME) --app-version $(CHART_VERSION) --version $(CHART_VERSION)

package: $(CHART_PACKAGE)

# Push chart to helm repository
push: $(CHART_PACKAGE)
	helm push $< $(CHART_REPO)

# Install chart from helm repository using default values
install:
	kubectl create namespace $(HELM_NAMESPACE) || true
	helm upgrade $(HELM_RELEASE) $(CHART_NAME) --repo $(CHART_REPO) --version $(CHART_VERSION) --namespace $(HELM_NAMESPACE) --install

# Install chart from local directory using default values
install-local:
	kubectl create namespace $(HELM_NAMESPACE) || true
	helm upgrade $(HELM_RELEASE) $(HELM_CHART_DIRECTORY) --namespace $(HELM_NAMESPACE) --install

clean:
	rm -f $(CHART_PACKAGE)

