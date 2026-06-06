#!/bin/bash

set -euo pipefail

echo "=== Starting installation script (Worker) ==="

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq curl

ip_worker="192.168.56.111"
shared_file="/vagrant/node-token"

# Attente du token avec timeout (3 minutes)
timeout=180
while [ ! -f "$shared_file" ] && [ "$timeout" -gt 0 ]; do
  echo "[LOG] Waiting for token... (${timeout}s remaining)"
  sleep 3
  timeout=$((timeout-3))
done

if [ ! -f "$shared_file" ]; then
  echo "ERROR: Token not found after timeout!"
  exit 1
fi

token=$(cat "$shared_file")
server_url="https://192.168.56.110:6443"
iface=$(ip -o -4 addr show | grep "$ip_worker" | awk '{print $2}')

# Garde-fou : l'interface doit avoir ete trouvee
if [ -z "$iface" ]; then
  echo "ERROR: no interface found for $ip_worker"
  ip -o -4 addr show
  exit 1
fi
echo "[LOG] Interface detected: $iface"

echo "Joining k3s cluster as agent..."
curl -sfL https://get.k3s.io | \
  K3S_URL="$server_url" K3S_TOKEN="$token" \
  INSTALL_K3S_EXEC="--node-ip=$ip_worker --flannel-iface=$iface" \
  sh -s - agent

echo "=== k3s Worker successfully joined the cluster ==="
