# Lab 03 - K8s vs K3s Key Differences

## Objective

This lab is not about running commands — it is about understanding when to use each tool. You will run a few targeted observations to make the differences concrete, then work through a decision exercise.

---

## Background

K3s is a certified Kubernetes distribution. It passes the same conformance tests as full K8s. This means every kubectl command you have used in the previous two labs works identically on both. The differences are in what comes bundled, how much resource it consumes, and what operational complexity it introduces.

---

## Part 1 - Resource Footprint Comparison

### 1.1 - Check Memory Usage on K8s

Run on `cp1`:

```bash
free -h
kubectl top nodes
```

Note the memory consumed by the control plane components. On a fresh K8s cluster you will typically see 800 MB to 1.5 GB in use just from the control plane.

![k8s memory usage](images/k8s-memory-usage.png)

### 1.2 - Check Memory Usage on K3s

Run on `k3s-server`:

```bash
free -h
```

K3s typically uses 250 to 400 MB for the entire control plane. This is because all components — API server, scheduler, controller manager — run as a single process rather than separate processes.

![k3s memory usage](images/k3s-memory-usage.png)

### 1.3 - Check Running Processes

On K8s (`cp1`):

```bash
sudo crictl ps --name "kube-" | awk '{print $NF}'
```

You will see separate containers for: `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `etcd`.

On K3s (`k3s-server`):

```bash
ps aux | grep k3s | grep -v grep
```

You will see a single `k3s server` process. Everything runs inside it.

---

## Part 2 - What is Installed Without Extra Work

### 2.1 - Check Ingress on K8s

Run on `cp1`:

```bash
kubectl get pods -A | grep ingress
```

Nothing. K8s does not ship with an ingress controller. To expose applications via HTTP hostnames, you must install one separately (NGINX, Traefik, HAProxy, etc.).

### 2.2 - Check Ingress on K3s

Run on `k3s-server`:

```bash
kubectl get pods -A | grep traefik
```

Traefik is already running. K3s installs it automatically. You can create an Ingress resource immediately without any extra setup.

![traefik running on k3s](images/k3s-traefik-running.png)

### 2.3 - Check Storage Classes

On both clusters:

```bash
kubectl get storageclass
```

K8s returns nothing unless you have installed Longhorn or another storage plugin. K3s returns `local-path` as a default storage class, which is available immediately for PersistentVolumeClaims.

---

## Part 3 - Node Recovery Behavior

This is one of the most important practical differences.

### 3.1 - Simulate Agent Failure on K3s

Run on `k3s-server`. First deploy a test application:

```bash
kubectl create deployment recovery-test \
  --image=nginx \
  --replicas=4

kubectl get pods -o wide
# Note which pods are on k3s-agent-1
```

Now go to `k3s-agent-1` and shut it down:

```bash
sudo shutdown -h now
```

Watch from `k3s-server`:

```bash
kubectl get pods -o wide -w
```

Within a few minutes the pods that were on `k3s-agent-1` will move to `Terminating` and new pods will start on `k3s-agent-2`. The deployment maintains its replica count automatically.

![pod rescheduling after agent failure](images/k3s-pod-rescheduling.png)

Power `k3s-agent-1` back on. Once it boots, check from the server:

```bash
kubectl get nodes -w
```

The agent rejoins automatically. No manual intervention is needed.

Cleanup:

```bash
kubectl delete deployment recovery-test
```

---

## Part 4 - Decision Guide

Use this table when choosing between K8s and K3s for a given project.

| Situation | Recommended Choice | Reason |
|---|---|---|
| Production cluster with 50+ nodes | K8s | etcd scales better than SQLite at high node counts |
| Edge device with 1 GB RAM | K3s | K8s control plane alone exceeds available memory |
| Team with no dedicated infrastructure engineers | K3s | Less to install, less to maintain, fewer failure points |
| Cluster that needs Windows worker nodes | K8s | K3s does not support Windows nodes |
| CI/CD pipeline that needs a cluster per branch | K3s | Spins up in under 30 seconds |
| Compliance environment needing detailed audit logs | K8s | More mature tooling for audit and policy enforcement |
| Raspberry Pi home server | K3s | Designed for ARM, runs on 512 MB RAM |
| Developer laptop | K3s | No VM required, minimal footprint |
| Multi-cloud deployment | K8s | Full cloud-controller-manager support |
| Learning Kubernetes for the first time | K3s | Faster feedback loop, less configuration to debug |

---

## Summary

The fundamental distinction is this:

K8s gives you a foundation. You assemble the pieces you need: the CNI, the ingress controller, the storage provider, the load balancer. This is more work, but it means every component is one you chose, understand, and can replace.

K3s gives you a working system. The pieces are already assembled and configured to work together. This is faster, but you are working within the choices Rancher made for you. When those choices match your needs, K3s is the better option. When they do not, K8s gives you the control to make your own.

Both are production-ready. The question is what kind of production environment you are running.
