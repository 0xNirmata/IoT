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


echo "=== Creating namespaces ==="

kubectl create namespace gitlab || echo "Namespace gitlab already exists"
kubectl create namespace argocd || echo "Namespace argocd already exists"
kubectl create namespace dev || echo "Namespace dev already exists"


echo "=== Installing ArgoCD ==="

# Add ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm install argocd argo/argocd \
  -n argocd \
  --set server.service.type=LoadBalancer \
  --set server.ingress.enabled=true \
  --set server.serviceNodePort=30080


echo "=== Creating GitLab repositories on cluster ==="

# Wait for GitLab to be ready before creating repos
echo "Waiting for GitLab to stabilize..."
sleep 60


echo "=== Installing GitLab ==="

helm install gitlab gitlab/gitlab \
-n gitlab \
-f /vagrant/confs/gitlab-values.yaml


echo "=== Waiting for GitLab to be ready (can take 5-10 minutes) ==="

# Wait loop with timeout instead of -w which hangs forever
MAX_WAITS=60   # Check up to 60 times
WAIT_INTERVAL=15  # Every 15 seconds
CURRENT_WAIT=0

echo "Checking GitLab pods status..."

while [ $CURRENT_WAIT -lt $MAX_WAITS ]; do
  echo "--- Check #$((CURRENT_WAIT + 1)) at $(date) ---"
  
  # Count running and ready pods
  RUNNING=$(kubectl get pods -n gitlab --no-headers 2>/dev/null | grep "Running" | wc -l)
  READY=$(kubectl get pods -n gitlab --no-headers 2>/dev/null | awk '{print $2}' | grep -E "^(1/1|2/2|3/3|4/4)$" | wc -l)
  
  echo "Running pods: $RUNNING, Ready pods: $READY"
  
  # GitLab needs at minimum these pods ready: webservice, sidekiq, postgresql, redis, nginx-ingress
  if [ $READY -ge 5 ]; then
    echo "✓ GitLab pods are ready!"
    kubectl get pods -n gitlab
    break
  fi
  
  # Check for failed pods
  FAILED=$(kubectl get pods -n gitlab --no-headers 2>/dev/null | grep -E "Error|CrashLoopBackOff" | wc -l)
  if [ $FAILED -gt 0 ]; then
    echo "⚠ Warning: Some pods are in Error or CrashLoopBackOff state:"
    kubectl get pods -n gitlab | grep -E "Error|CrashLoopBackOff"
    echo "Possible cause: Insufficient memory. Try increasing memory in gitlab-values.yaml"
    sleep $WAIT_INTERVAL
    CURRENT_WAIT=$((CURRENT_WAIT + 1))
    continue
  fi
  
  sleep $WAIT_INTERVAL
  CURRENT_WAIT=$((CURRENT_WAIT + 1))
done

if [ $READY -lt 5 ]; then
  echo "⚠ GitLab may not be fully ready yet. Check status with:"
  echo "   kubectl get pods -n gitlab"
  echo "   kubectl logs -n gitlab <pod-name>"
fi


echo ""
echo "=== Bonus installation finished ==="
echo ""
echo "=========================================="
echo "  ACCESS URLS:"
echo "=========================================="
echo "GitLab:       http://127.0.0.1.nip.io (port 8929)"
echo "ArgoCD UI:    http://localhost:8080"
echo ""
echo "Initial admin password for GitLab:"
echo "   kubectl get secret --namespace gitlab gitlab-gitlab-initial-root-password -o jsonpath='{\"data\":{\"initial_root_password\"}}' | base64 --decode"
echo ""
echo "ArgoCD admin password:"
echo "   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{\"data\":{\"password\"}}' | base64 --decode"
echo ""
echo "Pod Status:"
kubectl get pods -n gitlab
kubectl get pods -n argocd


echo ""
echo "=========================================="
echo "  GITOPS SETUP WITH ARGOCD"
echo "=========================================="
echo ""
echo "To enable GitOps synchronization:"
echo "1. Access ArgoCD UI: http://localhost:8080"
echo "2. Login with admin password (see below)"
echo "3. Create a new Application using the manifest in:"
echo "   /vagrant/confs/argocd-gitlab-app.yaml"
echo ""
echo "Or apply it manually:"
echo "   kubectl apply -f /vagrant/confs/argocd-gitlab-app.yaml"
echo ""
echo "This will make ArgoCD sync your GitLab repo to the k3d cluster automatically!"