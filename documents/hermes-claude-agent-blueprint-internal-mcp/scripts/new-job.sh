#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <project-id> <job-id>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ID="$1"
JOB_ID="$2"
JOB_DIR="$ROOT/jobs/$JOB_ID"

if [ -e "$JOB_DIR" ]; then
  echo "Job already exists: $JOB_DIR" >&2
  exit 1
fi

mkdir -p "$JOB_DIR"
cp "$ROOT/templates/coding-brief.md" "$JOB_DIR/brief.md"

cat > "$JOB_DIR/status.json" <<EOF
{
  "id": "$JOB_ID",
  "project_id": "$PROJECT_ID",
  "provider": "claude-code",
  "repo_path": "",
  "source_links": [],
  "status": "draft",
  "acceptance_criteria": [],
  "required_checks": [],
  "allowed_actions": ["read", "edit", "test", "draft_pr_after_approval"],
  "forbidden_actions": ["merge", "deploy", "force_push"]
}
EOF

touch "$JOB_DIR/execution.log"
echo "Created: $JOB_DIR"
