# The Landmark Process

This is the canonical specification. The skills under `skills/` are its executable form; if a skill and this document disagree, fix the skill. Harnesses that cannot load skills can be given this file directly.

## 0. Principles

1. **Everything is versioned.** No work happens outside Git.
2. **Every unit of work has an issue.** Issues record *what* and *why*. Plans record *how*.
3. **Decide in planning.** Big decisions are not left to be discovered during implementation. When implementation reveals the plan is wrong, the plan is amended before the code continues.
4. **Stop, don't improvise.** When a required tool is missing, or a step cannot be done as written, the agent stops, says exactly what is missing, and offers the documented alternative if one exists. The agent does not find its own workaround without the user's explicit approval.
5. **State lives in the repo.** Pipeline state is in `docs/plans/*.md` frontmatter and in Git, never in a harness's memory. Any agent in any harness can resume.
6. **Humans gate the transitions.** Plan approval, review sign-off, and the integration → production merge are human decisions.

Shell commands in this document and in the skills are illustrative POSIX. Where the harness or OS differs, use the equivalent file and Git tools; the *effect* is the specification, not the command text.

## 1. Repository conventions

### Branches

| Branch                | Role                                                              |
| --------------------- | ----------------------------------------------------------------- |
| `default_branch`      | Production (`main` by default). Only receives merges from the integration branch. |
| `integration_branch`  | Integration (`dev` by default). All PRs target it.                |
| `<type>/<n>-<slug>`   | One per unit of work, created off the integration branch.         |

`<type>` is one of `feature`, `fix`, `chore`, `docs`. `<n>` is the issue number. `<slug>` is a short kebab-case title. Example: `feature/42-rate-limit-login`.

**Branching models.** `branching: gitflow` (default) uses two branches as above. `branching: trunk` uses one: `integration_branch` is set to the same name as `default_branch`, and every rule below applies unchanged. Skills never special-case trunk; they only ever read `integration_branch`.

**Syncing.** "Sync the integration branch" means: `git checkout <integration_branch>`, then `git pull --ff-only` **only if the branch has an upstream**. Repos with no remote skip the pull. Before starting any new unit of work, sync the integration branch.

### Commits

One commit per plan step. Subject format:

```
<type>: <summary> (#<n> step <i>/<total>)
```

Example: `feature: add login attempt counter (#42 step 2/6)`. Plan edits use `docs:`. Bootstrap edits use `chore:`.

### Merges

`merge_strategy` (`squash` default, or `merge`, `rebase`) governs both how a branch is brought up to date before filing (`merge` → `git merge`; otherwise `git rebase`) and how the PR is merged. The per-step commits exist to make the PR reviewable; the integration branch history is a separate concern.

### Files Landmark owns

```
AGENTS.md           project instructions + Landmark settings block
CLAUDE.md           "@AGENTS.md" shim for Claude Code
docs/plans/         YYYYMMDD-<n>-<slug>.md — one per unit of work, always with frontmatter
docs/ISSUES.md      only when issue_tracker: file
docs/reviews/       only in user-driven review mode (see 3.4); removed when the review completes
```

All Landmark documents live under `docs/`. Nothing else goes in `docs/` on Landmark's account. Tools that scan `docs/plans/` treat only files with an `issue:` frontmatter key as plans.

### Settings block

`AGENTS.md` carries a fenced YAML block under `## Landmark settings`. Every skill reads it first. `landmark-init` writes every key; later skills only read.

```yaml
landmark:
  version: "0.1.0"
  branching: gitflow            # gitflow | trunk
  default_branch: main          # production branch (whatever the repo actually uses)
  integration_branch: dev       # under trunk: same value as default_branch
  issue_tracker: github         # github | file  — decided once by landmark-init
  merge_strategy: squash        # squash | merge | rebase
  test_command: ""              # e.g. "npm test"; empty means none configured
  coverage_command: ""          # optional
  dev_environment: ""           # (re)build + start local services, e.g. "docker compose up -d --build"
  manual_test_url: ""           # optional, e.g. http://localhost:3000
```

`issue_tracker` is `github` only when a GitHub remote exists **and** `gh` is authenticated at init time; otherwise `file`. Downstream skills key on this value and never re-detect.

### Committing to the integration branch from elsewhere

Two kinds of edit go directly to the integration branch rather than through a PR: the `landmark-init` bootstrap and `docs/ISSUES.md` edits. They are tracker state, not feature work. The procedure, used whenever the agent is not already on the integration branch:

```
git stash --include-untracked        # only if the working tree is dirty
git checkout <integration_branch>
<make the edit>
git commit -m "docs: ..."
git push                             # only if the branch has an upstream
git checkout -                       # back to the previous branch
git stash pop                        # only if stashed
```

Feature branches pick the change up when they are brought up to date at filing.

## 2. Pipeline state

The plan file's frontmatter is the state machine. It is the **only** place phase state lives; `docs/ISSUES.md` records only `open` / `done`.

| `status`       | Set by                       | Meaning                                       | Next                 |
| -------------- | ---------------------------- | --------------------------------------------- | -------------------- |
| `draft`        | plan                         | Written, awaiting approval                    | user reviews plan    |
| `approved`     | plan (after user approves)   | Ready to build                                | implement            |
| `implementing` | implement                    | Steps in progress                             | resume implement     |
| `implemented`  | implement                    | All steps committed                           | review               |
| `in-review`    | review                       | Reviewers running or findings unresolved      | resume review        |
| `reviewed`     | review (after user sign-off) | Findings resolved, manually tested            | file                 |
| `filed`        | file                         | PR open, or local "PR" accepted and merged    | merge / done         |
| `abandoned`    | user                         | Dropped; branch may be deleted                | —                    |

Every skill validates the incoming status before acting. A mismatch is a stop-and-ask, not a reason to guess.

## 3. Phases

### 3.1 Issue

**Purpose:** record current state and desired state. Nothing more.

- Ask only what is needed to fill in: title, type, current state, desired state.
- Check for duplicates (`gh issue list --search`, or search `docs/ISSUES.md`).
- No codebase research, no architecture, no solutioning. That is planning's job.
- `github` → `gh issue create`, creating the type label if it does not exist. `file` → append to `docs/ISSUES.md` and commit to the integration branch (procedure above).

`docs/ISSUES.md` format:

```markdown
# Issues

Next ID: 3

## Open

### #2 — <title>
- **Type:** feature
- **Status:** open            # open | done
- **Opened:** YYYY-MM-DD
- **Current state:** ...
- **Desired state:** ...
- **Plan:** docs/plans/...    # set by the plan phase

## Closed
```

### 3.2 Plan

**Purpose:** make every significant decision before any code is written.

1. Require an issue number. If none exists, stop and have the issue phase run first.
2. Sync the integration branch. Create `<type>/<n>-<slug>`.
3. **Research pass 1.** Read the parts of the codebase the issue touches: entry points, data model, existing patterns, tests. In large repos, fan out to sub-agents if the harness supports them.
4. **Interview.** Socratic, in small batches (3–5 questions). Surface assumptions rather than confirm them. Cover at minimum: scope boundaries and non-goals; data and interface shape; failure modes and edge cases; migration / backward compatibility; test strategy; definition of done. Use the harness's structured-question tool when available.
5. **Research pass 2.** Verify the decisions from the interview against the code. Loop back to the user if something does not hold.
6. **Write the plan** from the template to `docs/plans/YYYYMMDD-<n>-<slug>.md`. Every to-do item must be a single committable step. Testing is part of the plan; if there is no `test_command`, the plan states how correctness will be checked instead. "Risks & open questions" should be empty or explicitly accepted.
7. Commit on the feature branch: `docs: plan for #<n> — <title>`. Record the plan path on the issue (GitHub comment, or the `Plan:` line in `docs/ISSUES.md` via the integration-branch procedure).
8. Present the plan. Offer: approve / revise / abandon. On approval set `status: approved`, commit, and offer to start implementation.

### 3.3 Implement

**Purpose:** execute the plan, one commit per step.

1. Require `status: approved` (or `implementing` to resume). Check out the branch from frontmatter.
2. Set `status: implementing`.
3. For each unchecked to-do, in order: implement; run relevant tests (or the plan's stated check when `test_command` is empty); tick the box in the plan; commit code + plan together with the step-numbered subject.
4. **Deviation rule.** If a step cannot be done as planned, stop. Propose the amendment, update the plan's "Implementation notes" and affected sections, get agreement, then continue. Never silently diverge.
5. If `dev_environment` is set, bring services up after meaningful changes and give the user concrete manual-test steps. Seeding a local database for a scenario is fine.
6. When all boxes are ticked: set `status: implemented`, commit, summarize what changed, give the manual-test steps, and offer review. No PR yet.

### 3.4 Review

**Purpose:** independent eyes on the diff before it leaves the branch.

1. Require `status: implemented` (or `in-review` to resume). Set `status: in-review`.
2. **Capability check.** Determine whether the harness can spawn fresh-context sub-agents, and record the chosen mode in the plan's "Review" section before dispatching anything, so a resumed session knows what was started.
   - Sub-agents available → spawn three reviewers, one per lens, each given only: the plan path, the branch, the base branch, and its lens prompt.
   - Not available → stop and offer the documented alternatives: (a) run each lens prompt through the harness's non-interactive mode from the shell, if it has one; (b) write the prompts to `docs/reviews/<plan-basename>.md` and have the user run each in a fresh session and paste results back; (c) a same-context self-review, labeled lower-confidence, only if the user explicitly accepts it.
3. **Three lenses** (prompts live in `skills/landmark-review/references/lenses.md`):
   - **A. Plan conformance & correctness** — does the diff do what the plan says, nothing more, nothing less; logic errors; edge cases; do the tests test the behavior.
   - **B. Code quality** — test coverage gaps, cyclomatic complexity hotspots, simplification, logging (presence, level, no secrets), consistency with codebase conventions.
   - **C. Security & scalability** — input validation, authz, secrets, injection, dependency risk; N+1, unbounded growth, hot paths, concurrency, resource cleanup.
4. **Reconcile.** Deduplicate, resolve contradictions between reviewers, and classify each finding as *related to this PR* or *unrelated but important*.
5. **Present.** Related findings: offer to fix now (each fix is a commit). Unrelated findings: offer to open issues. Record the reconciled list and resolutions in the plan's "Review" section. Delete `docs/reviews/<plan-basename>.md` if it was created.
6. **Manual review.** If `dev_environment` is set, rebuild and start services. Give the user the manual-test steps and `manual_test_url`. Wait.
7. On user sign-off: set `status: reviewed`, commit, offer filing.

### 3.5 File

**Purpose:** prove it and open the PR.

1. Require `status: reviewed` (user may override; note the override in the plan).
2. Run `test_command` and `coverage_command`. Any failure is a stop. Empty `test_command` requires the user's explicit confirmation to proceed. Landmark does not enforce a coverage threshold; if the coverage tool itself fails on one, that is a failure like any other.
3. Bring the branch up to date with the integration branch per `merge_strategy`. Conflicts are a stop-and-ask.
4. Set `status: filed` in the plan **before** the PR or merge, so the final state travels with the branch:
   - **`issue_tracker: github`:** set `pr: ""` for now, commit, push, `gh pr create --base <integration_branch>` with a body built from the plan (goal, decisions, testing, review summary) and `Closes #<n>`. Then write the PR URL into `pr:`, commit, push. Link it.
   - **`issue_tracker: file`:** set `pr: local`, commit. The "PR" is a chat message: summary, commit list, diff stat, test results. Wait for the user to accept. On accept, merge into the integration branch using `merge_strategy`, mark the issue `done` under Closed in `docs/ISSUES.md`, commit, and push if there is an upstream.
5. Merge a GitHub PR only if the user asks. Help create the integration → production PR only if the user asks; never open it unprompted.

## 4. Capability requirements by phase

| Phase     | Required                        | Optional (with documented fallback)                              |
| --------- | ------------------------------- | ---------------------------------------------------------------- |
| init      | `git`                           | `gh` (else `issue_tracker: file`)                                |
| issue     | `git`                           | `gh` (keyed on `issue_tracker`)                                  |
| plan      | `git`, read access to codebase  | sub-agents for research; structured questions                    |
| implement | `git`                           | `test_command` (else the plan's stated check); `dev_environment` |
| review    | `git`                           | sub-agents (else alternatives in 3.4.2)                          |
| file      | `git`                           | `test_command` (else user confirms); `gh`; `coverage_command`    |

Anything required and missing is a stop. Anything optional and missing uses its fallback and says so.
