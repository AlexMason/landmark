# Working on Landmark

This repository *is* the process. Agents editing it follow the Landmark process themselves (`docs/process.md`), with these additions.

## What lives where

- `docs/process.md` is the specification. Change it first, then make the skills match.
- `skills/<name>/SKILL.md` is the executable form of one phase. Each skill must stay self-contained: it may read its own `assets/` and `references/`, never another skill's.
- `README.md` is for humans deciding whether to use Landmark. `INSTALL.md` is for agents doing the install.

## Rules for editing skills

- Keep the frontmatter to `name` and `description`. `name` must equal the directory name.
- Every skill opens by reading the target repo's `AGENTS.md` settings block and validating the incoming plan `status`. Do not remove those steps.
- Every stop condition must name what is missing and the documented alternative. Never add a silent fallback.
- Keep skills generic. No references to a specific company, person, or private infrastructure. Harness names are fine only where a harness genuinely differs (the `CLAUDE.md` shim; the install table).
- Under ~300 lines per `SKILL.md`. Move long reference material into `references/`.
- `./scripts/check.sh` must pass before filing.

## Landmark settings

```yaml
landmark:
  version: "0.1.0"
  branching: gitflow
  default_branch: main
  integration_branch: dev
  issue_tracker: github
  merge_strategy: squash
  test_command: "./scripts/check.sh"
  coverage_command: ""
  dev_environment: ""
  manual_test_url: ""
```
