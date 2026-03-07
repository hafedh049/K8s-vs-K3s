# 🧪 K3s Lab 05 — Cluster Upgrade
**Cluster:** K3s Multi-Node | **Node:** Run from k3s-server

---

## Objective
Upgrade K3s using the system-upgrade-controller for zero-downtime upgrades.

---

## Step 1 — Check Current Version

```bash
k3s --version
kubectl get nodes
```

---

## Step 2 — Install System Upgrade Controller

```bash
kubectl apply -f \
  https://github.com/rancher/system-upgrade-controller/releases/latest/download/system-upgrade-controller.yaml

kubectl get pods -n system-upgrade -w
```

---

## Step 3 — Create Upgrade Plan for Server

```bash
cat <<EOF | kubectl apply -f -
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-server-upgrade
  namespace: system-upgrade
spec:
  concurrency: 1
  cordon: true
  channel: https://update.k3s.io/v1-release/channels/stable
  upgrade:
    image: rancher/k3s-upgrade
  selector:
    matchExpressions:
      - key: node-role.kubernetes.io/control-plane
        operator: In
        values: ["true"]
EOF
```

---

## Step 4 — Create Upgrade Plan for Agents

```bash
cat <<EOF | kubectl apply -f -
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-agent-upgrade
  namespace: system-upgrade
spec:
  concurrency: 2
  cordon: true
  prepare:
    image: rancher/k3s-upgrade
    args: ["prepare", "k3s-server-upgrade"]
  channel: https://update.k3s.io/v1-release/channels/stable
  upgrade:
    image: rancher/k3s-upgrade
  selector:
    matchExpressions:
      - key: node-role.kubernetes.io/control-plane
        operator: NotIn
        values: ["true"]
EOF
```

---

## Step 5 — Watch Upgrade Progress

```bash
kubectl get plans -n system-upgrade
kubectl get jobs -n system-upgrade -w
kubectl get nodes -w
```

---

## ✅ What You Learned
- Zero-downtime upgrade via system-upgrade-controller
- Server upgraded first, then agents
- Nodes cordoned during upgrade, then uncordoned
