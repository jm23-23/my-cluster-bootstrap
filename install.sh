#!/bin/bash
set -e

echo "🚀 Starting Cluster Reconstruction..."

# 1. Clean up namespaces if they exist from a previous broken run
echo "🧹 Cleaning up existing namespaces..."
kubectl delete namespace argocd --ignore-not-found=true
kubectl delete deployment metrics-server -n kube-system --ignore-not-found=true

# 2. Add and update Helm Repositories
echo "📦 Adding Helm repositories..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 3. Install Argo CD cleanly
echo "📥 Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 9.5.16 \
  -f argocd-values.yaml \
  --force-conflicts

# 4. Wait for Argo CD API Server to be ready
echo "⏳ Waiting for Argo CD to spin up..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=90s

# 5. Inject the Bootstrap GitOps Application
echo "☸️ Applying Root GitOps Manifest..."
kubectl apply -f apps/root-bootstrap.yaml

echo "✅ Done! Argo CD is now automatically building your Metrics Server and test apps from Git."