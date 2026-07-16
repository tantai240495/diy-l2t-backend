#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <repo-path> [project-id]" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$1" && pwd)"
PROJECT_ID="${2:-$(basename "$REPO")}"

mkdir -p "$REPO/.claude/skills/implement-coding-task"
mkdir -p "$REPO/.claude/agents"
mkdir -p "$REPO/.claude/hooks"

cp "$ROOT/project/AGENTS.md" "$REPO/AGENTS.md"
cp "$ROOT/project/CLAUDE.md" "$REPO/CLAUDE.md"
cp "$ROOT/claude/skills/implement-coding-task/SKILL.md" \
   "$REPO/.claude/skills/implement-coding-task/SKILL.md"
cp "$ROOT/claude/agents/context-researcher.md" \
   "$REPO/.claude/agents/context-researcher.md"
cp "$ROOT/claude/agents/code-reviewer.md" \
   "$REPO/.claude/agents/code-reviewer.md"
cp "$ROOT/claude/hooks/block-dangerous.sh" \
   "$REPO/.claude/hooks/block-dangerous.sh"
cp "$ROOT/claude/settings.example.json" \
   "$REPO/.claude/settings.local.json"
chmod +x "$REPO/.claude/hooks/block-dangerous.sh"

echo "Bootstrapped project '$PROJECT_ID' at $REPO"
echo "Review AGENTS.md and .claude/settings.local.json before using Claude Code."
