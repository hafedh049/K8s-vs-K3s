# 🧪 K8s Lab 02 — Scaling & Resource Management
**Cluster:** K8s Multi-Node HA | **Node:** Run from cp1

---

## Objective
Practice manual and automatic scaling, resource requests/limits, and pod disruption budgets.

---

## Step 1 — Deploy with Resource Limits

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-demo
  template:
    metadata:
      labels:
        app: resource-demo
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF
```

---

## Step 2 — View Resource Usage

```bash
# Requires metrics-server
kubectl top pods
kubectl top nodes
```

---

## Step 3 — Horizontal Pod Autoscaler (HPA)

```bash
# Expose the deployment
kubectl expose deployment resource-demo --port=80

# Create HPA — scale between 2 and 10 based on CPU
kubectl autoscale deployment resource-demo \
  --cpu-percent=50 \
  --min=2 \
  --max=10

kubectl get hpa
kubectl describe hpa resource-demo
```

---

## Step 4 — Pod Disruption Budget

```bash
cat <<EOF | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: resource-demo-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: resource-demo
EOF

kubectl get pdb
```

This ensures at least 2 pods stay running during node drains.

---

## Step 5 — Test Node Drain Respect

```bash
# Try to drain wk1 — PDB will enforce minAvailable
kubectl drain wk1 --ignore-daemonsets --delete-emptydir-data

# Watch pods
kubectl get pods -o wide -w

# Restore wk1
kubectl uncordon wk1
```

---

## Cleanup

```bash
kubectl delete deployment resource-demo
kubectl delete svc resource-demo
kubectl delete hpa resource-demo
kubectl delete pdb resource-demo-pdb
```

---

## ✅ What You Learned
- Set resource requests and limits
- Create Horizontal Pod Autoscaler
- Create Pod Disruption Budget
- Test drain behavior with PDB
