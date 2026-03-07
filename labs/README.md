# 🧪 Labs Index
### K8s vs K3s · Hands-On Practice

---

## Kubernetes (K8s) Labs

| Lab | Topic | Difficulty | Cluster |
|---|---|---|---|
| [Lab 01](k8s-labs/lab-01-deploy-app.md) | Deploy & Expose an Application | ⭐ Beginner | K8s HA |
| [Lab 02](k8s-labs/lab-02-scaling.md) | Scaling & Resource Management | ⭐⭐ Intermediate | K8s HA |
| [Lab 03](k8s-labs/lab-03-ha-failover.md) | HA Failover Scenarios | ⭐⭐⭐ Advanced | K8s HA |
| [Lab 04](k8s-labs/lab-04-network-policies.md) | Network Policies with Calico | ⭐⭐⭐ Advanced | K8s HA |
| [Lab 05](k8s-labs/lab-05-storage.md) | Persistent Storage with Longhorn | ⭐⭐ Intermediate | K8s HA |
| [Lab 06](k8s-labs/lab-06-monitoring.md) | Monitoring with Prometheus & Grafana | ⭐⭐ Intermediate | K8s HA |

---

## K3s Labs

| Lab | Topic | Difficulty | Cluster |
|---|---|---|---|
| [Lab 01](k3s-labs/lab-01-deploy-app.md) | Deploy & Expose with Traefik | ⭐ Beginner | K3s Multi |
| [Lab 02](k3s-labs/lab-02-scaling.md) | Scaling & Rolling Updates | ⭐ Beginner | K3s Multi |
| [Lab 03](k3s-labs/lab-03-agent-failover.md) | Agent Failover | ⭐⭐ Intermediate | K3s Multi |
| [Lab 04](k3s-labs/lab-04-traefik-ingress.md) | Traefik Ingress Deep Dive | ⭐⭐ Intermediate | K3s Multi |
| [Lab 05](k3s-labs/lab-05-upgrade.md) | Cluster Upgrade | ⭐⭐ Intermediate | K3s Multi |
| [Lab 06](k3s-labs/lab-06-multi-server-ha.md) | Multi-Server HA with PostgreSQL | ⭐⭐⭐ Advanced | K3s Multi |

---

## Recommended Order

### Beginner Path
1. K3s Lab 01 → K3s Lab 02 → K8s Lab 01 → K8s Lab 02

### Intermediate Path
2. K3s Lab 03 → K3s Lab 04 → K8s Lab 05 → K8s Lab 06

### Advanced Path
3. K8s Lab 03 (HA Failover) → K8s Lab 04 (Network Policies) → K3s Lab 06 (PostgreSQL HA)
