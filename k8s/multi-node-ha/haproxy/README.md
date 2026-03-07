# ⚖️ HAProxy — API Server Load Balancing
> Adds health-check-based load balancing on top of the Keepalived VIP.

---

## Why HAProxy on top of Keepalived?

| Feature | Keepalived only | Keepalived + HAProxy |
|---|---|---|
| VIP failover | ✅ | ✅ |
| Health checks | ❌ Node-level only | ✅ API server level |
| If API crashes but node lives | VIP stays on broken node | HAProxy routes away |
| Load distribution | ❌ Single node takes all | ✅ Round-robin |

---

## Port Note

> HAProxy listens on **port 8443**, NOT 6443.
> Port 6443 is already used by the Kubernetes API server on each master.
> Running HAProxy on the same nodes as the API server means we cannot bind to 6443.

---

## Install

```bash
sudo apt install -y haproxy
```

---

## Configure

```bash
# Append K8s section to existing config
sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg

# Validate
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Start
sudo systemctl enable --now haproxy
sudo systemctl status haproxy

# Verify listening
ss -tlnp | grep 8443
```

---

## Verify Load Balancing

```bash
# Check HAProxy stats (if stats socket enabled)
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock | cut -d',' -f1,2,18

# Or just check all backends are UP
echo "show servers state" | sudo socat stdio /run/haproxy/admin.sock
```
