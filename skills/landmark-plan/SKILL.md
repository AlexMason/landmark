---
name: landmark-plan
description: Turn an issue into an approved implementation plan — research the codebase, interview the user Socratically, decide everything significant, and write docs/plans/YYYYMMDD-<issue>-<slug>.md. Creates the feature branch. Use when the user says "plan this", "plan issue #N", or wants to start work on something that has an issue but no plan.
---

# landmark-plan

The most important phase. Every significant decision is made here so that implementation is transcription, not invention.

## Preconditions

1. Read the `## Landmark settings` block in `AGENTS.md`. If absent, **stop** and suggest `landmark-init`.
2. Require an issue number. If the user has not given one and no matching issue exists, **stop**: ask the user to run `landmark-issue` first (invoke it yourself if the harness lets skills call skills), then return here with the number.
3. Load the issue (`gh issue view <n>` or the entry in `docs/ISSUES.md`).
4. If a plan for this issue already exists in `docs/plans/`, show its `status` and ask whether to revise it or start over. Do not silently overwrite.

## Rule

If any step cannot be completed as written, stop, say what is missing, and offer the documented alternative. Do not improvise.

## Steps

### 1. Branch

If there are uncommitted changes on the current branch, **stop** and ask the user to commit or stash them. Then:

```
git checkout <integration_branch>
git pull --ff-only          # only if the branch has an upstream; no-remote repos skip this
git checkout -b <type>/<n>-<slug>
```

`<type>` from the issue; `<slug>` is a short kebab-case title. If the branch already exists, check it out instead (and pull if it has an upstream).

### 2. Research pass 1 — the codebase as it is

Read the parts of the codebase the issue touches:

- entry points and call paths for the affected behavior,
- data models, schemas, migrations,
- existing patterns the change should follow (how similar things are done here),
- existing tests for the area, and how tests are run (`test_command`),
- configuration and environment the change depends on.

In large repositories, fan out to sub-agents if the harness supports them; otherwise read directly. Write down what you found as you go; it becomes the plan's **Context** section.

### 3. Interview

Goal: surface assumptions, not confirm them. Ask Socratic questions in batches of 3–5. Use the harness's structured-question tool when one exists; otherwise ask in prose. Keep going until the big decisions are made; do not leave them "to be figured out during implementation."

Cover at minimum:

- **Scope** — what is in, what is explicitly out (becomes **Non-goals**).
- **Shape** — data, interfaces, API surface, naming.
- **Failure modes** — what happens on bad input, timeouts, partial failure, concurrency.
- **Compatibility** — migrations, existing data, existing callers, rollback.
- **Testing** — what level, what cases, what is hard to test and how to handle it.
- **Done** — how the user will know it works; manual test steps if `dev_environment` applies.

Where the user's answer conflicts with what the research found, say so and resolve it now. Record each decision with the alternative considered and the reason; this becomes the **Decisions** table.

### 4. Research pass 2 — verify the decisions

Go back to the code with the decisions in hand. Check that each one is actually implementable as agreed: the hook point exists, the type supports it, the test harness can express the case. Anything that does not hold goes back to the user before writing the plan.

### 5. Write the plan

Copy `assets/plan-template.md` from this skill's directory to:

```
docs/plans/YYYYMMDD-<n>-<slug>.md
```

Fill every section. Standards:

- **Steps** are the contract with `landmark-implement`. Each is one committable unit that leaves the branch working. Tests come before or alongside the code they cover. Typical range is 3–12 steps; more than that suggests the issue should be split.
- **Testing** is not optional. If there is no `test_command`, the plan must say how correctness will be checked anyway (and the first step may be to add a test runner).
- **Risks & open questions** must be empty or each item marked *accepted*.
- Frontmatter: `issue`, `title`, `type`, `branch`, `status: draft`, `created`, `pr: ""`.

Commit on the feature branch:

```
docs: plan for #<n> — <title>
```

Record the plan path on the issue:

- `github`: `gh issue comment <n> --body "Plan: docs/plans/<file>"`.
- `file`: set the issue's `Plan:` line in `docs/ISSUES.md` using the integration-branch procedure — `git stash --include-untracked` only if dirty; `git checkout <integration_branch>`; edit; commit `docs: link plan for #<n>`; push only if upstream; `git checkout -`; `git stash pop` if stashed. Do **not** change `Status:`; phase state lives in the plan's frontmatter.

### 6. Present and gate

Show the user the plan (the whole file, or a tight summary with the Decisions table and Steps list in full). Offer exactly three options:

- **Approve** → set `status: approved`, commit `docs: approve plan for #<n>`, then offer `landmark-implement`.
- **Revise** → take the changes, update the plan, re-present.
- **Abandon** → set `status: abandoned`, commit, offer to delete the branch.

Do not begin implementation in this phase, even if the user is enthusiastic. Hand off.
