#!/bin/bash

echo "=== 1. Instalando Docker ==="
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
# Permite usar docker sin usar 'sudo'
sudo usermod -aG docker $USER

echo "=== 2. Instalando K3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash

echo "=== 3. Instalando Kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "=== 4. Creando el Clúster K3d para el proyecto ==="
# Redirige el puerto 8080 (para ArgoCD) y el 8888 (para la app de Wil)
k3d cluster create iot-cluster \ #... --wait en caso no sepa a quien conectarse
  -p "8080:80@loadbalancer" \
  -p "8888:8888@loadbalancer" \
  --agents 1 \
  --wait

echo "=== ¡Todo listo! Clúster creado con éxito ==="
kubectl get nodes
