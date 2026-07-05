#!/usr/bin/env bash
set -euo pipefail

echo ">> Deleting Kubernetes resources..."
kubectl delete -f k8s/ --ignore-not-found

echo ">> Removing Docker image..."
sudo docker image rm webapp:v1 2>/dev/null || true

echo ">> Cleanup complete."
