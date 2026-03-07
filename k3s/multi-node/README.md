# ⚡ K3s — Multi-Node Cluster
### 1 Server + 2 Agents · PostgreSQL Datastore · Production-Ready
> Load variables: `source ../../variables.env`

---

## 🗺️ Architecture

```
                k3s-server (192.168.3.184)
                │   K3s Control Plane
                │   API Server + Scheduler + Controller (single binary)
                │   PostgreSQL Client
                │
                │── PostgreSQL DB (192.168.3.184:5432)
                │   Shared cluster state (replaces SQLite)
                │
        ┌───────┴───────┐
        │               │
k3s-agent-1         k3s-agent-2
(192.168.3.185)     (192.168.3.186)
   Worker               Worker
```

---

## 📋 Node Reference

| Hostname | IP | Role |
|---|---|---|
| k3s-server | 192.168.3.184 | Server (Control Plane) |
| k3s-agent-1 | 192.168.3.185 | Agent (Worker) |
| k3s-agent-2 | 192.168.3.186 | Agent (Worker) |

---

## Why PostgreSQL Instead of SQLite?

| Feature | SQLite | PostgreSQL |
|---|---|---|
| Multi-server HA | ❌ Cannot share between servers | ✅ All servers share one DB |
| Data persistence | Local file only | Dedicated DB server |
| Concurrent writes | ❌ Single writer | ✅ Multiple writers |
| Backup | Copy file | pg_dump / streaming replication |
| Production ready | ❌ Dev/single node only | ✅ Yes |
| Setup complexity | Zero (built-in) | Moderate |

> **Bottom line:** If you want more than one K3s server node, you MUST use an external datastore. SQLite is a local file and cannot be accessed by multiple machines simultaneously.

---

## Phase 1 — Install PostgreSQL (on k3s-server)

```bash
sudo apt install -y postgresql postgresql-contrib

sudo systemctl enable --now postgresql
sudo systemctl status postgresql
```

### Create K3s Database and User

```bash
sudo -u postgres psql <<EOF
CREATE USER k3suser WITH PASSWORD 'k3s@Secure2026';
CREATE DATABASE k3s OWNER k3suser;
GRANT ALL PRIVILEGES ON DATABASE k3s TO k3suser;
EOF
```

### Allow Remote Connections (if DB is on separate host)

```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/*/main/postgresql.conf
# Change: listen_addresses = 'localhost'
# To:     listen_addresses = '*'

# Edit pg_hba.conf
sudo nano /etc/postgresql/*/main/pg_hba.conf
# Add this line:
# host    k3s    k3suser    192.168.3.0/24    md5

sudo systemctl restart postgresql
```

### Verify Connection

```bash
psql -h 192.168.3.184 -U k3suser -d k3s -c "\l"
# Should show k3s database
```

---

## Phase 2 — Install K3s Server with PostgreSQL

### Option A — Using Config File (Recommended)

```bash
sudo mkdir -p /etc/rancher/k3s

cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
# Datastore — PostgreSQL for HA
datastore-endpoint: "postgres://k3suser:k3s@Secure2026@192.168.3.184:5432/k3s"

# Network
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
cluster-dns: "10.43.0.10"

# TLS
tls-san:
  - "192.168.3.184"
  - "k3s-server"

# Kubeconfig permissions
write-kubeconfig-mode: "0644"

# Logging
log: "/var/log/k3s.log"

# Node labels
node-label:
  - "environment=production"
  - "role=server"
EOF

curl -sfL https://get.k3s.io | sh -
```

### Option B — Using Flags

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --datastore-endpoint="postgres://k3suser:k3s@Secure2026@192.168.3.184:5432/k3s" \
  --tls-san=192.168.3.184 \
  --tls-san=k3s-server \
  --write-kubeconfig-mode=0644
```

### Verify Server

```bash
sudo systemctl status k3s
sudo k3s kubectl get nodes
```

---

## Phase 3 — Get Server Token

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
# Save this token — needed for agents
```

---

## Phase 4 — Install K3s Agents

Run on **k3s-agent-1** and **k3s-agent-2**:

### Option A — Using Config File (Recommended)

```bash
sudo mkdir -p /etc/rancher/k3s

cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
server: "https://192.168.3.184:6443"
token: "<PASTE_TOKEN_FROM_SERVER>"

node-label:
  - "environment=production"
  - "role=worker"
EOF

curl -sfL https://get.k3s.io | sh -s - agent
```

### Option B — Using Flags

```bash
export K3S_URL="https://192.168.3.184:6443"
export K3S_TOKEN="<PASTE_TOKEN_FROM_SERVER>"

curl -sfL https://get.k3s.io | sh -s - agent \
  --server $K3S_URL \
  --token $K3S_TOKEN
```

### Verify Agent

```bash
sudo systemctl status k3s-agent
```

---

## Phase 5 — Configure kubectl on Server

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

---

## Phase 6 — Verify Full Cluster

```bash
k get nodes
# Expected:
# NAME          STATUS   ROLES           AGE   VERSION
# k3s-server    Ready    control-plane   ...   v1.34.5+k3s1
# k3s-agent-1   Ready    <none>          ...   v1.34.5+k3s1
# k3s-agent-2   Ready    <none>          ...   v1.34.5+k3s1

k get pods -A
```

---

## Uninstall

```bash
# On server
sudo /usr/local/bin/k3s-uninstall.sh

# On agents
sudo /usr/local/bin/k3s-agent-uninstall.sh
```
