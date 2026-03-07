# 🧪 K3s Lab 02 — Scaling & Rolling Updates
**Cluster:** K3s Multi-Node | **Node:** Run from k3s-server

---

## Objective
Scale deployments and perform rolling updates on K3s.

---

## Step 1 — Deploy and Scale

```bash
kubectl create deployment scale-demo \
  --image=nginx \
  --replicas=4

kubectl get pods -o wide
# Should spread across both agents
```

---

## Step 2 — Manual Scaling

```bash
kubectl scale deployment scale-demo --replicas=8
kubectl get pods -o wide -w

kubectl scale deployment scale-demo --replicas=2
kubectl get pods -o wide
```

---

## Step 3 — Rolling Update

```bash
# Update image
kubectl set image deployment/scale-demo \
  nginx=nginx:alpine

# Watch rollout
kubectl rollout status deployment/scale-demo

# Verify new image
kubectl describe pods -l app=scale-demo | grep Image
```

---

## Step 4 — Rollback

```bash
kubectl rollout history deployment/scale-demo
kubectl rollout undo deployment/scale-demo
kubectl rollout status deployment/scale-demo
```

---

## Cleanup

```bash
kubectl delete deployment scale-demo
```
