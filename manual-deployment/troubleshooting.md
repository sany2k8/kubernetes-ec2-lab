# Troubleshooting Guide

**`kubectl get nodes` shows `NotReady`**
Usually means the pod network add-on (Flannel) isn't up yet. Check with `kubectl get pods -n kube-system` and wait, or check `kubectl describe node <node>` for specific errors.

**Pods stuck in `Pending`**
Run `kubectl describe pod <pod> -n webapp` and check the `Events` section — common causes are insufficient CPU/memory on the node, or an unschedulable taint (see Chapter 5's taint-removal step).

**Pods stuck in `ImagePullBackOff`**
Since `imagePullPolicy: Never` is set, this means the image wasn't imported into containerd correctly. Re-run the `docker save` / `ctr images import` steps (or `automation/05-build-image.sh`) and confirm with `sudo ctr -n=k8s.io images` or similar and confirm.

**Can't reach the app from your browser**
Check that port `30080` is open in the EC2 Security Group, and that you're using the EC2 **public** IP, not private.

**`kubeadm init` fails with swap-related error**
Confirm swap is actually off: `swapon --show` should print nothing. Re-run `sudo swapoff -a`.

**Lost `kubectl` access after reconnecting SSH**
Your `$HOME/.kube/config` only exists for the user who ran `kubeadm init`. Make sure you're re-running the `mkdir -p $HOME/.kube && sudo cp ...` steps under the same user, or export `KUBECONFIG=/etc/kubernetes/admin.conf`.
