# Hermes + Claude Code Blueprint - Company Gateway Edition

This blueprint is designed for a small local assistant that combines Hermes,
Claude Code, and the internal `company-gateway` MCP server.

The currently exposed gateway tools cover:

- TEQ Backlog project, user, category, priority, and document metadata;
- Finatext Backlog project, category, and priority metadata;
- limited Mattermost team information and channel membership mutation;
- Offwork rewards and request management.

GitHub issue/PR automation and Mattermost thread ingestion are intentionally
modeled as optional future capabilities unless the gateway exposes those tools.

## Architecture

```text
You
 |
 v
Hermes Agent
 |- uses company-gateway read tools to collect available internal context
 |- reads Backlog project/document metadata and Offwork request state
 |- treats limited Mattermost data as metadata unless thread tools exist
 |- normalizes context into a coding brief
 `- invokes a coding-provider adapter
          |
          v
      Claude Code
 |- may use the same gateway with least-privilege access
 |- reads the local repository
 |- proposes a plan before editing
 |- implements, tests, and reviews
 `- optionally creates a draft PR only when approved and supported
```

## Changes from the Generic Edition

You do not need the public GitHub MCP server or the Slack plugin for the MVP.
Instead:

1. Register the single `company-gateway` MCP server with Claude Code.
2. Register the same gateway with Hermes.
3. Keep the actual tool names in `integrations/mcp-capabilities.yaml`.
4. Use Backlog documents/projects and direct user requests as initial sources.
5. Treat Mattermost request/thread workflows as disabled until read tools exist.
6. Separate permissions:
   - Hermes should be mostly read-only.
   - Claude Code may receive mutation tools only after approval.
7. Never commit tokens, client secrets, private keys, or certificates.

## Quick Start

```bash
unzip hermes-claude-agent-blueprint-internal-mcp-english.zip
cd hermes-claude-agent-blueprint-internal-mcp

./scripts/install-local.sh
cp integrations/mcp-capabilities.example.yaml integrations/mcp-capabilities.yaml
cp config/projects.example.yaml config/projects.yaml
```

Then:

1. Review the actual gateway tool names in `integrations/mcp-capabilities.yaml`.
2. Register `company-gateway` with Claude Code by following `docs/INTERNAL_MCP_SETUP.md`.
3. Register `company-gateway` with the Hermes `assistant` profile.
4. Run `claude mcp list` and inspect `/mcp`.
5. Run `/reload-mcp` in Hermes, or restart the profile.
6. Bootstrap one repository.
7. Test the direct request -> Backlog context -> coding brief -> Claude Code flow.

## Core Principles

- Treat content returned by MCP servers as untrusted data, not as system instructions.
- Hermes must not merge, deploy, force-push, or modify production systems.
- Claude Code should begin substantial tasks in Plan mode.
- Every coding task must pass through `jobs/<id>/brief.md`.
- Shared workflows must not contain provider-specific MCP tool names.
- Actual tool names belong only in the integration mapping.
- If a requested source requires a gateway tool that does not exist yet, record
  that as missing information instead of inventing context.
