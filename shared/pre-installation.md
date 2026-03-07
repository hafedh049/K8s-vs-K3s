# 🛠️ Pre-Installation — All Nodes
> Run these steps on **every node** before installing K8s or K3s.
> Load your variables first: `source ../../variables.env`

---

## Step 1 — Update System

```bash
sudo apt update && sudo apt upgrade -y
```

---

## Step 2 — Install Essential Utilities

```bash
sudo apt install -y \
  curl wget git \
  apt-transport-https \
  ca-certificates \
  gnupg lsb-release \
  software-properties-common \
  net-tools
```

---

## Step 3 — Set Hostname (run on each node individually)

```bash
# On cp1
sudo hostnamectl set-hostname cp1

# On cp2
sudo hostnamectl set-hostname cp2

# On cp3
sudo hostnamectl set-hostname cp3

# On wk1
sudo hostnamectl set-hostname wk1

# On wk2
sudo hostnamectl set-hostname wk2

# On wk3
sudo hostnamectl set-hostname wk3

# K3s nodes
# On k3s-server
sudo hostnamectl set-hostname k3s-server

# On k3s-agent-1
sudo hostnamectl set-hostname k3s-agent-1

# On k3s-agent-2
sudo hostnamectl set-hostname k3s-agent-2
```

---

## Step 4 — Configure /etc/hosts

```bash
sudo nano /etc/hosts
```

Add these entries (adjust IPs to match your environment from `variables.env`):

```
# K8s Nodes
192.168.3.129   cp1
192.168.3.179   cp2
192.168.3.181   cp3
192.168.3.180   wk1
192.168.3.182   wk2
192.168.3.178   wk3
192.168.3.200   k8s-vip

# K3s Nodes
192.168.3.184   k3s-server
192.168.3.185   k3s-agent-1
192.168.3.186   k3s-agent-2
```

---

## Step 5 — Disable Swap (Required for K8s, Optional for K3s)

```bash
# Disable immediately
sudo swapoff -a

# Disable permanently
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Verify — Swap row should show: 0B 0B 0B
free -h
```

---

## Step 6 — Load Kernel Modules

```bash
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

---

## Step 7 — Configure sysctl Networking

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

---

## Step 8 — Verify sysctl Settings

```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
# Both should return = 1
```

---

## Step 9 — Install Container Runtime (docker.io)

> We use `docker.io` because it ships with containerd as the underlying CRI runtime,
> while also giving you the Docker CLI for image management.

```bash
sudo apt install -y docker.io docker-compose
```

Configure containerd for Kubernetes compatibility:

```bash
# Generate default containerd config
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable SystemdCgroup — REQUIRED for kubeadm
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Verify
sudo systemctl status containerd
```

Fix crictl endpoint warning:

```bash
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock
sudo crictl config --set image-endpoint=unix:///run/containerd/containerd.sock
```

---

## ✅ Pre-Installation Checklist

| Step | Command to verify |
|---|---|
| Swap disabled | `free -h` → Swap: 0B |
| Kernel modules loaded | `lsmod \| grep overlay` |
| sysctl applied | `sysctl net.ipv4.ip_forward` → 1 |
| containerd running | `sudo systemctl status containerd` |
| Docker installed | `docker --version` |
