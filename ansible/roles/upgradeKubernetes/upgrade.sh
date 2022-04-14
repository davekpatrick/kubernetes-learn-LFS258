
#Check the health of the database using the loopback IP and port2379
kubectl -n kube-system exec -it etcd-k8s00 -- sh -c "ETCDCTL_API=3 \
ETCDCTL_CACERT= ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
etcdctl endpoint health"

# Determine how many databases are part of the cluster
kubectl -n kube-system exec -it etcd-k8s00 -- sh -c "ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/peer.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/peer.key \
etcdctl --endpoints=https://127.0.0.1:2379 member list"

kubectl -n kube-system exec -it etcd-k8s00 -- sh -c "ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/peer.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/peer.key \
etcdctl --endpoints=https://127.0.0.1:2379 member list -w table"

# back etcd .... Use the snapshot argument to save into the /var/lib/etcd directory
kubectl -n kube-system exec -it etcd-k8s00 -- sh -c "ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
etcdctl --endpoints=https://127.0.0.1:2379 snapshot save /var/lib/etcd/snapshot.db"

# save backup details
mkdir $HOME/backup
sudo cp /var/lib/etcd/snapshot.db $HOME/backup/snapshot.db-$(date +%m-%d-%y)
sudo cp /root/kubeadm-config.yaml $HOME/backup/
sudo cp -r /etc/kubernetes/pki/etcd $HOME/backup/

#
sudo apt update
sudo apt-cache madison kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.23.1-00
sudo apt-mark hold kubeadm
#
kubectl drain k8s00 --ignore-daemonsets
sudo kubeadm version
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.23.1
kubectl get node
#
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.23.1-00 kubectl=1.23.1-00
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl get node
kubectl uncordon k8s00
kubectl get node
# -------------------------------------------
sudo apt update
sudo apt-cache madison kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.23.1-00
sudo apt-mark hold kubeadm
#
kubectl drain k8s01 --ignore-daemonsets 
#
sudo kubeadm version
sudo kubeadm upgrade node
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.23.1-00 kubectl=1.23.1-00
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
#
kubectl get node
kubectl uncordon k8s01
kubectl get node