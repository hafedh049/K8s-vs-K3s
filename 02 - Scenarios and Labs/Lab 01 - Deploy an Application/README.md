# Lab 01 - Deploy an Application

## Objective

Deploy an nginx web server on both K8s and K3s and expose it so it can be accessed from a browser. By the end of this lab you will understand how deployments, services, and pod scheduling work, and how the experience differs between the two distributions.

---

## Background

A Deployment tells Kubernetes how many copies of a container to run and what image to use. It also handles restarting pods that crash. A Service exposes those pods on a stable IP or port so other applications or users can reach them.

The commands you run are identical between K8s and K3s — both speak the same Kubernetes API. The difference is in what is already available without extra setup.

---

## Part 1 - Deploy on K8s

Run all commands from `cp1`.

### 1.1 - Create the Deployment

```bash
kubectl create deployment nginx-demo \
  --image=nginx \
  --replicas=3
```

Watch the pods start:

```bash
kubectl get pods -o wide -w
```

Press `Ctrl+C` when all 3 pods show `Running`. Notice the `NODE` column — on a single-node cluster all pods land on `cp1`. On a multi-node cluster they would spread across worker nodes.

![[images/Pasted image 20260311135056.png]]

### 1.2 - Expose the Deployment

```bash
kubectl expose deployment nginx-demo \
  --port=80 \
  --type=NodePort
```

Get the assigned port:

```bash
kubectl get svc nginx-demo
```

Look at the `PORT(S)` column. You will see something like `80:31500/TCP`. The second number, `31500`, is the NodePort — this is the port you use to reach the application from outside the cluster.

![[images/Pasted image 20260311135238.png]]

### 1.3 - Access the Application

```bash
NODE_PORT=$(kubectl get svc nginx-demo \
  -o jsonpath='{.spec.ports[0].nodePort}')

curl http://192.168.3.129:${NODE_PORT}
```

You should see the nginx welcome page HTML in your terminal. You can also open `http://192.168.3.129:<port>` in a browser.

![[images/Pasted image 20260311135320.png]]

### 1.4 - Inspect What Was Created

```bash
# See the deployment
kubectl describe deployment nginx-demo

# See the service
kubectl describe svc nginx-demo

# See which pods are behind the service
kubectl get endpoints nginx-demo
```

The endpoints list shows the internal IPs of the 3 pods that the service is load balancing across.

### 1.5 - Cleanup

```bash
kubectl delete deployment nginx-demo
kubectl delete svc nginx-demo
```

---

## Part 2 - Deploy on K3s

Run all commands from `k3s-server`.

### 2.1 - Create the Deployment

```bash
kubectl create deployment nginx-demo \
  --image=nginx \
  --replicas=3
```

Watch pods start:

```bash
kubectl get pods -o wide -w
```

Notice the `NODE` column this time. With one agent, all pods land on `k3s-agent-1`. The server node does not run workload pods by default — only agents do.

![[images/Pasted image 20260311135628.png]]

### 2.2 - Expose and Access

```bash
kubectl expose deployment nginx-demo \
  --port=80 \
  --type=NodePort

NODE_PORT=$(kubectl get svc nginx-demo \
  -o jsonpath='{.spec.ports[0].nodePort}')

# Access via any agent IP
curl http://192.168.3.185:${NODE_PORT}
```

![[images/Pasted image 20260311135714.png]]

### 2.3 - Cleanup

```bash
kubectl delete deployment nginx-demo
kubectl delete svc nginx-demo
```

---

## What the Learner Must Understand

The kubectl commands are completely identical between K8s and K3s. The same `create deployment` and `expose` commands work on both. What changes is the behavior:

| Behavior | K8s (cp1 + wk1 + wk2) | K3s (server + 1 agent) |
|---|---|---|
| Where pods land | Spread across wk1 and wk2 | All pods on k3s-agent-1 |
| Which IP to access | Any worker IP | Agent IP (192.168.3.185) |
| Server runs workloads | No — workers only | No — agent only |

The key insight is that Kubernetes and K3s are not different tools — K3s is a distribution of Kubernetes. Every kubectl command you learn works on both.
