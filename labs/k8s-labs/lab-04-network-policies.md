# 🧪 K8s Lab 04 — Network Policies with Calico
**Cluster:** K8s Multi-Node HA | **Node:** Run from cp1

---

## Objective
Use Calico NetworkPolicies to control pod-to-pod communication.

---

## Step 1 — Deploy Frontend and Backend

```bash
# Backend
kubectl create deployment backend \
  --image=nginx --replicas=2
kubectl expose deployment backend --port=80

# Frontend
kubectl create deployment frontend \
  --image=nginx --replicas=2
kubectl expose deployment frontend --port=80

# Label pods
kubectl label pods -l app=backend tier=backend
kubectl label pods -l app=frontend tier=frontend
```

---

## Step 2 — Verify Open Communication (Before Policy)

```bash
# Get a frontend pod name
FRONTEND_POD=$(kubectl get pods -l app=frontend -o name | head -1)

# Test: frontend can reach backend
kubectl exec $FRONTEND_POD -- curl -s http://backend
# Should succeed
```

---

## Step 3 — Apply Deny-All Policy

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

**Test after deny-all:**
```bash
kubectl exec $FRONTEND_POD -- curl -s --max-time 3 http://backend
# Should TIMEOUT — all traffic blocked
```

---

## Step 4 — Allow Frontend → Backend Only

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
```

**Test:**
```bash
# Frontend → Backend: should WORK
kubectl exec $FRONTEND_POD -- curl -s http://backend

# Backend → Frontend: should FAIL (no policy allows this)
BACKEND_POD=$(kubectl get pods -l app=backend -o name | head -1)
kubectl exec $BACKEND_POD -- curl -s --max-time 3 http://frontend
```

---

## Step 5 — Allow DNS Resolution

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: default
spec:
  podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF
```

---

## Step 6 — View All Policies

```bash
kubectl get networkpolicies
kubectl describe networkpolicy allow-frontend-to-backend
```

---

## Cleanup

```bash
kubectl delete deployment frontend backend
kubectl delete svc frontend backend
kubectl delete networkpolicy deny-all allow-frontend-to-backend allow-dns
```

---

## ✅ What You Learned
- Default open communication between pods
- Deny-all baseline policy
- Selective allow policies
- Why Calico is needed (Flannel has no NetworkPolicy support)
