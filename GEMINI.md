# Repository Context

## Overview

The forgeops repository contains all of the core tools and resources required to help users deploy the Ping Identity  
Platform stack into a Kubernetes environment. The repository contains a mixture of scripts, Kubernetes manifests and  
supporting resources using a variety of programming languages.

Sample GEMINI.md: https://github.com/ping-rocks/eng-gemini-review/blob/main/examples/basic/GEMINI.md

## Technology Stack

- **Languages**: python3, bash, groovy
- **Kubernetes tools**: Kustomize, Helm
- **Container tools**: Docker


## Project Structure

```
├── bin/               # Bash and Python scripts for supporting platform deployments and troubleshooting
│   ├── commands/      # Individual modules for each forgeops cli tool command
├── charts/            # Helm charts
├── docker/            # Product Docker directories
├── etc/               # Additional supporting resources
├── helm/              # User's custom Helm environments(custom values.yaml)
├── how-tos/           # How-to guides
├── jenkins-scripts/   # Jenkins configuration scripts for PR and Post-commit pipelines
├── legacy-docs/       # Packaged legacy documentation
├── lib/               # External dependencies, shared code, plugins, or third-party packages required for scripts in the bin dir
└── upgrade/           # Migration scripts for migrating from a previous forgeops version
```

## Architecture Patterns

### Layered Architecture

### Dependency Injection

## API Conventions

## Exception Handling

### Custom Exceptions

### Global Exception Handler

## Testing Strategy

### Unit Tests

### Integration Tests

## Configuration

### Profiles

### Environment Variables

## Build and Deploy
* Docker build for building custom Docker images for the Identity-Platform
* Kustomize and Helm for Identity-Platform deployments
* Jenkins scripts for configuring Jenkins pipelines
* bin/forgeops command for managing custom environments for Helm and Kustomize and deploying Kustomize overlays