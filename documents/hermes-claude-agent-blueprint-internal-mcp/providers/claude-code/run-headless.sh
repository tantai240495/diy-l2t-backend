#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <repo-path> <brief-path>" >&2
  exit 1
fi

REPO="$(cd "$1" && pwd)"
BRIEF="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

if ! grep -Eiq 'Brief approved:[[:space:]]*yes' "$BRIEF"; then
  echo "Refusing headless execution: brief is not approved." >&2
  exit 2
fi

cd "$REPO"
claude -p \
  "Read and follow the approved brief at $BRIEF. Implement it, run required checks, and return a concise structured result. Do not push, create a PR, merge, or deploy." \
  --allowedTools "Read,Edit,Write,Bash,Grep,Glob" \
  --max-turns 20
