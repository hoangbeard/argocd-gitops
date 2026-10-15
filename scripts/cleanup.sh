#!/usr/bin/env bash
# Remove everything this repo installed.
# For a throwaway kind cluster, `make kind-down` is faster.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Context: $(kubectl config current-context)"
read -r -p "Delete all apps and Argo CD from this cluster? [y/N] " answer
[[ "$answer" == "y" ]] || exit 1

echo "==> Deleting the root app (and every app it created)"
# Stop Argo CD from re-creating apps while we delete them.
kubectl -n argocd patch application argocd --type merge \
  -p '{"spec":{"syncPolicy":{"automated":null}}}' 2>/dev/null || true
kubectl -n argocd delete application root --wait=true --timeout=180s 2>/dev/null || true
kubectl -n argocd delete application --all --wait=true --timeout=180s 2>/dev/null || true

echo "==> Deleting Argo CD"
kubectl delete -k "$ROOT/bootstrap" --ignore-not-found --wait=false
kubectl delete namespace argocd --ignore-not-found --timeout=120s

echo "Done."
