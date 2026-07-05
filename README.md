# Kubernetes EC2 Web App

A complete, hands-on project that teaches the **full Kubernetes workflow** — not just Kubernetes objects — by deploying a real Node.js web application on a self-managed `kubeadm` cluster running on an AWS EC2 instance.

Two ways to do everything in this repo:

1. **Manual, step-by-step** — run every command yourself and understand what it does.
2. **Automated** — run a handful of shell scripts that do the same thing for you.

---

## Table of Contents

- [Project Architecture](#project-architecture)
- [Project Tree](#project-tree)
- [Prerequisites](#prerequisites)
- [Part 1 — AWS Infrastructure](#part-1--aws-infrastructure)
- [Way 1: Manual Step-by-Step Deployment](#way-1-manual-step-by-step-deployment)
  - [Chapter 1 — Launch EC2](#chapter-1--launch-ec2)
  - [Chapter 2 — SSH Into the Server](#chapter-2--ssh-into-the-server)
  - [Chapter 3 — System Update](#chapter-3--system-update)
  - [Chapter 4 — Install Docker](#chapter-4--install-docker)
  - [Chapter 5 — Install Kubernetes (kubeadm)](#chapter-5--install-kubernetes-kubeadm)
  - [Chapter 6 — Verify the Cluster](#chapter-6--verify-the-cluster)
  - [Chapter 7 — Create the Node.js App](#chapter-7--create-the-nodejs-app)
  - [Chapter 8 — Run the App Locally](#chapter-8--run-the-app-locally)
  - [Chapter 9 — Dockerize the App](#chapter-9--dockerize-the-app)
  - [Chapter 10 — Kubernetes Manifests](#chapter-10--kubernetes-manifests)
  - [Chapter 11 — Scaling](#chapter-11--scaling)
  - [Chapter 12 — Rolling Updates & Rollback](#chapter-12--rolling-updates--rollback)
  - [Chapter 13 — Cleanup](#chapter-13--cleanup)
- [Way 2: Professional Automation (Bash Scripts)](#way-2-professional-automation-bash-scripts)
- [Bonus Exercises](#bonus-exercises)
- [Troubleshooting](#troubleshooting)
- [Why This Structure Works](#why-this-structure-works)

---

## Project Architecture

```
Laptop
  │
  ▼
AWS Account
  │
  ▼
Launch Ubuntu EC2
  │
  ▼
Configure Security Group
  │
  ▼
SSH into Server
  │
  ▼
Install Docker
  │
  ▼
Install Kubernetes (kubeadm)
  │
  ▼
Create Web App (Node.js)
  │
  ▼
Build Docker Image
  │
  ▼
Kubernetes Deployment
  │
  ▼
Expose Service
  │
  ▼
Access via EC2 Public IP
```

---

## Project Tree

This is the full repository layout. Create it exactly like this so every path referenced later in this README lines up.

```
kubernetes-ec2-webapp/
│
├── README.md
│
├── manual-deployment/
│   ├── 01-ec2-setup.md
│   ├── 02-install-docker.md
│   ├── 03-install-kubernetes.md
│   ├── 04-create-node-app.md
│   ├── 05-build-docker-image.md
│   ├── 06-deploy-kubernetes.md
│   ├── 07-access-application.md
│   └── troubleshooting.md
│
├── automation/
│   ├── 01-server-setup.sh
│   ├── 02-install-docker.sh
│   ├── 03-install-kubernetes.sh
│   ├── 04-create-project.sh
│   ├── 05-build-image.sh
│   ├── 06-deploy.sh
│   ├── 07-scale.sh
│   └── cleanup.sh
│
├── app/
│   ├── server.js
│   ├── package.json
│   ├── Dockerfile
│   └── public/
│       └── index.html
│
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
└── screenshots/
```

---

## Prerequisites

- An AWS account with permission to launch EC2 instances and edit Security Groups.
- A local machine with SSH and a terminal (macOS, Linux, or WSL on Windows).
- Basic comfort with the command line. No prior Kubernetes experience required — that's the point of this repo.
- A GitHub account if you want to push this project (optional but recommended).

---

## Part 1 — AWS Infrastructure

### Chapter 1 — Launch EC2

1. Log into the AWS Console → **EC2** → **Launch Instance**.
2. **AMI**: Ubuntu Server 24.04 LTS.
3. **Instance type**: `t2.medium` (recommended — `t2.micro` is too small for `kubeadm`; the control plane alone needs ~2 CPUs and 2GB+ RAM).
4. **Key pair**: create a new one (e.g. `my-key.pem`) and download it. You'll use this to SSH in.
5. **Security Group**: open the following inbound ports.

| Port        | Purpose        |
| ----------- | -------------- |
| 22          | SSH |
| 80          | HTTP |
| 443         | HTTPS |
| 6443        | Kubernetes API server |
| 30000-32767 | NodePort range (how you'll reach the app via Kubernetes Service) |

> Why these ports: SSH (22) is how you administer the box. 80/443 are standard web traffic if you later put this behind Ingress/a load balancer. 6443 is the Kubernetes API server port — kubectl and cluster components talk to it here. The 30000-32767 range is where Kubernetes exposes `NodePort` Services by default.

6. Launch the instance and note its **Public IPv4 address**.

Lock down your key file permissions locally:

```bash
chmod 400 my-key.pem
```

---

### Chapter 2 — SSH Into the Server

```bash
ssh -i my-key.pem ubuntu@<EC2_PUBLIC_IP>
```

Verify you're in and check basic environment info:

```bash
whoami
hostname
pwd
```

---

### Chapter 3 — System Update

```bash
sudo apt update
sudo apt upgrade -y
```

**Why:** `apt update` refreshes the local package index so apt knows about the latest available versions. `apt upgrade -y` installs those updates without prompting. Doing this first avoids compatibility issues when installing Docker and Kubernetes packages later.

---

### Chapter 4 — Install Docker

```bash
sudo apt install docker.io -y
```

Enable Docker to start on boot and start it now:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Verify:

```bash
docker version
docker ps
```

Add your user to the `docker` group so you don't need `sudo` for every docker command (log out/in or run `newgrp docker` afterwards):

```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

### Chapter 5 — Install Kubernetes (kubeadm)

This project uses `kubeadm` instead of Minikube because `kubeadm` mirrors how real production clusters are bootstrapped.

**Key components:**

- **containerd** — the container runtime that actually runs your containers (Docker uses it under the hood too).
- **kubeadm** — the tool that bootstraps a Kubernetes cluster.
- **kubelet** — the agent that runs on every node and manages pods.
- **kubectl** — the CLI you use to talk to the cluster.

Install containerd:

```bash
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

Disable swap (Kubernetes requires this):

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

Load required kernel modules and sysctl settings:

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

Add the Kubernetes apt repository and install `kubeadm`, `kubelet`, `kubectl`:

```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Initialize the cluster:

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

> The `--pod-network-cidr` must match the CIDR expected by the pod network add-on you install next (Flannel uses `10.244.0.0/16`).

Configure `kubectl` for your user (copy the admin config kubeadm generated):

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install the Flannel pod network add-on (lets pods on different nodes talk to each other):

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Since this is a single-node cluster, allow the control-plane node to also run application pods:

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

---

### Chapter 6 — Verify the Cluster

```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

You should see your single node in `Ready` state, and all system pods (`kube-system` namespace) in `Running` status. If Flannel pods aren't `Running` yet, wait a minute and re-check — the CNI plugin takes a moment to come up.

---

### Chapter 7 — Create the Node.js App

```bash
mkdir -p app/public
cd app
```

**`app/package.json`** — Refer to [app/package.json](app/package.json) for the configuration.

**`app/server.js`** — Refer to [app/server.js](app/server.js) for the Express server routing and setup.

**`app/public/index.html`** — Refer to [app/public/index.html](app/public/index.html) for the web UI code.


---

### Chapter 8 — Run the App Locally

```bash
npm install
node server.js
```

Open in your browser:

```
http://<EC2_PUBLIC_IP>:3000
```

(Make sure port 3000 is open in the Security Group temporarily, or just test with `curl localhost:3000` on the box.)

---

### Chapter 9 — Dockerize the App

**`app/Dockerfile`** — Refer to [app/Dockerfile](app/Dockerfile) for the Docker build instructions.


Build the image:

```bash
docker build -t webapp:v1 .
```

Run it standalone to sanity-check it before Kubernetes gets involved:

```bash
docker run -d -p 3000:3000 --name webapp-test webapp:v1
docker ps
curl localhost:3000/api/health
docker stop webapp-test && docker rm webapp-test
```

> **Note on images and kubeadm:** since this is a single-node cluster using containerd, the image built with `docker build` needs to be visible to containerd. The simplest path for a learning setup is to import it directly:
> ```bash
> docker save webapp:v1 -o webapp.tar
> sudo ctr -n=k8s.io images import webapp.tar
> ```
> In production you'd instead push to a registry (Docker Hub, ECR, GHCR) and reference it by tag in your Deployment — this is listed as a bonus exercise below.

---

### Chapter 10 — Kubernetes Manifests

Core concepts before the YAML:

- **Pod** — the smallest deployable unit; one or more containers sharing network/storage.
- **ReplicaSet** — ensures a specified number of identical Pods are running at all times.
- **Deployment** — manages ReplicaSets for you, and enables rolling updates/rollbacks.
- **Service** — a stable network endpoint that load-balances traffic across a set of Pods.
- **Selector / Labels** — how Services and Deployments find the Pods they manage (key/value tags matched between the Pod template and the selector).
- **Namespace** — a virtual cluster-within-a-cluster used to group and isolate resources.

**`k8s/namespace.yaml`** — Refer to [k8s/namespace.yaml](k8s/namespace.yaml) for the namespace specification.

**`k8s/deployment.yaml`** — Refer to [k8s/deployment.yaml](k8s/deployment.yaml) for the deployment template, replica sizing, probe configs, and resource limits.

**`k8s/service.yaml`** — Refer to [k8s/service.yaml](k8s/service.yaml) for the NodePort service exposing the application.

**`k8s/ingress.yaml`** (optional bonus — see [Bonus Exercises](#bonus-exercises)) — Refer to [k8s/ingress.yaml](k8s/ingress.yaml) for routing setup.


Apply everything (in order — namespace first):

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Verify:

```bash
kubectl get all -n webapp
kubectl get pods -n webapp
kubectl describe pod <pod-name> -n webapp
kubectl logs <pod-name> -n webapp
```

---

### Chapter 11 — Access the Application

```bash
http://<EC2_PUBLIC_IP>:30080
```

Make sure port `30080` (within the 30000-32767 NodePort range you opened in Chapter 1) is reachable in your Security Group.

---

### Chapter 11 — Scaling

```bash
kubectl scale deployment webapp -n webapp --replicas=4
```

Watch it happen:

```bash
kubectl get pods -n webapp -w
```

---

### Chapter 12 — Rolling Updates & Rollback

Build and import a new version of the image (tag it `v2`), then:

```bash
kubectl set image deployment/webapp webapp=webapp:v2 -n webapp
```

Check rollout status and history:

```bash
kubectl rollout status deployment/webapp -n webapp
kubectl rollout history deployment/webapp -n webapp
```

Roll back if something's wrong:

```bash
kubectl rollout undo deployment/webapp -n webapp
```

---

### Chapter 13 — Cleanup

```bash
kubectl delete -f k8s/
docker image rm webapp:v1
```

---

## Way 2: Professional Automation (Bash Scripts)

Everything above, encapsulated into scripts under `automation/`. This is how you'd hand this project to a teammate, or wire it into CI.

**`automation/01-server-setup.sh`** — Refer to [automation/01-server-setup.sh](automation/01-server-setup.sh)

**`automation/02-install-docker.sh`** — Refer to [automation/02-install-docker.sh](automation/02-install-docker.sh)

**`automation/03-install-kubernetes.sh`** — Refer to [automation/03-install-kubernetes.sh](automation/03-install-kubernetes.sh)

**`automation/04-create-project.sh`** — Refer to [automation/04-create-project.sh](automation/04-create-project.sh)

**`automation/05-build-image.sh`** — Refer to [automation/05-build-image.sh](automation/05-build-image.sh)

**`automation/06-deploy.sh`** — Refer to [automation/06-deploy.sh](automation/06-deploy.sh)

**`automation/07-scale.sh`** — Refer to [automation/07-scale.sh](automation/07-scale.sh)

**`automation/cleanup.sh`** — Refer to [automation/cleanup.sh](automation/cleanup.sh)


### Run the automation

Make all scripts executable and run them in order:

```bash
chmod +x automation/*.sh

./automation/01-server-setup.sh
./automation/02-install-docker.sh
./automation/03-install-kubernetes.sh
./automation/04-create-project.sh
./automation/05-build-image.sh
./automation/06-deploy.sh
```

Or run the whole sequence in a loop:

```bash
for script in automation/01-server-setup.sh automation/02-install-docker.sh automation/03-install-kubernetes.sh automation/04-create-project.sh automation/05-build-image.sh automation/06-deploy.sh
do
    bash "$script"
done
```

> Note: `01-server-setup.sh` and `02-install-docker.sh` may require you to reconnect your SSH session (or run `newgrp docker`) before continuing, since group membership changes need a fresh shell.

Scale on demand:

```bash
./automation/07-scale.sh 6
```

Tear everything down:

```bash
./automation/cleanup.sh
```

---

## Bonus Exercises

Once the core deployment works end-to-end, try these to go deeper:

- [ ] Deploy with 3 replicas, then scale to 10.
- [ ] Perform a rolling update from `v1` to `v2`, then roll back.
- [ ] View pod logs (`kubectl logs -f <pod> -n webapp`).
- [ ] Exec into a running pod (`kubectl exec -it <pod> -n webapp -- sh`).
- [ ] Delete a pod manually and watch Kubernetes recreate it.
- [ ] Install Metrics Server and inspect resource usage (`kubectl top pods -n webapp`).
- [ ] Deploy a second application into its own namespace.
- [ ] Add/adjust readiness and liveness probes.
- [ ] Add resource requests and limits (already included above — try tuning them).
- [ ] Mount a ConfigMap into the app for environment-specific config.
- [ ] Store a sensitive value in a Kubernetes Secret and consume it as an env var.
- [ ] Install an NGINX Ingress Controller and use `k8s/ingress.yaml` instead of NodePort.
- [ ] Attach a PersistentVolume/PersistentVolumeClaim and persist data across pod restarts.
- [ ] Push the image to a real registry (Docker Hub, ECR, or GHCR) instead of importing it locally.
- [ ] Wire up a multi-node cluster by joining a second EC2 instance as a worker.
- [ ] Package the manifests as a Helm chart.
- [ ] Add a GitHub Actions workflow that builds the image and deploys on every push.

---

## Troubleshooting

**`kubectl get nodes` shows `NotReady`**
Usually means the pod network add-on (Flannel) isn't up yet. Check with `kubectl get pods -n kube-system` and wait, or check `kubectl describe node <node>` for specific errors.

**Pods stuck in `Pending`**
Run `kubectl describe pod <pod> -n webapp` and check the `Events` section — common causes are insufficient CPU/memory on the node, or an unschedulable taint (see Chapter 5's taint-removal step).

**Pods stuck in `ImagePullBackOff`**
Since `imagePullPolicy: Never` is set, this means the image wasn't imported into containerd correctly. Re-run the `docker save` / `ctr images import` steps (or `automation/05-build-image.sh`) and confirm with `sudo ctr -n=k8s.io images ls`.

**Can't reach the app from your browser**
Check that port `30080` is open in the EC2 Security Group, and that you're using the EC2 **public** IP, not private.

**`kubeadm init` fails with swap-related error**
Confirm swap is actually off: `swapon --show` should print nothing. Re-run `sudo swapoff -a`.

**Lost `kubectl` access after reconnecting SSH**
Your `$HOME/.kube/config` only exists for the user who ran `kubeadm init`. Make sure you're re-running the `mkdir -p $HOME/.kube && sudo cp ...` steps under the same user, or export `KUBECONFIG=/etc/kubernetes/admin.conf`.

---

## Why This Structure Works

This repository supports two learning paths from the same source of truth:

- **Manual deployment** (`manual-deployment/`) — every command is run and explained step by step, building real understanding of Docker, EC2 networking, and Kubernetes internals.
- **Automated deployment** (`automation/`) — the same workflow, encapsulated into reusable, idempotent-where-possible shell scripts, showing how manual operations evolve into repeatable infrastructure automation.