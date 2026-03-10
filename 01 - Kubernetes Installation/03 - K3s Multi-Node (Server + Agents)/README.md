# K3s - Multi-Node Installation (Server + Agents)

This guide sets up a K3s cluster with one server node (control plane) and two agent nodes (workers). The server runs the K3s API server and stores cluster state. The agents run workloads.

| Role | Hostname | IP |
|---|---|---|
| Server | k3s-server | 192.168.3.184 |
| Agent 1 | k3s-agent-1 | 192.168.3.185 |
| Agent 2 | k3s-agent-2 | 192.168.3.186 |

Before starting, complete `00 - Environment Setup` on all three nodes.

---

## Architecture

```
k3s-server (192.168.3.184)
    API Server + Scheduler + Controller + SQLite
          |
    ------+------
    |           |
k3s-agent-1   k3s-agent-2
(workloads)   (workloads)
```

In K3s, all control plane components run as a single binary. There is no separate etcd process — by default K3s uses SQLite as its datastore, embedded inside the binary. This is sufficient for a single server and a handful of agents.

---

## Why SQLite Here, Not PostgreSQL

For this lab we use the default SQLite datastore. SQLite is a local file — it works fine when you have one server node. PostgreSQL is only needed when you want multiple K3s server nodes sharing the same cluster state, which is a more advanced HA scenario beyond this lab.

---

## Part 1 - Install the K3s Server

Run on `k3s-server` only.

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --tls-san=192.168.3.184 \
  --write-kubeconfig-mode=0644
```

The `--tls-san` flag adds your server IP to the TLS certificate so kubectl can connect by IP without a certificate error. The `--write-kubeconfig-mode=0644` flag makes the kubeconfig readable without sudo.

Verify the server is running:

```bash
sudo systemctl status k3s
k get nodes
```

![k3s server running](images/k3s-server-running.png)

---

## Part 2 - Get the Node Token

Agent nodes authenticate to the server using a token. Retrieve it from the server:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Copy the full token output. You will need it in the next step.

![server token](images/server-token.png)

---

## Part 3 - Configure kubectl on the Server

```bash
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

---

## Part 4 - Install the K3s Agents

Run on `k3s-agent-1` and `k3s-agent-2`. Replace `<TOKEN>` with the token from Part 2.

```bash
export K3S_URL="https://192.168.3.184:6443"
export K3S_TOKEN="<TOKEN>"

curl -sfL https://get.k3s.io | sh -s - agent \
  --server $K3S_URL \
  --token $K3S_TOKEN
```

Check the agent service:

```bash
sudo systemctl status k3s-agent
```

![k3s agent running](images/k3s-agent-running.png)

---

## Part 5 - Verify the Cluster from the Server

Run on `k3s-server`:

```bash
k get nodes
```

Expected output:

```
NAME          STATUS   ROLES                  AGE   VERSION
k3s-server    Ready    control-plane,master   ...   v1.34.x+k3s1
k3s-agent-1   Ready    <none>                 ...   v1.34.x+k3s1
k3s-agent-2   Ready    <none>                 ...   v1.34.x+k3s1
```

![all nodes ready](images/all-nodes-ready.png)

---

## Important: kubectl Belongs on the Server Only

Agent nodes do not run an API server. Running `kubectl get nodes` on an agent node will fail with a connection refused error — this is expected behavior, not a misconfiguration. Always run kubectl commands from the server node.

---

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Running `curl get.k3s.io | sh -` on agents without `agent` flag | Installs a second server instead of an agent | Uninstall with `/usr/local/bin/k3s-uninstall.sh` and reinstall correctly |
| Wrong token | Agent cannot join | Get fresh token from `sudo cat /var/lib/rancher/k3s/server/node-token` |
| Port 6444 already in use on agent | Agent service crashes | Run `sudo fuser -k 6444/tcp` then restart the service |

---

## Uninstall

```bash
# On server
sudo /usr/local/bin/k3s-uninstall.sh

# On each agent
sudo /usr/local/bin/k3s-agent-uninstall.sh
```
