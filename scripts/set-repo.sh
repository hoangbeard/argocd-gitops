#!/usr/bin/env bash
# Point every Argo CD Application and AppProject at your fork.
#
# Usage: scripts/set-repo.sh https://github.com/<you>/argocd-gitops.git
set -euo pipefail

new="${1:?Usage: $0 <git repo URL>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
old="$(awk '/repoURL:/ {print $2; exit}' "$ROOT/bootstrap/root-app.yaml")"

grep -rl --include='*.yaml' "$old" "$ROOT/bootstrap" "$ROOT/projects" "$ROOT/apps" |
  while read -r file; do
    sed -i.bak "s|$old|$new|g" "$file" && rm "$file.bak"
    echo "updated ${file#"$ROOT"/}"
  done
