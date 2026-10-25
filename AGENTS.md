# Agent context for <repository name>

## Repository

<Describe what this repository provides, its intended users, and the main directories.>

## Checks

Run `make check` before committing. Record any environment dependent failures in the task brief or handoff with the command and observed result.

## Commits

Keep each commit focused on one change. Use an imperative subject that says what changed. Include the relevant tests in the same commit where practical. Do not commit generated secrets, local machine paths, or credentials.

## State

Write the current state, verification, and next action in `HANDOFF.md` (start from `HANDOFF.md.example`). Keep task requirements and acceptance criteria in `tasks/` using the format in `tasks/README.md`.
