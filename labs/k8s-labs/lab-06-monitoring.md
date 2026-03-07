# 🧪 K8s Lab 06 — Monitoring with Prometheus & Grafana
**Cluster:** K8s Multi-Node HA | **Node:** Run from cp1

---

## Objective
Deploy the full monitoring stack, explore Grafana dashboards, and create alerts.

---

## Step 1 — Install Helm & Deploy Stack

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install prometheus \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin@k8s2026

kubectl get pods -n monitoring -w
```

---

## Step 2 — Expose Grafana via NodePort

```bash
kubectl patch svc prometheus-grafana \
  -n monitoring \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"nodePort":32000}]}}'

echo "Grafana: http://192.168.3.129:32000"
echo "User: admin | Pass: admin@k8s2026"
```

---

## Step 3 — Explore Dashboards

Open Grafana and explore:

| Dashboard | What it shows |
|---|---|
| Kubernetes / Nodes | CPU, RAM, disk per node |
| Kubernetes / Pods | Pod resource usage |
| Kubernetes / Cluster | Overall cluster health |
| Node Exporter Full | Detailed system metrics |

---

## Step 4 — Generate Load to See Metrics

```bash
# Deploy a load generator
kubectl run load-test \
  --image=busybox \
  --restart=Never \
  -- sh -c "while true; do wget -qO- http://kubernetes.default; done"

# Watch CPU spike in Grafana
kubectl top pods
kubectl top nodes
```

---

## Step 5 — Create a Prometheus Alert Rule

```bash
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: node-memory-alert
  namespace: monitoring
  labels:
    app: kube-prometheus-stack
    release: prometheus
spec:
  groups:
  - name: node.rules
    rules:
    - alert: NodeMemoryHigh
      expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.2
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "Node memory is above 80%"
        description: "Node {{ \$labels.instance }} memory usage is high"
EOF
```

---

## Step 6 — Check Prometheus Targets

```bash
# Expose Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus \
  9090:9090 -n monitoring

# Open: http://localhost:9090/targets
# All targets should be UP
```

---

## Cleanup

```bash
kubectl delete pod load-test
# Keep monitoring stack for future labs
```

---

## ✅ What You Learned
- Deploy Prometheus + Grafana with Helm
- Explore pre-built dashboards
- Generate load and observe metrics
- Create custom alert rules
