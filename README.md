# diy-l2t-backend

FastAPI backend project managed with Poetry.

## Setup

```sh
make setup
```

## Hermes-first Local Assistant

The selected direction is to run upstream `nousresearch/hermes-agent` as the
assistant runtime and keep only project-specific profile, policy, MCP routing,
audit hooks, and verification in this repository.

Start with `documents/README.md`. `documents/NOW.md` contains the single active
checkpoint. Hermes-specific profile, skills, hooks, and tests will be added only
by the checkpoint that verifies each capability.
