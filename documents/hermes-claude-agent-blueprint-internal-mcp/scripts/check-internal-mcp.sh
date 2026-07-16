#!/usr/bin/env bash
set -euo pipefail

echo "=== Claude Code MCP servers ==="
claude mcp list || true

echo
echo "Expected server names:"
echo "  - company-gateway"

echo
echo "Open Claude Code and run /mcp to inspect authentication and tool availability."
echo "Open Hermes and run /reload-mcp after editing its profile config."
