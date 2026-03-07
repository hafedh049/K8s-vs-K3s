# ☸️ Kubernetes — Multi-Node HA Cluster
### 3 Control Planes + 3 Workers · Keepalived VIP · HAProxy · Calico
> Load variables first: `source ../../variables.env`

---

## 🗺️ Architecture

```
                         VIP: 192.168.3.200
                              │
                    ┌─────────┴─────────┐
                    │    Keepalived     │
                    │    + HAProxy      │
                    └─────────┬─────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
   cp1 (192.168.3.129)  cp2 (192.168.3.179)  cp3 (192.168.3.181)
   MASTER priority=100  BACKUP priority=90   BACKUP priority=80
   apiserver+etcd       apiserver+etcd       apiserver+etcd
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │ Calico CNI
          ┌───────────────────┼───────────────────┐
          │                   │                   │
   wk1 (192.168.3.180)  wk2 (192.168.3.182)  wk3 (192.168.3.178)
       Worker               Worker               Worker
```

---

## 📋 Node Reference

| Hostname | IP | Role | Keepalived State | Priority |
|---|---|---|---|---|
| cp1 | 192.168.3.129 | Control Plane | MASTER | 100 |
| cp2 | 192.168.3.179 | Control Plane | BACKUP | 90 |
| cp3 | 192.168.3.181 | Control Plane | BACKUP | 80 |
| wk1 | 192.168.3.180 | Worker | — | — |
| wk2 | 192.168.3.182 | Worker | — | — |
| wk3 | 192.168.3.178 | Worker | — | — |
| VIP | 192.168.3.200 | Virtual IP | — | — |

---

## Phase 1 — All Nodes: Pre-Installation

> Complete `shared/pre-installation.md` on **ALL 6 nodes** before continuing.

---

## Phase 2 — All Nodes: Install kubeadm, kubelet, kubectl

Run on **cp1, cp2, cp3, wk1, wk2, wk3**:

```bash
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Verify
kubectl version --client
kubeadm version
```

---

## Phase 3 — All Control Planes: Install & Configure Keepalived

Run on **cp1, cp2, cp3**:

```bash
sudo apt install -y keepalived
```

### cp1 — MASTER Configuration

```bash
cat <<EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass k8s@2026
    }

    virtual_ipaddress {
        192.168.3.200/24
    }
}
EOF
```

### cp2 — BACKUP Configuration

```bash
cat <<EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 90
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass k8s@2026
    }

    virtual_ipaddress {
        192.168.3.200/24
    }
}
EOF
```

### cp3 — BACKUP Configuration

```bash
cat <<EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 80
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass k8s@2026
    }

    virtual_ipaddress {
        192.168.3.200/24
    }
}
EOF
```

### Start Keepalived — All Control Planes

```bash
sudo systemctl enable --now keepalived
sudo systemctl status keepalived
```

### Verify VIP is on cp1

```bash
# Run on cp1
ip a show ens33 | grep 192.168.3.200
# Should show: inet 192.168.3.200/24
```

---

## Phase 4 — All Control Planes: Install & Configure HAProxy

> HAProxy adds health-check-based load balancing on top of the Keepalived VIP.
> We use port 8443 because port 6443 is already used by the K8s API server.

```bash
sudo apt install -y haproxy
```

Add to the bottom of `/etc/haproxy/haproxy.cfg` on **all 3 masters**:

```bash
cat <<EOF | sudo tee -a /etc/haproxy/haproxy.cfg

#---------------------------------------------------------------------
# Kubernetes API Load Balancer
#---------------------------------------------------------------------
frontend kubernetes-api
    bind *:8443
    mode tcp
    option tcplog
    default_backend kubernetes-masters

backend kubernetes-masters
    mode tcp
    balance roundrobin
    option tcp-check
    server cp1 192.168.3.129:6443 check
    server cp2 192.168.3.179:6443 check
    server cp3 192.168.3.181:6443 check
EOF
```

```bash
# Validate config
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Start
sudo systemctl enable --now haproxy
sudo systemctl status haproxy

# Verify listening
ss -tlnp | grep 8443
```

---

## Phase 5 — cp1 Only: Initialize the Cluster

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.3.129 \
  --control-plane-endpoint="192.168.3.200:6443" \
  --upload-certs \
  --kubernetes-version=v1.29.0
```

> ⚠️ **Save the entire output!** You need two join commands from it.

---

## Phase 6 — cp1 Only: Configure kubectl

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Apply alias (see `shared/kubectl-config.md`):

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
k get nodes
```

---

## Phase 7 — cp1 Only: Install Calico CNI

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Wait for all Calico pods to be Running
kubectl get pods -n calico-system -w
```

---

## Phase 8 — cp2 & cp3: Join as Control Plane Nodes

If you lost the join command, regenerate on cp1:

```bash
# New certificate key
sudo kubeadm init phase upload-certs --upload-certs

# New join token + hash
kubeadm token create --print-join-command
```

Run on **cp2**, then **cp3** (one at a time):

```bash
sudo kubeadm join 192.168.3.200:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH> \
  --control-plane \
  --certificate-key <CERT_KEY>
```

Configure kubectl on cp2 and cp3 as well:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## Phase 9 — Workers: Join the Cluster

Run on **wk1, wk2, wk3**:

```bash
sudo kubeadm join 192.168.3.200:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

Regenerate worker join command if expired (24h TTL):

```bash
kubeadm token create --print-join-command
```

---

## Phase 10 — Verify Full Cluster

```bash
kubectl get nodes -o wide
# Expected output:
# NAME   STATUS   ROLES           AGE   VERSION
# cp1    Ready    control-plane   ...   v1.29.15
# cp2    Ready    control-plane   ...   v1.29.15
# cp3    Ready    control-plane   ...   v1.29.15
# wk1    Ready    <none>          ...   v1.29.15
# wk2    Ready    <none>          ...   v1.29.15
# wk3    Ready    <none>          ...   v1.29.15

# Verify etcd has 3 members
kubectl exec -n kube-system etcd-cp1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

---

## Phase 11 — Optional: Resource Limits

```bash
kubectl apply -f manifests/limits.yaml
kubectl get limitrange -n default
```

---

## Phase 12 — Optional: Monitoring Stack

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add repo
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy
kubectl create namespace monitoring
helm install prometheus \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin@k8s2026

# Expose Grafana via NodePort
kubectl patch svc prometheus-grafana \
  -n monitoring \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"nodePort":32000}]}}'

# Access: http://192.168.3.129:32000
# User: admin / Pass: admin@k8s2026
```

---

## Phase 13 — Optional: Persistent Storage (Longhorn)

Install prerequisites on **ALL nodes**:

```bash
sudo apt install -y open-iscsi nfs-common
sudo systemctl enable --now iscsid
```

Deploy from **cp1 only**:

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml

kubectl get pods -n longhorn-system -w

# Set as default storage class
kubectl patch storageclass longhorn \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## HA Failure Scenarios

| Failure | What happens | Recovery |
|---|---|---|
| cp1 dies | VIP → cp2, cluster alive | Power on cp1, kubelet auto-rejoins |
| cp2 dies | cp1 holds VIP, cluster alive | Power on cp2 |
| cp1+cp2 die | VIP → cp3, etcd freezes (1/3) | Restore at least one master |
| Worker dies | Pods reschedule on remaining workers | `kubectl uncordon` after recovery |
| API server killed | kubelet restarts it in ~10s | Automatic |

---

## Uninstall

```bash
# On each node
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/ /var/lib/etcd/ $HOME/.kube
sudo iptables -F && sudo iptables -t nat -F
sudo apt purge -y kubeadm kubectl kubelet
sudo apt autoremove -y
```
