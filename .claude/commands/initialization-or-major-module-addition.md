---
name: initialization-or-major-module-addition
description: Workflow command scaffold for initialization-or-major-module-addition in tldr-cli.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /initialization-or-major-module-addition

Use this workflow when working on **initialization-or-major-module-addition** in `tldr-cli`.

## Goal

Sets up a new module or major feature area, including schema/migrations, core library files, and supporting scripts or documentation.

## Common Files

- `Gemfile`
- `Gemfile.lock`
- `db/migrate/*.rb`
- `lib/**`
- `spec/**`
- `README.md`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Add or update Gemfile and Gemfile.lock for dependencies
- Create or update database migration scripts in db/migrate/
- Add core library files in lib/ (often in a new subdirectory)
- Add supporting scripts, documentation, and/or tests

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.