# ☸️ Kubernetes (K8s) — Overview
> Full enterprise-grade container orchestration

---

## Guides

| Guide | Description |
|---|---|
| [Single Node](single-node/README.md) | One machine: control plane + workloads |
| [Multi-Node HA](multi-node-ha/README.md) | 3 masters + 3 workers + Keepalived + HAProxy |

---

## Quick Decision

| I want to... | Use |
|---|---|
| Learn K8s on one machine | Single Node |
| Build a production-grade HA cluster | Multi-Node HA |
| Test K8s without much hardware | Single Node |

---

## What Makes K8s HA Special in This Repo

- **Keepalived** — floating VIP `192.168.3.200` across cp1, cp2, cp3
- **HAProxy** — health-check load balancing on port 8443
- **etcd** — distributed on all 3 masters (2/3 quorum)
- **Calico** — CNI with full NetworkPolicy support
- **Longhorn** — distributed persistent storage
- **Prometheus + Grafana** — full observability stack
