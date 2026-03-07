# ⚡ K3s — Single Node
> The simplest way to run Kubernetes. One command, everything included.
> Server: `snk` at `192.168.3.184`
> Load variables: `source ../../variables.env`

---

## What's Included Out of the Box

| Component | K3s Built-in | K8s Equivalent |
|---|---|---|
| Container Runtime | containerd | Must install separately |
| CNI | Flannel | Must install (we use Calico) |
| Ingress | Traefik | Must install separately |
| DNS | CoreDNS | Must install separately |
| Storage | Local Path Provisioner | Must install separately |
| Helm Controller | ✅ | Must install separately |
| Load Balancer | ServiceLB | Must install separately |

---

## Step 1 — Install K3s Server

```bash
curl -sfL https://get.k3s.io | sh -
```

That's it. K3s is running.

---

## Step 2 — Verify

```bash
sudo systemctl status k3s

sudo k3s kubectl get nodes
```

---

## Step 3 — Configure kubectl for Regular User

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

Add alias and completion (see `shared/kubectl-config.md`):

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

---

## Step 4 — Fix crictl Endpoint

```bash
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock
sudo crictl config --set image-endpoint=unix:///run/containerd/containerd.sock
```

---

## Step 5 — Apply Configuration File (Recommended)

Instead of CLI flags, use a config file:

```bash
sudo mkdir -p /etc/rancher/k3s

cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
# Network
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
cluster-dns: "10.43.0.10"

# TLS — add your server IP so kubectl can connect by IP
tls-san:
  - "192.168.3.184"
  - "snk"

# Kubeconfig permissions (dev only)
write-kubeconfig-mode: "0644"

# Logging
log: "/var/log/k3s.log"

# Node labels
node-label:
  - "environment=dev"
  - "role=single-server"
EOF

sudo systemctl restart k3s
```

---

## Step 6 — Verify Everything

```bash
k get nodes
k get pods -A
```

---

## Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## Uninstall

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```
