#!/usr/bin/env bash
set -euo pipefail

cd app
echo ">> Building Docker image webapp:v1..."
docker build -t webapp:v1 .

echo ">> Importing image into containerd (k8s.io namespace) for kubeadm to use..."
docker save webapp:v1 -o /tmp/webapp.tar
sudo ctr -n=k8s.io images import /tmp/webapp.tar
rm /tmp/webapp.tar

echo ">> Image built and imported."
