# Flux

## Introduction

Flux is a set of continuous and progressive delivery solutions for Kubernetes, which are open and extensible. It automates the deployment of container images, configuration changes, and other Kubernetes resources, ensuring that the cluster state matches the desired state defined in Git.

## Operator Installation

```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```