# Landmark

A portable blueprint for agentic software development.

Landmark is a set of skills, templates, and conventions that tell a coding agent how to work in a repository: how to track work, plan it, implement it, review it, and file it. The same way, in every harness.

Point an agent at this repo and say **"install Landmark"**. That is the whole pitch.

## Why

Every coding harness has its own place for instructions, skills, and rules. Switching between them means rebuilding the same process each time, and the process drifts. Landmark makes the process a dependency instead: install it once per harness, initialize it once per repository, and every agent you run follows the same workflow.

Landmark ships in the [Agent Skills](https://agentskills.io) format (`SKILL.md`), which is read natively by most current harnesses. No per-harness adapters.

## Quick start

**1. Install the skills into your harness** (once per machine):

```sh
npx skills add alexmason/landmark
```

Works for any harness that reads the Agent Skills format. Manual install paths and harness notes are in [INSTALL.md](INSTALL.md). You can also just tell your agent: *"Read INSTALL.md in this repo and install Landmark."*

**2. Initialize a repository** (once per repo):

```
/landmark-init
```

Sets up `main` + `dev`, `docs/plans/`, and an `AGENTS.md` with a Landmark settings block. Safe to run on an existing repo; it appends rather than overwrites.

**3. Do work:**

```
/landmark-issue      capture what and why
/landmark-plan       research, interview, decide, write the plan
/landmark-implement  work the plan, one commit per step
/landmark-review     fresh-context reviewers, three lenses
/landmark-file       tests, PR against dev
/landmark-status     where am I?
```

Each skill ends by offering the next one. Each one can also be run on its own.

## The process

```
 ┌───────┐    ┌──────┐    ┌───────────┐    ┌────────┐    ┌──────┐
 │ issue │ ─▶ │ plan │ ─▶ │ implement │ ─▶ │ review │ ─▶ │ file │
 └───────┘    └──────┘    └───────────┘    └────────┘    └──────┘
   what &       decide       one commit      3 lenses,     tests,
   why only     everything   per step        reconciled    PR → dev
```

State lives in the plan file's frontmatter, so any agent in any harness can pick up mid-stream:

| `status`       | Meaning                                  | Next action            |
| -------------- | ---------------------------------------- | ---------------------- |
| `draft`        | Plan written, awaiting your approval     | review the plan        |
| `approved`     | You signed off                           | `/landmark-implement`  |
| `implementing` | Steps in progress                        | resume implement       |
| `implemented`  | All steps committed                      | `/landmark-review`     |
| `in-review`    | Reviewers running or findings unresolved | resume review          |
| `reviewed`     | Findings resolved, you've tested locally | `/landmark-file`       |
| `filed`        | PR open (or local merge accepted)        | merge, or wait         |

The full specification is in [docs/process.md](docs/process.md).

## Ground rules

These are the non-negotiables the skills enforce:

- **Everything is versioned.** `main` is production. `dev` is integration. Work happens on `feature/`, `fix/`, `chore/`, or `docs/` branches off `dev`. PRs target `dev`. `dev → main` is a human decision.
- **Every unit of work has an issue.** GitHub Issues when there is a GitHub remote and `gh` is authenticated; `docs/ISSUES.md` otherwise. Decided once at init.
- **Decisions are made in planning,** not discovered during implementation. If implementation reveals the plan is wrong, the plan is amended first.
- **The agent stops when a tool is missing.** It names what is missing and the documented alternative. It does not improvise a workaround without explicit approval.
- **State lives in the repository** (`docs/`), never in the harness.

## What Landmark puts in your repo

```
AGENTS.md            project instructions + Landmark settings block
CLAUDE.md            one line: @AGENTS.md  (Claude Code shim; other harnesses read AGENTS.md directly)
docs/
  plans/             YYYYMMDD-<issue>-<slug>.md, one per unit of work
  ISSUES.md          only when issue_tracker is file
  reviews/           only while a user-driven review is in progress
```

Nothing else. Landmark does not add CI, hooks, or tooling to your project.

## Repository layout

```
skills/
  landmark-init/       bootstrap a repo
  landmark-issue/      capture an issue (+ ISSUES.md template)
  landmark-plan/       research → interview → plan (+ plan template)
  landmark-implement/  work the plan
  landmark-review/     fresh-context review (+ lens prompts)
  landmark-file/       tests → PR
  landmark-status/     read plan frontmatter, report state
docs/
  process.md           the canonical specification
scripts/
  check.sh             validates skills; the repo's own test_command
INSTALL.md             agent-facing install instructions
AGENTS.md              instructions for agents working on Landmark itself
```

## Customizing

Fork it. The process is yours to change; the skills are plain markdown. Keep each skill self-contained (they are installed individually), and keep project-specific configuration in the target repo's `AGENTS.md` settings block rather than in the skills.

Before publishing your fork, replace `alexmason` with your GitHub handle in `README.md`, `INSTALL.md`, and `skills/landmark-init/assets/AGENTS.md`. `./scripts/check.sh` validates the skills.

## Versioning

Tagged releases. `landmark-init` records the version it installed in the settings block so you can tell which repos are behind. To update a harness, re-run the install command.

## License

MIT. See [LICENSE](LICENSE).
