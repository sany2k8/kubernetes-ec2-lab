#!/usr/bin/env bash
set -euo pipefail

echo ">> Applying Kubernetes manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo ">> Waiting for rollout..."
kubectl rollout status deployment/webapp -n webapp

echo ">> Current state:"
kubectl get all -n webapp

echo ">> App will be reachable at http://<EC2_PUBLIC_IP>:30080"
