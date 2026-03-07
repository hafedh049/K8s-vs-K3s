# ⚡ K3s — Overview
> Lightweight Kubernetes — everything included, minimal footprint

---

## Guides

| Guide | Description |
|---|---|
| [Single Node](single-node/README.md) | One command install, instant cluster |
| [Multi-Node](multi-node/README.md) | 1 server + 2 agents + PostgreSQL HA |

---

## Quick Decision

| I want to... | Use |
|---|---|
| Get K8s running in 30 seconds | Single Node |
| Run on Raspberry Pi / ARM | Single Node |
| Build a small production cluster | Multi-Node |
| Learn Kubernetes the easy way | Single Node → Multi-Node |

---

## What Makes K3s Special in This Repo

- **PostgreSQL** — external datastore replacing SQLite for multi-node HA
- **Traefik** — built-in ingress controller (no extra install)
- **Flannel** — built-in CNI (replaced by Calico if NetworkPolicies needed)
- **Local Path Provisioner** — built-in persistent storage
- **Config File** — all settings in `/etc/rancher/k3s/config.yaml` instead of CLI flags
- **System Upgrade Controller** — zero-downtime cluster upgrades
