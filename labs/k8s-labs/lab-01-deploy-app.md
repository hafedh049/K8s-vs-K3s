# 🧪 K8s Lab 01 — Deploy & Expose an Application
**Cluster:** K8s Multi-Node HA | **Node:** Run from cp1

---

## Objective
Deploy an nginx application, expose it via NodePort, and verify it's accessible from your browser.

---

## Step 1 — Create a Deployment

```bash
kubectl create deployment nginx-lab \
  --image=nginx \
  --replicas=3

# Watch pods come up
kubectl get pods -o wide -w
```

Expected: 3 pods spread across wk1, wk2, wk3.

---

## Step 2 — Expose via NodePort

```bash
kubectl expose deployment nginx-lab \
  --port=80 \
  --type=NodePort

kubectl get svc nginx-lab
# Note the NodePort (30000–32767 range)
```

---

## Step 3 — Access from Browser

```bash
# Get the NodePort
NODE_PORT=$(kubectl get svc nginx-lab -o jsonpath='{.spec.ports[0].nodePort}')
echo "Access at: http://192.168.3.180:${NODE_PORT}"
```

Open in browser: `http://192.168.3.180:<NodePort>`

---

## Step 4 — Scale Up and Down

```bash
# Scale to 6 replicas
kubectl scale deployment nginx-lab --replicas=6
kubectl get pods -o wide

# Scale down to 1
kubectl scale deployment nginx-lab --replicas=1
kubectl get pods -o wide
```

---

## Step 5 — Rolling Update

```bash
# Update image version
kubectl set image deployment/nginx-lab nginx=nginx:alpine

# Watch the rollout
kubectl rollout status deployment/nginx-lab

# Check history
kubectl rollout history deployment/nginx-lab
```

---

## Step 6 — Rollback

```bash
kubectl rollout undo deployment/nginx-lab
kubectl rollout status deployment/nginx-lab
```

---

## Cleanup

```bash
kubectl delete deployment nginx-lab
kubectl delete svc nginx-lab
```

---

## ✅ What You Learned
- Create and expose a Kubernetes deployment
- Scale replicas
- Perform rolling updates
- Rollback to previous version
