# ☸ K8s vs K3s — Single & Multi-Node Guide
### Linux Mint (Ubuntu-based) · Production-Ready · Fully Documented

---

## 📋 Table of Contents

- [Overview & Comparison](#-overview--comparison)
- [When to Use K8s vs K3s](#-when-to-use-k8s-vs-k3s)
- [Repository Structure](#-repository-structure)
- [Quick Start](#-quick-start)
- [Labs](#-labs)

---

## 🔍 Overview & Comparison

### What are they?

| | Kubernetes (K8s) | K3s |
|---|---|---|
| Created by | Google → CNCF | Rancher (now CNCF) |
| Type | Full container orchestration | Lightweight K8s distribution |
| CNCF Certified | ✅ Yes | ✅ Yes |
| K8s API Compatible | ✅ Full | ✅ Full |
| Binary Size | ~500 MB (multiple components) | < 100 MB (single binary) |
| Min RAM | 4 GB per master | 512 MB |
| Min CPU | 2 vCPU | 1 vCPU |
| Default Datastore | etcd | SQLite |
| HA Datastore | etcd (built-in) | PostgreSQL / MySQL (external) |
| Default CNI | None (must install) | Flannel (built-in) |
| Default Ingress | None (must install) | Traefik (built-in) |
| Install Time | 30–60 minutes | < 2 minutes |
| ARM Support | ⚠️ Limited | ✅ Full (Raspberry Pi, IoT) |

---

### Container Runtime Comparison

| Runtime | Package | Size | Used by |
|---|---|---|---|
| **docker.io** | `apt install docker.io` | ~200 MB | Docker CLI + containerd |
| containerd | `apt install containerd.io` | ~50 MB | Standalone, no Docker CLI |
| CRI-O | `apt install cri-o` | ~30 MB | OpenShift-focused |

> **This repo uses `docker.io`** — it ships with containerd as the underlying runtime, giving you both the Docker CLI for image management and containerd as the CRI that Kubernetes/K3s talks to.

---

### CNI (Pod-to-Pod Networking) Comparison

| CNI | Network Policies | Performance | Complexity | Best For |
|---|---|---|---|---|
| **Calico** | ✅ Full | ⭐⭐⭐⭐⭐ | Medium | Production, security-sensitive |
| Flannel | ❌ None | ⭐⭐⭐⭐ | Low | Simple clusters, learning |
| Cilium | ✅ Full + eBPF | ⭐⭐⭐⭐⭐ | High | Advanced observability |
| Weave | ✅ Basic | ⭐⭐⭐ | Low | Small clusters |

> **This repo uses Calico** — it supports full NetworkPolicy enforcement, making it suitable for production multi-tenant workloads.

---

### Datastore Comparison (K3s Multi-Node)

| Datastore | Type | HA Support | Setup | Best For |
|---|---|---|---|---|
| **SQLite** | Embedded | ❌ Single node only | Zero config | Dev / single server |
| **PostgreSQL** | External | ✅ Full HA | Moderate | Production multi-server |
| MySQL/MariaDB | External | ✅ Full HA | Moderate | Production multi-server |
| etcd | External | ✅ Full HA | Complex | Large scale |

> **K3s Multi-Node in this repo uses PostgreSQL** — SQLite cannot be shared between multiple K3s servers, making it unsuitable for HA. PostgreSQL gives you a single source of truth for cluster state that all K3s server nodes read/write.

---

## 🎯 When to Use K8s vs K3s

### Use Kubernetes (K8s) when:
- ✅ Running **large-scale, multi-tenant production** workloads
- ✅ Your team has **dedicated DevOps/SRE** expertise
- ✅ You need **full enterprise features**: advanced RBAC, CRDs, cloud-controller
- ✅ Running on **managed cloud**: EKS, GKE, AKS
- ✅ Your cluster has **100+ nodes**
- ✅ You need **Windows node** support
- ✅ You require **GPU workloads** at scale

### Use K3s when:
- ✅ Deploying on **edge, IoT, or ARM** devices (Raspberry Pi)
- ✅ You want a **fast dev/test/CI** environment
- ✅ Your team is **small with limited infrastructure expertise**
- ✅ Resources are **constrained** (< 2 GB RAM, < 2 vCPU)
- ✅ You need **single-node or small-cluster** deployments
- ✅ You want **zero-fuss setup** with batteries included
- ✅ You're doing **homelab or learning** Kubernetes concepts

### K3s is BETTER than K8s when:
| Scenario | Why K3s wins |
|---|---|
| Raspberry Pi / ARM deployment | Native ARM support, 512 MB RAM enough |
| CI/CD ephemeral clusters | Spins up in < 30 seconds |
| Edge computing (factory floor, retail) | Runs offline, minimal footprint |
| Developer laptops | No VM overhead, runs natively |
| Small startup with 1 DevOps person | No etcd to manage, simple ops |

### K8s is BETTER than K3s when:
| Scenario | Why K8s wins |
|---|---|
| 50+ node clusters | K3s SQLite/PostgreSQL can't match etcd at scale |
| Multi-cloud federation | Full cloud-controller-manager support |
| Strict compliance (PCI-DSS, HIPAA) | More mature audit and policy tooling |
| Windows workloads | K3s doesn't support Windows nodes |
| GPU/ML workloads at scale | Better device plugin ecosystem |

---

## 📁 Repository Structure

```
k8s-vs-k3s/
│
├── README.md                          ← You are here
├── variables.env                      ← 🔧 ALL IPs and config variables
│
├── shared/
│   ├── pre-installation.md            ← Common steps for ALL nodes
│   ├── kubectl-config.md              ← kubectl alias, completion, kubeconfig
│   └── comparison-tables.md          ← All comparison tables reference
│
├── k8s/
│   ├── README.md                      ← K8s overview and index
│   ├── single-node/
│   │   ├── README.md                  ← Single-node K8s guide
│   │   └── manifests/
│   │       └── limits.yaml
│   └── multi-node-ha/
│       ├── README.md                  ← Full HA K8s guide (cp1-3, wk1-3)
│       ├── keepalived/
│       │   ├── README.md
│       │   ├── cp1-keepalived.conf    ← MASTER config
│       │   ├── cp2-keepalived.conf    ← BACKUP config
│       │   └── cp3-keepalived.conf    ← BACKUP config
│       ├── haproxy/
│       │   ├── README.md
│       │   └── haproxy.cfg
│       └── manifests/
│           ├── limits.yaml
│           ├── calico.yaml            ← CNI
│           └── longhorn.yaml          ← Storage
│
├── k3s/
│   ├── README.md                      ← K3s overview and index
│   ├── single-node/
│   │   ├── README.md                  ← Single-node K3s guide
│   │   └── config.yaml                ← K3s server config
│   └── multi-node/
│       ├── README.md                  ← Multi-node K3s guide
│       ├── postgresql/
│       │   ├── README.md              ← PostgreSQL setup for K3s HA
│       │   └── init.sql
│       ├── server/
│       │   ├── README.md
│       │   └── config.yaml            ← K3s server config
│       └── agents/
│           ├── README.md
│           └── config.yaml            ← K3s agent config
│
└── labs/
    ├── README.md                      ← Labs index
    ├── k8s-labs/
    │   ├── lab-01-deploy-app.md
    │   ├── lab-02-scaling.md
    │   ├── lab-03-ha-failover.md
    │   ├── lab-04-network-policies.md
    │   ├── lab-05-storage.md
    │   └── lab-06-monitoring.md
    └── k3s-labs/
        ├── lab-01-deploy-app.md
        ├── lab-02-scaling.md
        ├── lab-03-agent-failover.md
        ├── lab-04-traefik-ingress.md
        ├── lab-05-upgrade.md
        └── lab-06-multi-server-ha.md
```

---

## ⚡ Quick Start

### K8s Single Node
```bash
# 1. Set variables
source variables.env

# 2. Pre-installation
bash shared/scripts/pre-install.sh

# 3. Follow guide
cat k8s/single-node/README.md
```

### K8s HA (3 Masters + 3 Workers)
```bash
source variables.env
cat k8s/multi-node-ha/README.md
```

### K3s Single Node
```bash
curl -sfL https://get.k3s.io | sh -
cat k3s/single-node/README.md
```

### K3s Multi-Node
```bash
source variables.env
cat k3s/multi-node/README.md
```

---

## 🧪 Labs

| Lab | Type | Topic |
|---|---|---|
| K8s Lab 01 | K8s | Deploy & expose an application |
| K8s Lab 02 | K8s | Scaling and rolling updates |
| K8s Lab 03 | K8s | HA failover scenarios |
| K8s Lab 04 | K8s | Network policies with Calico |
| K8s Lab 05 | K8s | Persistent storage with Longhorn |
| K8s Lab 06 | K8s | Monitoring with Prometheus & Grafana |
| K3s Lab 01 | K3s | Deploy & expose an application |
| K3s Lab 02 | K3s | Scaling and rolling updates |
| K3s Lab 03 | K3s | Agent failover |
| K3s Lab 04 | K3s | Traefik ingress |
| K3s Lab 05 | K3s | Cluster upgrade |
| K3s Lab 06 | K3s | Multi-server HA with PostgreSQL |

---

*Linux Mint 22 · K8s v1.29 · K3s v1.34 · Calico v3.27 · March 2026*
