#!/bin/bash
# Commit everything staged by `git add -A` with the given message and push.
# Refuses to commit if anything under build/, logs/, or a binary slipped in.
set -euo pipefail
cd ~/TensorForge
msg="${1:?usage: commit.sh <message>}"
git add -A
if git diff --cached --name-only | grep -E '^(build|logs)/|\.(o|so|a|cubin|fatbin)$'; then
  echo "refusing: build output staged" >&2; exit 1
fi
git diff --cached --stat | tail -3
git commit -q -m "$msg"
git push -q origin main
git log --oneline -1
