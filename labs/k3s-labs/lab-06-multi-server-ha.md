# 🧪 K3s Lab 06 — Multi-Server HA with PostgreSQL
**Cluster:** K3s Multi-Node | **Node:** Run from k3s-server

---

## Objective
Understand how PostgreSQL enables K3s HA, test server failover, and compare with K8s HA approach.

---

## Step 1 — Verify PostgreSQL is the Datastore

```bash
# Check K3s is using PostgreSQL
sudo cat /etc/rancher/k3s/config.yaml | grep datastore

# Verify PostgreSQL connection
psql -h 192.168.3.184 -U k3suser -d k3s -c "SELECT count(*) FROM kine;"
# kine is the table K3s uses to store cluster state
```

---

## Step 2 — Inspect Cluster State in PostgreSQL

```bash
psql -h 192.168.3.184 -U k3suser -d k3s <<EOF
-- View recent cluster events
SELECT name, created, deleted
FROM kine
ORDER BY id DESC
LIMIT 20;
EOF
```

---

## Step 3 — Deploy Test Workload

```bash
kubectl create deployment pg-test --image=nginx --replicas=4
kubectl get pods -o wide
```

---

## Step 4 — Simulate Server Restart

```bash
# Restart K3s server (not full shutdown)
sudo systemctl restart k3s

# Agents maintain their workloads
kubectl get pods -o wide
# Pods keep running on agents during server restart
```

---

## Step 5 — Compare K3s vs K8s HA

| Aspect | K8s HA | K3s HA (PostgreSQL) |
|---|---|---|
| State storage | etcd (built-in, distributed) | PostgreSQL (external) |
| Min masters for quorum | 3 (for 2/3 quorum) | 1 server + external DB |
| Database location | On masters themselves | Separate DB host |
| Complexity | High (etcd management) | Moderate (PostgreSQL ops) |
| Backup | etcd snapshot | pg_dump |
| Recovery | etcd restore | Restore DB + reinstall |
| Masters needed for HA | 3+ | 2+ (DB provides HA) |

---

## Step 6 — Backup the Cluster State

```bash
# PostgreSQL backup
pg_dump -h 192.168.3.184 -U k3suser k3s > k3s-backup-$(date +%Y%m%d).sql

# Verify backup
ls -lh k3s-backup-*.sql
```

---

## Cleanup

```bash
kubectl delete deployment pg-test
```

---

## ✅ What You Learned
- PostgreSQL stores all K3s cluster state in the `kine` table
- Server can restart without affecting running pods on agents
- K3s HA is simpler operationally than K8s etcd HA
- PostgreSQL gives you standard DB backup/restore for cluster state
