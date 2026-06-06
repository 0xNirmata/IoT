#!/bin/bash

set -euo pipefail

echo "=== Starting installation script (Server) ==="

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

# Attente du token
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  echo "[LOG] Waiting for token..."
  sleep 3
done

cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
echo "[LOG] Token successfully written to /vagrant/node-token"
echo "=== k3s Server is ready ==="
