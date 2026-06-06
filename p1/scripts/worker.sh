#!/bin/bash
# worker

set -e

ip_worker="192.168.56.111"

while [ ! -f /vagrant/node-token ]; do
	echo "[LOG] wait for token"
	sleep 2
done
echo "[LOG] token received"

apt update && apt -y upgrade
apt install -y curl

token=$(cat "/vagrant/node-token")
server_url="https://192.168.56.110:6443"
iface=$(ip -o -4 addr show | grep "192.168.56.111" | awk '{print $2}')

echo "=== Starting installation script ==="

# download k3s
curl -sfL https://get.k3s.io | K3S_URL=$server_url K3S_TOKEN=$token INSTALL_K3S_EXEC="--node-ip=$ip_worker --flannel-iface=$iface" sh -
