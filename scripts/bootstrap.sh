#!/usr/bin/env bash
# Install Argo CD and hand control over to Git.
# Run once per cluster. After this, change things through Git only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Context: $(kubectl config current-context)"

echo "==> Installing Argo CD, AppProjects and the root app"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# The first apply can fail while the Argo CD CRDs are still being registered.
# Retry a few times instead of failing.
for i in 1 2 3; do
  if kubectl apply -k "$ROOT/bootstrap" --server-side --force-conflicts; then
    break
  fi
  echo "    Waiting for CRDs, retry $i/3..."
  sleep 10
done

echo "==> Waiting for Argo CD to be ready"
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s

echo
echo "Done. Argo CD now syncs everything under apps/ from Git."
echo "  make status    # list applications"
echo "  make password  # initial admin password"
echo "  make ui        # open the UI on http://localhost:8080"
