#!/usr/bin/env bash
set -euo pipefail

REPLICAS="${1:-4}"

echo ">> Scaling webapp deployment to $REPLICAS replicas..."
kubectl scale deployment webapp -n webapp --replicas="$REPLICAS"
kubectl get pods -n webapp
