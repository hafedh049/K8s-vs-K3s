# K8s - Single Control Plane + 2 Worker Nodes

This guide installs a Kubernetes cluster with one control plane and two worker nodes. The control plane manages the cluster. The workers run your application workloads.

| Role | Hostname | IP Address |
|---|---|---|
| Control Plane | cp1 | 192.168.3.129 |
| Worker 1 | wk1 | 192.168.3.180 |
| Worker 2 | wk2 | 192.168.3.182 |

Before starting, complete `00 - Environment Setup` on all three nodes.

---

## What You Will Install

| Component | Package | Purpose |
|---|---|---|
| kubeadm | pkgs.k8s.io | Bootstraps the cluster |
| kubelet | pkgs.k8s.io | Runs on every node, manages pods |
| kubectl | pkgs.k8s.io | CLI to communicate with the cluster |
| Calico | manifest | Pod-to-pod networking and NetworkPolicy |

---

## Step 1 - Install kubeadm, kubelet, kubectl

Run on **cp1, wk1, and wk2**.

Add the Kubernetes apt repository:

```bash
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install the packages:

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Pin versions to prevent accidental upgrades
sudo apt-mark hold kubelet kubeadm kubectl
```

Confirm on each node:

```bash
kubectl version --client
kubeadm version
```

![[images/Pasted image 20260311125859.png]]

---

## Step 2 - Initialize the Cluster

Run on **cp1 only**.

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.3.129 \
  --kubernetes-version=v1.29.0
```

This takes 1-2 minutes. When it finishes, you will see output that includes a `kubeadm join` command at the bottom. It looks like this:

```
kubeadm join 192.168.3.129:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

Copy and save the entire join command. You will need it in Step 5. The token expires after 24 hours. If it expires before you use it, regenerate it with:

```bash
kubeadm token create --print-join-command
```

![[images/Pasted image 20260311131423.png]]

---

## Step 3 - Configure kubectl

Run on **cp1 only**.

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Add the alias and tab completion:

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

Test the connection:

```bash
k get nodes
```

cp1 will show `NotReady` until the CNI is installed in the next step.

---

## Step 4 - Install Calico CNI

Run on **cp1 only**.

Without a CNI plugin, pods cannot communicate with each other and nodes stay in `NotReady` state.

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

Wait for Calico pods to be running:

```bash
kubectl get pods -n calico-system -w
```

Press `Ctrl+C` when all pods show `Running`. Then check the node:

```bash
k get nodes
```

cp1 should now show `Ready`.

![[images/Pasted image 20260311131546.png]]

---

## Step 5 - Join the Worker Nodes

Run on **wk1 and wk2**. Use the join command you saved from Step 2.

```bash
sudo kubeadm join 192.168.3.129:6443 \
  --token <your-token> \
  --discovery-token-ca-cert-hash sha256:<your-hash>
```

Run this on wk1 first, wait for it to complete, then run it on wk2.

---

## Step 6 - Verify the Full Cluster

Run on **cp1**.

```bash
k get nodes -o wide
```

Expected output:

```
NAME   STATUS   ROLES           AGE   VERSION     INTERNAL-IP
cp1    Ready    control-plane   ...   v1.29.15    192.168.3.129
wk1    Ready    <none>          ...   v1.29.15    192.168.3.180
wk2    Ready    <none>          ...   v1.29.15    192.168.3.182
```

All three nodes should show `Ready`. If a worker shows `NotReady`, wait 30 seconds and run the command again — kubelet on the new node needs a moment to register with the control plane.

Check all system pods are healthy:

```bash
k get pods -A
```

![[images/Pasted image 20260311132002.png]]

---

## Step 7 - Verify Pod Scheduling on Workers

Deploy a quick test to confirm pods land on the worker nodes and not on the control plane:

```bash
kubectl create deployment test-scheduling \
  --image=nginx \
  --replicas=4

kubectl get pods -o wide
```

You should see pods distributed across wk1 and wk2. The control plane (cp1) does not receive workload pods by default. This is intentional — the control plane is reserved for cluster management components.

![[images/Pasted image 20260311133130.png]]

Clean up:

```bash
kubectl delete deployment test-scheduling
```

---

## What is Running on Your Cluster

| Component | Node | Namespace | Role |
|---|---|---|---|
| kube-apiserver | cp1 | kube-system | Accepts all kubectl commands |
| etcd | cp1 | kube-system | Stores all cluster state |
| kube-scheduler | cp1 | kube-system | Decides which node runs each pod |
| kube-controller-manager | cp1 | kube-system | Ensures desired state is maintained |
| kube-proxy | all nodes | kube-system | Handles networking rules per node |
| coredns | cp1 | kube-system | DNS resolution inside the cluster |
| calico-node | all nodes | calico-system | Pod networking per node |

---

## Common Issues

| Problem | Likely Cause | Fix |
|---|---|---|
| Worker shows NotReady | kubelet not started | `sudo systemctl restart kubelet` on the worker |
| Join command rejected | Token expired (24h TTL) | Run `kubeadm token create --print-join-command` on cp1 |
| Pods stuck on cp1 | Control plane taint removed | Do not run the untaint command — workers should receive pods |
| Worker cannot reach cp1 | Firewall or /etc/hosts | Verify `ping cp1` works from the worker and port 6443 is open |
