#!/usr/bin/env bash
set -euo pipefail

echo ">> Installing Docker..."
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"

docker version
echo ">> Docker installed. Log out/in (or run 'newgrp docker') to use docker without sudo."
