# Lab 02 - Scaling

## Objective

Scale a deployment up and down on both K8s and K3s. Observe how the scheduler distributes pods across nodes when you increase replicas, and how it handles bringing replicas back down when you reduce them.

---

## Background

Scaling in Kubernetes means changing the number of pod replicas in a deployment. When you scale up, the scheduler places new pods on nodes that have available capacity. When you scale down, Kubernetes terminates pods to reach the desired count. The deployment always reconciles reality to match what you declared.

---

## Part 1 - Scaling on K8s

Run all commands from `cp1`.

### 1.1 - Create a Starting Deployment

```bash
kubectl create deployment scale-demo \
  --image=nginx \
  --replicas=2

kubectl get pods -o wide
```

Both pods will be on `cp1` since it is the only node.

### 1.2 - Scale Up

```bash
kubectl scale deployment scale-demo --replicas=6

kubectl get pods -o wide -w
```

Watch 4 new pods start. Press `Ctrl+C` when all 6 are `Running`.

![scaled to 6 on k8s](images/k8s-scaled-up.png)

### 1.3 - Scale Down

```bash
kubectl scale deployment scale-demo --replicas=1

kubectl get pods -o wide
```

Kubernetes terminates 5 pods and keeps 1. Note which pod survives — it is not necessarily the first one that was created.

### 1.4 - Cleanup

```bash
kubectl delete deployment scale-demo
```

---

## Part 2 - Scaling on K3s

Run all commands from `k3s-server`.

### 2.1 - Create the Deployment

```bash
kubectl create deployment scale-demo \
  --image=nginx \
  --replicas=2

kubectl get pods -o wide
```

With two agent nodes, each agent gets one pod.

### 2.2 - Scale Up and Observe Distribution

```bash
kubectl scale deployment scale-demo --replicas=6

kubectl get pods -o wide
```

Observe how the scheduler distributes pods across `k3s-agent-1` and `k3s-agent-2`. With 6 pods and 2 nodes, each agent should receive approximately 3 pods.

![pods distributed across agents](images/k3s-scaled-distributed.png)

### 2.3 - Simulate What Happens When a Node Has More Pods

Scale to a number that cannot divide evenly:

```bash
kubectl scale deployment scale-demo --replicas=5
kubectl get pods -o wide
```

The scheduler tries to balance the load but does not guarantee a perfect split. You will typically see 3 on one agent and 2 on the other.

### 2.4 - Scale to Zero

```bash
kubectl scale deployment scale-demo --replicas=0
kubectl get pods -o wide
# No pods listed
```

The deployment still exists but no pods are running. Scaling back up starts them again.

```bash
kubectl scale deployment scale-demo --replicas=2
kubectl get pods -o wide
```

### 2.5 - Cleanup

```bash
kubectl delete deployment scale-demo
```

---

## Part 3 - Rolling Update (Both Clusters)

A rolling update replaces pods one at a time instead of all at once. This keeps the application available during the update.

Run this on either cluster.

```bash
kubectl create deployment rolling-demo \
  --image=nginx:1.25 \
  --replicas=4

kubectl get pods -o wide
```

Update the image:

```bash
kubectl set image deployment/rolling-demo \
  nginx=nginx:1.26

kubectl rollout status deployment/rolling-demo
```

Watch the output — it shows pods terminating and new ones starting in sequence, not all at once.

![rolling update](images/rolling-update.png)

View the rollout history:

```bash
kubectl rollout history deployment/rolling-demo
```

Roll back to the previous version:

```bash
kubectl rollout undo deployment/rolling-demo
kubectl rollout status deployment/rolling-demo
```

Cleanup:

```bash
kubectl delete deployment rolling-demo
```

---

## What the Learner Must Understand

Scaling commands are identical on K8s and K3s. The observable difference is in pod placement:

| Observation | K8s (single node) | K3s (2 agents) |
|---|---|---|
| Scaling from 2 to 6 | All 6 pods on the same node | Pods spread across 2 agents |
| Scaling down | Pods terminate regardless of which node | Same behavior |
| Rolling update | Replaces pods one at a time | Same behavior |

The scheduler is what decides where pods go. It considers available resources on each node, existing pod counts, and affinity rules. With one node there is only one option. With multiple nodes the scheduler makes a distribution decision for every new pod.

The concept of a rolling update is important: real applications cannot afford downtime during updates. Kubernetes handles this automatically unless you tell it otherwise.
