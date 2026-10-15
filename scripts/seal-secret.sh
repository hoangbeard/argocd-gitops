#!/usr/bin/env bash
# Create a SealedSecret that is safe to commit.
#
# Usage:
#   scripts/seal-secret.sh <namespace> <name> KEY=value [KEY=value ...] > path/to/sealed-secret.yaml
#
# The plain value never touches the disk. Only the Sealed Secrets controller
# in the current cluster can decrypt the result.
set -euo pipefail

if [[ $# -lt 3 ]]; then
  sed -n '4,6p' "$0" >&2
  exit 1
fi

namespace="$1"; name="$2"; shift 2

args=()
for pair in "$@"; do
  args+=("--from-literal=$pair")
done

kubectl create secret generic "$name" --namespace "$namespace" \
  "${args[@]}" --dry-run=client -o yaml |
  kubeseal --controller-namespace kube-system --format yaml
