#!/bin/bash

set -e

echo "=== Installing Docker ==="

apt-get update
apt-get install -y docker.io curl git

systemctl enable docker
systemctl start docker


echo "=== Installing k3d ==="

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash


echo "=== Installing kubectl ==="

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm kubectl


echo "=== Creating k3d cluster ==="

k3d cluster create bonus-cluster \
-p "8080:80@loadbalancer" \
-p "8888:8888@loadbalancer" \
-p "8929:8929@loadbalancer" \
--agents 1 \
--wait


echo "=== Installing Helm ==="

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


echo "=== Adding GitLab Helm repository ==="

helm repo add gitlab https://charts.gitlab.io/

helm repo update


echo "=== Creating namespace ==="

kubectl create namespace gitlab || true


echo "=== Installing GitLab ==="

helm install gitlab gitlab/gitlab \
-n gitlab \
-f /vagrant/confs/gitlab-values.yaml


echo "=== Waiting ==="

kubectl get pods -n gitlab -w #w monitoreo de pods , puede tardar entre 5 y 10 min


echo "=== Bonus installation finished ==="