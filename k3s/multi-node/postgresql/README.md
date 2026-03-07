# 🐘 PostgreSQL — K3s External Datastore
> Replaces SQLite to enable true multi-server K3s HA.

---

## Why PostgreSQL Over SQLite?

SQLite is a local file. It cannot be shared between multiple K3s server nodes.
PostgreSQL is a proper database server that all K3s servers connect to simultaneously.

| | SQLite | PostgreSQL |
|---|---|---|
| Location | Local file on server | Dedicated host |
| Multi-server | ❌ Impossible | ✅ Yes |
| HA | ❌ Single point of failure | ✅ With replication |
| Backup | Copy file | pg_dump |
| Production ready | ❌ | ✅ |

---

## Install

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
```

---

## Initialize

```bash
# Run the init script
sudo -u postgres psql -f init.sql

# Or manually:
sudo -u postgres psql <<EOF
CREATE USER k3suser WITH PASSWORD 'k3s@Secure2026';
CREATE DATABASE k3s OWNER k3suser;
GRANT ALL PRIVILEGES ON DATABASE k3s TO k3suser;
EOF
```

---

## Allow Remote Connections

```bash
# postgresql.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" \
  /etc/postgresql/*/main/postgresql.conf

# pg_hba.conf — add K3s network
echo "host k3s k3suser 192.168.3.0/24 md5" | \
  sudo tee -a /etc/postgresql/*/main/pg_hba.conf

sudo systemctl restart postgresql
```

---

## Verify

```bash
psql -h 192.168.3.184 -U k3suser -d k3s -c "\l"
```

---

## Backup Cluster State

```bash
pg_dump -h 192.168.3.184 -U k3suser k3s > k3s-backup-$(date +%Y%m%d).sql
```

---

## Restore

```bash
psql -h 192.168.3.184 -U k3suser -d k3s < k3s-backup-20260307.sql
```
