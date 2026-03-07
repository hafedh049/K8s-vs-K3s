# ☸️ Kubernetes — Single Node
> A single-node K8s cluster (control plane + workloads on same machine).
> Good for learning and local development.
> Load variables: `source ../../variables.env`

---

## ⚠️ Prerequisites
Complete `shared/pre-installation.md` first.

---

## Step 1 — Install kubeadm, kubelet, kubectl

```bash
# Create keyrings directory
sudo mkdir -p /etc/apt/keyrings

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Pin versions
sudo apt-mark hold kubelet kubeadm kubectl

# Verify
kubectl version --client
kubeadm version
```

---

## Step 2 — Initialize Cluster

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}')
```

---

## Step 3 — Configure kubectl

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Apply alias and completion (see `shared/kubectl-config.md`).

---

## Step 4 — Install Calico CNI

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Wait for Calico pods
kubectl get pods -n calico-system -w
```

---

## Step 5 — Allow Scheduling on Master (Single Node)

By default, no pods schedule on master nodes. For single-node, remove the taint:

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

---

## Step 6 — Verify

```bash
kubectl get nodes
# STATUS should be Ready

kubectl get pods -A
# All pods should be Running
```

---

## Apply Resource Limits

```bash
kubectl apply -f manifests/limits.yaml
kubectl get limitrange -n default
```

---

## Install Metrics Server

```bash
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Test after 60 seconds
kubectl top nodes
```
