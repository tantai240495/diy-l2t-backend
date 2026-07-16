# Coding Provider Interface

Every provider adapter should support:

## start_interactive

Inputs:

- repository path;
- brief path;
- permission mode;
- optional session name.

Expected behavior:

- open the repository;
- load the brief;
- begin in plan/read-only mode;
- allow the human to interact;
- preserve a resumable session.

## run_headless

Inputs:

- repository path;
- approved brief;
- max turns/time/budget;
- allowed tools.

Expected behavior:

- no interactive questions;
- write structured result;
- fail closed when approval or information is missing.

## outputs

Write to the job directory:

- `plan.md`
- `execution.log`
- `test-results.md`
- `review.md`
- `result.md`
- `status.json`
