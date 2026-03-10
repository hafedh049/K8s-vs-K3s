# K3s - Single Node Installation

K3s installs in a single command. Everything K8s requires you to install separately — the container runtime, CNI, ingress controller, DNS — comes bundled in K3s as a single binary under 100 MB.

Node used: `k3s-server` at `192.168.3.184`

Before starting, complete `00 - Environment Setup` on this node.

---

## What K3s Includes Out of the Box

| Component | K8s (what you did manually) | K3s (built-in) |
|---|---|---|
| Container runtime | Installed containerd separately | Bundled |
| CNI networking | Applied Calico manifest | Flannel bundled |
| Ingress controller | Must install NGINX or similar | Traefik bundled |
| DNS | CoreDNS applied by kubeadm | Bundled |
| Storage provisioner | Must install Longhorn or similar | Local Path bundled |
| Load balancer | Must install MetalLB or similar | ServiceLB bundled |

---

## Step 1 - Install K3s

```bash
curl -sfL https://get.k3s.io | sh -
```

That single command installs K3s, registers it as a systemd service, and starts it.

![k3s install complete](images/k3s-install-complete.png)

---

## Step 2 - Verify the Service

```bash
sudo systemctl status k3s
```

![k3s service running](images/k3s-service-running.png)

---

## Step 3 - Configure kubectl

```bash
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Add the alias and tab completion:

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

---

## Step 4 - Verify the Node

```bash
k get nodes
k get pods -A
```

The node is `Ready` immediately. All pods are already running.

![k3s node ready](images/k3s-node-ready.png)

---

## Step 5 - Fix the crictl Endpoint Warning

```bash
sudo crictl config \
  --set runtime-endpoint=unix:///run/containerd/containerd.sock \
  --set image-endpoint=unix:///run/containerd/containerd.sock
```

---

## Comparing the Two Installations

At this point you have installed both K8s and K3s. Consider what was different:

| Step | K8s | K3s |
|---|---|---|
| Commands to get a working cluster | 6 steps, multiple commands | 1 command |
| Manual CNI installation | Yes (Calico) | No (Flannel built-in) |
| Time to first working node | 10-20 minutes | Under 2 minutes |
| Packages installed | kubeadm + kubelet + kubectl + containerd config | Single binary |
| Node status after install | NotReady until CNI applied | Ready immediately |

This does not mean K3s is always better. K8s gives you full control over every component. K3s trades that control for simplicity. The right choice depends on what you are building.
