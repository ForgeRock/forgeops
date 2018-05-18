# Forgeops Benchmark Suite

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Forgeops Benchmark Suite](#forgeops-benchmark-suite)
	- [Introduction](#introduction)
	- [Project folder structure](#project-folder-structure)
		- [1. Gatling helm chart](#1-gatling-helm-chart)
		- [2. Deployment scripts](#2-deployment-scripts)
	- [Setup](#setup)
		- [Prerequisites](#prerequisites)
		- [1. Configure your namespace](#1-configure-your-namespace)
			- [Gatling image](#gatling-image)
		- [2. Deployment configuration](#2-deployment-configuration)
			- [AM Configuration](#am-configuration)
	- [Run benchmark](#run-benchmark)
		- [1. Run deployment script](#1-run-deployment-script)
		- [2. Run benchmark](#2-run-benchmark)
		- [3. Access benchmark results](#3-access-benchmark-results)

<!-- /TOC -->

## Introduction

This is first version of benchmark for Forgerock products deployed with
Forgeops into GKE. Initially we support only OpenAM+OpenDJ deployment, but
this may change and expand to cover all 4 major products in future.

## Project folder structure
This project consist of two main parts - deployment scripts and Gatling
helm chart with tests.

### 1. Gatling helm chart
Folder `forgeops-benchmark-chart/` is a benchmark chart with all the tests
included. Chart follows same structure as other ForgeOps charts.

### 2. Deployment scripts
Folders `open[am/ig/dj/id]/` contains deployment scripts for products along
with yaml files sorted in folders by cluster size.   

## Setup
There are few steps you need to take before running this benchmark.

### Prerequisites
This guide assumes you have access to Kubernetes cluster and you are able to
do deployments. Other requirements are:
 - Helm is installed (Kubernetes package manager)
 - Ingress is deployed and you can access cluster endpoint from your laptop
 machine where you are running benchmark from.

### 1. Configure your namespace
You need to have secrets in your namespace to access following places:
  - github.com (Where we store product configuration for benchmark)
  - bintary.com (Gatling benchmark image - in private part of repo)

#### Gatling image
Gatling image we are using for running benchmarks is built
from official gatling image and benchmark scala files from
pyforge testing framework. Links to build job and git repository follows:

 - http://jenkins-gnb.internal.forgerock.com:8080/view/K8S%20/job/docker-builds/job/pyforge-gatling/
 - https://stash.forgerock.org/projects/DOCKER/repos/docker-qa/browse/pyforge-gatling/Dockerfile

### 2. Deployment configuration
Deployment script for each product is located in respective folder.

Open `[product]/deploy-[product].sh` file and modify following variables:
 - DOMAIN - Domain that will be used for deployment of product
 - NAMESPACE - Namespace where your deployment will be deployed to
 - CLUSTER - Cluster size as defined per following document:
 https://docs.google.com/document/d/16roOI6FZ0vsg72fZ0lTR8XI2X4yYp8B-GwwM9iKW9X8/edit

Cluster size needs to be name of folder located in `[product]/yamls/[cluster size]`

#### AM Configuration

In `openam/yamls/[cluster-size]/amster.yaml`, you need to modify sedFilter
to match values in deployment script. Example follows.

```
global:
  git:
    sedFilter: "-e s/lee.example.com/[NAMESPACE].[DOMAIN]/"
```

For benchmarking purpose, you can also modify resource related properties
as they will change outcome of benchmark significantly.

## Run benchmark

### 1. Run deployment script
Execute `[product]/deploy-[product].sh` to run product deployment. Once deployment
is finished, you can proceed to run benchmark.


### 2. Run benchmark
Look into `forgeops-benchmark/values.yaml`. There are couple of test variables
you can set as well as select benchmark that will run.

Once deployment is setup(Or you have existing deployment, that suits our benchmarks)
you can proceed to installing benchmark chart.

`helm install --name benchmark forgeops-benchmark-chart`

Now you can list pods in your namespace. Output should be as this:

```
kubectl get pods
NAME                                     READY     STATUS     RESTARTS   AGE
amster-7f58b78755-5bxn4                  2/2       Running    0          7m
configstore-0                            1/1       Running    0          7m
ctsstore-0                               1/1       Running    0          7m
forgeops-benchmark-8566b4cf98-4j78b      0/1       Init:0/1   0          3m
openam-pyforge-openam-6c7575b4f5-5cxxh   1/1       Running    0          7m
userstore-0                              1/1       Running    0          7m
```

Benchmark pod will be in Init:0/1 state until tests are finished.

To see gatling progress output, run `./logs.sh`.

### 3. Access benchmark results

Once tests are finished, you need to make sure you have ingress address with
fqdn in your /etc/hosts file.


```
kubectl get ingress
NAME      HOSTS                          ADDRESS         PORTS     AGE
gatling   gatling.pyforge.forgeops.com   35.227.42.137   80        3m
openam    openam.pyforge.forgeops.com    35.227.42.137   80        7m
```
Then you can simply access results by going to :
`http://gatling.[NAMESPACE].[DOMAIN]/` e.g. `http://gatling.pyforge.forgeops.com`

Accessing this URL will show following:

```
Index of /
../
restlogin-1523282212519/                           09-Apr-2018 14:59                   -
restlogin-1523282212519.tar.gz                     09-Apr-2018 15:00            33988974
```

Folder contains HTML report which can be directly opened and inspected.
Archive .tar.gz can be downloaded and kept for future usage. Once helm chart with
benchmark is deleted, you can no longer access these files, so download it if you need to archive results.
