#!/bin/bash
# server

set -e

ip_server="192.168.56.110"
shared_file="/vagrant/node-token"
iface=$(ip -o -4 addr show | grep "192.168.56.110" | awk '{print $2}')

echo "=== Starting installation script ==="
apt update && apt -y upgrade
apt install -y curl

# download k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=$ip_server --flannel-iface=$iface" sh -

# token for workers
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
	echo "[LOG] wait for token"
	sleep 2
done
echo "[LOG] token received"

cat /var/lib/rancher/k3s/server/node-token > $shared_file

