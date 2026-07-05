# Chapter 5 — Install Kubernetes (kubeadm)

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

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

> **Note:** If you are running on a `t2.micro` or any instance with less than 2GB of RAM/2 CPUs, `kubeadm` will fail with preflight checks. You can ignore those checks by running:
> ```bash
> sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU,Mem
> ```
> 
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

## Chapter 6 — Verify the Cluster

```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

You should see your single node in `Ready` state, and all system pods (`kube-system` namespace) in `Running` status. If Flannel pods aren't `Running` yet, wait a minute and re-check — the CNI plugin takes a moment to come up.
