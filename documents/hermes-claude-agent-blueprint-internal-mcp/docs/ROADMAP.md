# Roadmap

## Phase 1 - Interactive First

- Run Hermes locally through its CLI or TUI.
- Run Claude Code locally.
- Connect the `company-gateway` MCP server.
- Connect Google Workspace to Hermes when needed.
- Use provider-neutral coding briefs.
- Require Plan mode and human approval.
- Run one coding task at a time.

## Phase 2 - Repeatable Workflows

- Add reusable skills for Hermes and Claude Code.
- Add context-researcher and code-reviewer subagents.
- Add hooks that block dangerous commands.
- Support multiple repositories through the project registry.
- Use a Git worktree for each task.
- Create draft pull requests only.

## Phase 3 - Background Preparation

- Run the Hermes gateway.
- Generate a daily brief from available company-gateway data and optional
  email/calendar connectors.
- Automatically prepare coding briefs from new issues or requests.
- Wait for user approval before opening a coding session.

## Phase 4 - Controlled Automation

- Add a queue and durable job state.
- Run simple, well-defined coding tasks in headless mode.
- Add budgets, timeouts, retries, and observability.
- Use the Claude Agent SDK for workflows that have become stable.
- Add a Codex provider adapter.
