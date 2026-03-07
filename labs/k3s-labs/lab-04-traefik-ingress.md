# 🧪 K3s Lab 04 — Traefik Ingress Deep Dive
**Cluster:** K3s Multi-Node | **Node:** Run from k3s-server

---

## Objective
Explore Traefik's built-in features: path routing, middleware, and dashboard.

---

## Step 1 — View Traefik Status

```bash
kubectl get pods -n kube-system | grep traefik
kubectl get svc -n kube-system | grep traefik
```

---

## Step 2 — Deploy Two Apps

```bash
kubectl create deployment app-v1 --image=nginx --replicas=2
kubectl create deployment app-v2 --image=httpd --replicas=2
kubectl expose deployment app-v1 --port=80
kubectl expose deployment app-v2 --port=80
```

---

## Step 3 — Path-Based Routing

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-routing
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: app-v1
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: app-v2
            port:
              number: 80
EOF
```

```bash
echo "192.168.3.184 myapp.local" | sudo tee -a /etc/hosts
curl http://myapp.local/v1
curl http://myapp.local/v2
```

---

## Step 4 — Enable Traefik Dashboard

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-dashboard
  namespace: kube-system
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: traefik.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: traefik
            port:
              number: 8080
EOF

echo "192.168.3.184 traefik.local" | sudo tee -a /etc/hosts
# Open: http://traefik.local in browser
```

---

## Cleanup

```bash
kubectl delete deployment app-v1 app-v2
kubectl delete svc app-v1 app-v2
kubectl delete ingress path-routing
kubectl delete ingress traefik-dashboard -n kube-system
```
