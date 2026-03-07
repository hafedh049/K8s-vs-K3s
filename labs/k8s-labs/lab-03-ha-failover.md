# 🧪 K8s Lab 03 — HA Failover Scenarios
**Cluster:** K8s Multi-Node HA | **Node:** Run from cp1/cp2

---

## Objective
Test all 4 HA failure scenarios and verify cluster resilience.

---

## Pre-Lab Setup — Deploy Test App

```bash
kubectl create deployment ha-test \
  --image=nginx \
  --replicas=6

kubectl get pods -o wide
# Verify pods spread across wk1, wk2, wk3
```

---

## Scenario 1 — Master Node Failure (VIP Failover)

**On cp2 — open a watch:**
```bash
watch -n1 kubectl get nodes
```

**Shut down cp1:**
```bash
# On cp1
sudo shutdown -h now
```

**Verify on cp2:**
```bash
# VIP should move to cp2
ip a show ens33 | grep 192.168.3.200

# Cluster still alive
kubectl get nodes
# cp1: NotReady, cp2: Ready, cp3: Ready

# etcd quorum maintained (2/3)
kubectl exec -n kube-system etcd-cp2 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

**Expected:** VIP on cp2, cluster operational.

**Recovery:** Power on cp1. kubelet auto-rejoins within 60s.

---

## Scenario 2 — Worker Node Failure (Pod Rescheduling)

**Watch pods:**
```bash
kubectl get pods -o wide -w
```

**Shut down wk1:**
```bash
# On wk1
sudo shutdown -h now
```

**Observe:** Pods from wk1 → Terminating → rescheduled on wk2/wk3.

**Speed up eviction:**
```bash
kubectl drain wk1 --ignore-daemonsets --delete-emptydir-data --force
```

**Recovery:**
```bash
# Power on wk1 — auto-rejoins (no uncordon needed if just shut down)
# If drained: kubectl uncordon wk1
```

---

## Scenario 3 — API Server Process Kill

**Kill the API server on cp1:**
```bash
sudo kill -9 $(pgrep -f kube-apiserver)
```

**Watch it restart:**
```bash
sudo crictl ps | grep apiserver
# Should restart within 10-20 seconds
```

**From cp2:**
```bash
# Cluster should still respond (cp2/cp3 API servers handle requests)
kubectl get nodes
```

**Check restart count:**
```bash
kubectl get pods -n kube-system | grep apiserver
# RESTARTS column should increment
```

---

## Scenario 4 — Double Master Failure

**On cp3 — watch VIP:**
```bash
watch -n1 "ip a show ens33 | grep 192.168.3.200"
```

**Shut down cp1:**
```bash
sudo shutdown -h now  # on cp1
```

**Shut down cp2:**
```bash
sudo shutdown -h now  # on cp2
```

**Expected:**
- VIP moves to cp3
- etcd loses quorum (1/3) — cluster freezes
- Existing pods on workers keep running
- No new deployments possible

**Recovery:**
```bash
# Power on cp1 and cp2
sudo systemctl start kubelet  # on each
kubectl get nodes  # all should return to Ready
```

---

## Results Summary Table

| Scenario | Cluster alive? | VIP moves? | Pods affected? | Recovery |
|---|---|---|---|---|
| 1 master down | ✅ Yes | ✅ Yes | ❌ No | Automatic |
| 2 masters down | ❌ Frozen | ✅ Yes | ❌ Running | Restore masters |
| Worker down | ✅ Yes | N/A | ✅ Rescheduled | Automatic |
| API server killed | ✅ Yes | N/A | ❌ No | Automatic (~10s) |

---

## Cleanup

```bash
kubectl delete deployment ha-test
```
