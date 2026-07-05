# Part 1 — AWS Infrastructure & Server Setup

## Chapter 1 — Launch EC2

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

## Chapter 2 — SSH Into the Server

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

## Chapter 3 — System Update

```bash
sudo apt update
sudo apt upgrade -y
```

**Why:** `apt update` refreshes the local package index so apt knows about the latest available versions. `apt upgrade -y` installs those updates without prompting. Doing this first avoids compatibility issues when installing Docker and Kubernetes packages later.
