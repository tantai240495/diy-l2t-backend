# Architecture

## 1. Control Plane

The control plane lives in this repository and does not depend on Claude Code or Codex:

- `config/projects.yaml`: registry of supported projects
- `integrations/`: MCP gateway and capability mappings
- `workflows/`: provider-neutral operating procedures
- `templates/`: artifacts exchanged between Hermes and coding providers
- `schemas/`: data contracts
- `jobs/`: state and outputs for each task
- `providers/`: adapters for individual coding providers

## 2. Hermes Agent

Hermes is responsible for:

1. Receiving requests from the user.
2. Collecting context from `company-gateway` and any optional connectors that
   are actually configured.
3. Treating external content as data rather than trusted instructions.
4. Identifying the correct project.
5. Creating `source-context.md`, `brief.md`, and `status.json`.
6. Invoking the configured coding-provider adapter after approval.
7. Summarizing the final result for the user.

Hermes should not directly:

- merge pull requests;
- deploy;
- access production secrets;
- run commands outside the designated coding workspace;
- change project policies;
- mutate Mattermost, Backlog, or Offwork without explicit approval.

## 3. Coding Provider

Every coding provider receives the same contract:

- project path;
- normalized source context;
- approved coding brief;
- permission mode;
- required checks;
- approval checkpoints.

The provider must return:

- investigation findings;
- implementation plan;
- code changes;
- test results;
- review findings;
- diff summary;
- draft PR URL when approved;
- final task status.

## 4. Human Approval Checkpoints

The MVP has four approval checkpoints:

1. After source collection and brief creation.
2. After the coding provider presents its implementation plan.
3. Before pushing a branch or creating a draft PR.
4. Before mutating Mattermost, Backlog, or Offwork.

## 5. Provider Portability

Do not embed the `claude` command in shared workflows. Shared workflows should call an adapter:

```text
providers/<provider>/run-interactive.sh
```

When moving to Codex, create an equivalent adapter while keeping the following unchanged:

- project registry;
- source-context format;
- coding briefs;
- workflows;
- security policy;
- approval checkpoints;
- job state.

## 6. Current Gateway Boundaries

The observed `company-gateway` tools support Backlog project/document metadata,
limited Mattermost team information, and Offwork request/reward operations.
They do not currently provide GitHub issue/PR operations or Mattermost
post/thread reads. Workflows must record those as missing capabilities instead
of assuming the data exists.
