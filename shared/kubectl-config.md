# ⚙️ kubectl Configuration — Alias, Completion & Kubeconfig
> Apply on any node where you run `kubectl`

---

## Alias & Shell Completion

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

Now `k` works exactly like `kubectl` with full tab completion:

```bash
k get nodes
k get pods -A
k describe pod <name>
```

---

## Kubeconfig — K8s

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## Kubeconfig — K3s

```bash
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## Managing Multiple Clusters

```bash
# View all contexts
kubectl config get-contexts

# Switch between K8s and K3s
kubectl config use-context kubernetes-admin@kubernetes   # K8s
kubectl config use-context default                        # K3s

# Set default namespace
kubectl config set-context --current --namespace=production
```

---

## Access Remote Cluster from Your Laptop

```bash
# Copy kubeconfig from K8s master
scp root@192.168.3.129:/etc/kubernetes/admin.conf ~/.kube/k8s-config

# Copy kubeconfig from K3s server
scp root@192.168.3.184:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config

# Fix K3s server IP
sed -i 's/127.0.0.1/192.168.3.184/' ~/.kube/k3s-config

# Use specific config
export KUBECONFIG=~/.kube/k8s-config
kubectl get nodes

export KUBECONFIG=~/.kube/k3s-config
kubectl get nodes
```
