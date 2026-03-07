# 🧪 K3s Lab 01 — Deploy & Expose an Application
**Cluster:** K3s Multi-Node | **Node:** Run from k3s-server

---

## Objective
Deploy an application on K3s, expose it via the built-in Traefik ingress, and compare the experience with K8s.

---

## Step 1 — Deploy Application

```bash
kubectl create deployment hello-k3s \
  --image=nginx \
  --replicas=2

kubectl get pods -o wide
# Pods should spread across k3s-agent-1 and k3s-agent-2
```

---

## Step 2 — Expose via ClusterIP

```bash
kubectl expose deployment hello-k3s --port=80
kubectl get svc hello-k3s
```

---

## Step 3 — Expose via NodePort

```bash
kubectl patch svc hello-k3s \
  -p '{"spec":{"type":"NodePort"}}'

NODE_PORT=$(kubectl get svc hello-k3s \
  -o jsonpath='{.spec.ports[0].nodePort}')

echo "Access: http://192.168.3.185:${NODE_PORT}"
curl http://192.168.3.185:${NODE_PORT}
```

---

## Step 4 — Expose via Traefik Ingress (K3s Built-in)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: hello.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-k3s
            port:
              number: 80
EOF
```

```bash
# Add to /etc/hosts on your machine
echo "192.168.3.184 hello.local" | sudo tee -a /etc/hosts

# Access
curl http://hello.local
```

---

## Step 5 — Compare K3s vs K8s Ingress Setup

| Step | K8s | K3s |
|---|---|---|
| Ingress controller | Must install NGINX manually | Traefik built-in ✅ |
| Ingress class | Must specify | Auto-detected |
| Setup time | 5–10 minutes | 0 minutes |

---

## Cleanup

```bash
kubectl delete deployment hello-k3s
kubectl delete svc hello-k3s
kubectl delete ingress hello-ingress
```

---

## ✅ What You Learned
- Deploy on K3s multi-node cluster
- NodePort exposure
- Traefik ingress (built-in, no extra install)
- Compare with K8s ingress approach
