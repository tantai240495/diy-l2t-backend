#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <repo-path> <brief-path>" >&2
  exit 1
fi

REPO="$(cd "$1" && pwd)"
BRIEF="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

if [ ! -f "$BRIEF" ]; then
  echo "Brief not found: $BRIEF" >&2
  exit 1
fi

cd "$REPO"
exec claude --permission-mode plan \
  "Use the /implement-coding-task workflow. Read the approved coding brief at: $BRIEF. Investigate and present a plan only; do not edit until I approve."
