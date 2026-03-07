# 🧪 K3s Lab 03 — Agent Failover
**Cluster:** K3s Multi-Node | **Node:** Run from k3s-server

---

## Objective
Simulate agent node failure and verify pod rescheduling.

---

## Step 1 — Deploy Test App

```bash
kubectl create deployment failover-test \
  --image=nginx \
  --replicas=4

kubectl get pods -o wide
# Note which pods are on k3s-agent-1
```

---

## Step 2 — Simulate Agent Failure

```bash
# On k3s-agent-1
sudo shutdown -h now
```

Watch from k3s-server:

```bash
kubectl get pods -o wide -w
# Pods from agent-1 → Terminating → rescheduled on agent-2
```

---

## Step 3 — Verify Rescheduling

```bash
kubectl get pods -o wide
# All pods should be Running on k3s-agent-2
kubectl get nodes
# k3s-agent-1: NotReady
```

---

## Step 4 — Recover Agent

Power on k3s-agent-1. It auto-rejoins:

```bash
kubectl get nodes -w
# k3s-agent-1 returns to Ready automatically
```

---

## Cleanup

```bash
kubectl delete deployment failover-test
```

---

## ✅ What You Learned
- K3s handles agent failures automatically
- No manual intervention needed for unplanned shutdowns
- Pods reschedule within minutes
