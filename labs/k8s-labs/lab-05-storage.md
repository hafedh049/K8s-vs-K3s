# 🧪 K8s Lab 05 — Persistent Storage with Longhorn
**Cluster:** K8s Multi-Node HA | **Node:** Run from cp1

---

## Objective
Deploy Longhorn, create PersistentVolumeClaims, and verify data persists across pod restarts.

---

## Pre-Requisite — Install Longhorn

Run on ALL nodes:
```bash
sudo apt install -y open-iscsi nfs-common
sudo systemctl enable --now iscsid
```

Run on cp1:
```bash
kubectl apply -f \
  https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml

kubectl get pods -n longhorn-system -w
# Wait until all Running

kubectl patch storageclass longhorn \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## Step 1 — Create a PVC

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
EOF

kubectl get pvc demo-pvc
# STATUS should be Bound
```

---

## Step 2 — Deploy App with PVC

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storage-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storage-demo
  template:
    metadata:
      labels:
        app: storage-demo
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - mountPath: /data
          name: demo-volume
      volumes:
      - name: demo-volume
        persistentVolumeClaim:
          claimName: demo-pvc
EOF
```

---

## Step 3 — Write Data to Volume

```bash
POD=$(kubectl get pods -l app=storage-demo -o name | head -1)

# Write data
kubectl exec $POD -- sh -c "echo 'Hello from Longhorn!' > /data/test.txt"

# Verify
kubectl exec $POD -- cat /data/test.txt
```

---

## Step 4 — Verify Data Persists After Pod Restart

```bash
# Delete the pod (deployment will recreate it)
kubectl delete $POD

# Wait for new pod
kubectl get pods -l app=storage-demo -w

# Read data from new pod
NEW_POD=$(kubectl get pods -l app=storage-demo -o name | head -1)
kubectl exec $NEW_POD -- cat /data/test.txt
# Should still show: Hello from Longhorn!
```

---

## Cleanup

```bash
kubectl delete deployment storage-demo
kubectl delete pvc demo-pvc
```

---

## ✅ What You Learned
- Create PersistentVolumeClaims
- Mount volumes in pods
- Verify data persistence across pod restarts
- Longhorn distributed storage
