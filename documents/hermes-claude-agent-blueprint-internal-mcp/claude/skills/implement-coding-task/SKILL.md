---
description: Implements an approved provider-neutral coding brief with a plan-first, human-supervised workflow. Use when given a jobs/<id>/brief.md file or an approved coding task.
---

# Implement Coding Task

## Input

The argument should point to an approved coding brief.

## Procedure

1. Read the brief.
2. Read `AGENTS.md`, `CLAUDE.md`, project rules, and relevant nested instructions.
3. Confirm the brief says `Brief approved: yes`. If not, do not modify files.
4. Investigate in read-only mode.
5. Present:
   - concise root cause;
   - implementation plan;
   - files expected to change;
   - tests to add/run;
   - risks and assumptions.
6. Stop for plan approval.
7. After approval, implement the smallest coherent change.
8. Add a regression test for bug fixes unless explicitly exempted.
9. Run all required checks from the brief and project instructions.
10. Delegate an independent diff review to the `code-reviewer` agent.
11. Present:
    - changed files;
    - behavior change;
    - test results;
    - unresolved risks.
12. Do not push, create a PR, or mutate Mattermost/Backlog/Offwork state until
    the user approves.
13. Never merge or deploy.

## Failure handling

- Stop after two materially different failed approaches.
- Preserve logs and explain the blocker.
- Never weaken tests solely to make them pass.
