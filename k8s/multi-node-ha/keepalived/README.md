# 🔁 Keepalived — VIP Failover
> Provides a floating Virtual IP `192.168.3.200` across all 3 control plane nodes.

---

## How it Works

```
cp1 (priority=100) ──┐
cp2 (priority=90)  ──┼── VIP: 192.168.3.200
cp3 (priority=80)  ──┘

Highest alive priority = holds the VIP
```

---

## Install

```bash
# On ALL control plane nodes
sudo apt install -y keepalived
```

---

## Configure

Copy the appropriate config to `/etc/keepalived/keepalived.conf` on each node:

```bash
# On cp1
sudo cp cp1-keepalived.conf /etc/keepalived/keepalived.conf

# On cp2
sudo cp cp2-keepalived.conf /etc/keepalived/keepalived.conf

# On cp3
sudo cp cp3-keepalived.conf /etc/keepalived/keepalived.conf
```

---

## Start

```bash
sudo systemctl enable --now keepalived
sudo systemctl status keepalived
```

---

## Verify VIP

```bash
# On cp1 — should show VIP attached
ip a show ens33 | grep 192.168.3.200

# Shutdown cp1 — VIP should move to cp2
# On cp2:
ip a show ens33 | grep 192.168.3.200
```

---

## Priority Reference

| Node | State | Priority | Gets VIP when |
|---|---|---|---|
| cp1 | MASTER | 100 | Always (when alive) |
| cp2 | BACKUP | 90 | cp1 is down |
| cp3 | BACKUP | 80 | cp1 AND cp2 are down |
