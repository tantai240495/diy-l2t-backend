#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_PROFILE_HOME="${HERMES_PROFILE_HOME:-$HOME/.hermes/profiles/assistant}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

mkdir -p "$HERMES_PROFILE_HOME/skills/prepare-coding-task"
mkdir -p "$CLAUDE_HOME/agents"

cp "$ROOT/hermes/skills/prepare-coding-task/SKILL.md" \
   "$HERMES_PROFILE_HOME/skills/prepare-coding-task/SKILL.md"
cp "$ROOT/claude/agents/context-researcher.md" \
   "$CLAUDE_HOME/agents/context-researcher.md"
cp "$ROOT/claude/agents/code-reviewer.md" \
   "$CLAUDE_HOME/agents/code-reviewer.md"

if [ ! -f "$ROOT/config/projects.yaml" ]; then
  cp "$ROOT/config/projects.example.yaml" "$ROOT/config/projects.yaml"
fi

find "$ROOT/scripts" "$ROOT/providers" -type f -name "*.sh" -exec chmod +x {} +

echo "Installed Hermes skill into: $HERMES_PROFILE_HOME"
echo "Installed Claude Code agents into: $CLAUDE_HOME"
echo "Edit: $ROOT/config/projects.yaml"
