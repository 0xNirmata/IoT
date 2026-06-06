#!/bin/bash

set -euo pipefail

echo "=== Starting installation script (P2 Server) ==="

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq curl

ip_server="192.168.56.110"
iface=$(ip -o -4 addr show | grep "$ip_server" | awk '{print $2}')

# Garde-fou : l'interface doit avoir ete trouvee
if [ -z "$iface" ]; then
  echo "ERROR: no interface found for $ip_server"
  ip -o -4 addr show
  exit 1
fi
echo "[LOG] Interface detected: $iface"

echo "Installing k3s server..."
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--node-ip=$ip_server --flannel-iface=$iface --write-kubeconfig-mode 644" \
  sh -s - server

# Attente que l'API Kubernetes soit prete (le node passe Ready)
echo "[LOG] Waiting for Kubernetes API to be ready..."
until kubectl get nodes >/dev/null 2>&1; do
  sleep 3
done
echo "[LOG] Kubernetes API is ready"

# Application des manifests (apps + ingress)
# p2/confs sur l'hote est monte dans /vagrant/confs dans la VM
echo "[LOG] Applying manifests from /vagrant/confs/ ..."
kubectl apply -f /vagrant/confs/

echo "=== P2 setup complete ==="
kubectl get all
kubectl get ingress

