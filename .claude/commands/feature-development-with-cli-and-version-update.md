---
name: feature-development-with-cli-and-version-update
description: Workflow command scaffold for feature-development-with-cli-and-version-update in tldr-cli.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /feature-development-with-cli-and-version-update

Use this workflow when working on **feature-development-with-cli-and-version-update** in `tldr-cli`.

## Goal

Implements a new feature by updating CLI command logic and bumping the CLI version.

## Common Files

- `lib/tldr/cli/commands.rb`
- `lib/tldr/cli/version.rb`
- `CHANGELOG.md`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Implement or update feature logic in lib/tldr/cli/commands.rb
- Update version in lib/tldr/cli/version.rb
- Update CHANGELOG.md to document the new feature

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.