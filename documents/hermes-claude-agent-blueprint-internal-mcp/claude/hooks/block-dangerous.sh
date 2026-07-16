#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"

DENY_PATTERN='(^|[;&|[:space:]])(sudo[[:space:]]+)?(rm[[:space:]]+-rf[[:space:]]+(/|~)|git[[:space:]]+push[[:space:]].*--force|git[[:space:]]+reset[[:space:]]+--hard|terraform[[:space:]]+apply|kubectl[[:space:]]+delete|helm[[:space:]]+uninstall|DROP[[:space:]]+DATABASE|TRUNCATE[[:space:]]+TABLE)'

if printf '%s' "$COMMAND" | grep -Eiq "$DENY_PATTERN"; then
  jq -n --arg reason "Blocked by project safety policy: $COMMAND" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
else
  exit 0
fi
