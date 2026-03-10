# K8s - Single Control Plane Installation

This guide installs a single-node Kubernetes cluster where the control plane and workloads run on the same machine. This is used for learning and local testing.

Node used: `cp1` at `192.168.3.129`

Before starting, complete `00 - Environment Setup` on this node.

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

Confirm installation:

```bash
kubectl version --client
kubeadm version
```

![kubeadm and kubectl installed](images/kubeadm-installed.png)

---

## Step 2 - Initialize the Cluster

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.3.129 \
  --kubernetes-version=v1.29.0
```

This process takes 1-2 minutes. At the end you will see a `kubeadm join` command. Save it — you need it to add worker nodes later.

![kubeadm init success](images/kubeadm-init-success.png)

---

## Step 3 - Configure kubectl

Copy the admin config so kubectl can authenticate:

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

The node will show `NotReady` until the CNI is installed in the next step.

---

## Step 4 - Install Calico CNI

Without a CNI plugin, pods cannot communicate with each other and the node stays in NotReady state.

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

Wait for Calico pods to start:

```bash
kubectl get pods -n calico-system -w
```

Press `Ctrl+C` when all pods show `Running`. Then check the node:

```bash
k get nodes
```

The node should now show `Ready`.

![node ready after calico](images/node-ready-calico.png)

---

## Step 5 - Allow Scheduling on the Control Plane

By default, Kubernetes does not schedule workload pods on control plane nodes. For a single-node setup, remove this restriction:

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

---

## Step 6 - Verify the Cluster

```bash
k get nodes -o wide
k get pods -A
```

All system pods should be `Running`. The node should be `Ready`.

![full cluster healthy](images/cluster-healthy.png)

---

## What is Running on Your Cluster

| Component | Namespace | Role |
|---|---|---|
| kube-apiserver | kube-system | Accepts all kubectl commands |
| etcd | kube-system | Stores all cluster state |
| kube-scheduler | kube-system | Decides which node runs each pod |
| kube-controller-manager | kube-system | Ensures desired state is maintained |
| kube-proxy | kube-system | Handles networking rules on the node |
| coredns | kube-system | DNS resolution inside the cluster |
| calico-node | calico-system | Pod networking |
