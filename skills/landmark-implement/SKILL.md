---
name: landmark-implement
description: Execute an approved Landmark plan step by step in a dedicated Git worktree — one commit per step, plan checkboxes ticked as you go, deviations agreed before proceeding. Use when the user says "implement", "build it", "start the plan", or a plan has status approved or implementing.
---

# landmark-implement

Work the plan. Do not redesign it.

## Preconditions

1. Read the `## Landmark settings` block in `AGENTS.md`. If absent, **stop** and suggest `landmark-init`.
2. Locate the plan: the one the user named, or the single plan in `docs/plans/` with `status: approved` or `implementing`. If there are several, ask which. If there are none, **stop** and suggest `landmark-plan`.
3. Validate `status`:
   - `approved` → fresh start.
   - `implementing` → resume at the first unchecked step.
   - anything else → **stop** and explain what phase the plan is in.
4. Get the branch's worktree. `<branch>` is from the plan's frontmatter; `<path>` is `../<repo>.worktrees/<branch with / replaced by ->`, a sibling of the main checkout (`<repo>` is its directory name).
   - `git worktree list --porcelain` already lists `<branch>` → use that worktree.
   - Otherwise: if `<branch>` does not exist locally, `git fetch` and try again; if still missing, **stop**. If the main checkout (first entry of `git worktree list`) has `<branch>` checked out, **stop** and ask when it has uncommitted changes; otherwise `git checkout <integration_branch>` there, because a branch can be checked out in only one place. Then `git worktree add <path> <branch>`.
   - If `git worktree` is unavailable (Git older than 2.5), **stop**; upgrade Git. There is no alternative.
5. Do all remaining work in the worktree: run every command with it as the working directory, never in the main checkout. If the worktree has uncommitted changes, **stop** and ask. A fresh worktree contains only tracked files; if tests or `dev_environment` fail because untracked files (dependencies, `.env`) are missing, **stop** and ask how to provision them.

## Rule

If a step cannot be done as planned, or a required tool is missing, stop and say so. Do not improvise a workaround or quietly change the design.

## Steps

### 1. Mark in progress

Set `status: implementing` in the plan frontmatter. Commit: `docs: start implementing #<n>`.

If `test_command` is empty, say so once now. The plan's **Testing** section then defines how each step is checked; follow it.

### 2. Work each step, in order

For each unchecked item under **Steps**:

1. Re-read the plan's **Design** and **Decisions** for anything that bears on this step.
2. Implement it. Follow the patterns the plan's **Context** identified.
3. Run the relevant tests (`test_command`, scoped to the affected area where the runner allows; or the plan's stated check if there is no runner). A failing test the step was supposed to make pass is a bug in the step, not a reason to skip the test.
4. Tick the checkbox in the plan file.
5. Commit the code **and** the plan edit together:

   ```
   <type>: <summary> (#<n> step <i>/<total>)
   ```

   One step, one commit. Do not batch steps. Do not split a step across commits unless the plan is amended to split the step.

### 3. The deviation rule

If, during a step, the plan turns out to be wrong or incomplete — a hook point does not exist, a decision conflicts with reality, a step is much larger than it looked:

1. **Stop** before writing further code.
2. Explain the problem and propose an amendment: changed design, changed steps, or a decision to revisit.
3. Get the user's agreement.
4. Update the plan: edit the affected sections and add an entry under **Implementation notes** (what changed, why, date).
5. Commit `docs: amend plan for #<n> — <reason>`, then continue.

Never silently diverge from the plan. The plan is what reviewers will check the diff against.

### 4. Keep the dev environment honest

If `dev_environment` is set, run it after any step that changes runtime behavior, so the user can poke at it. After each such step, give short manual-test instructions: what to open (`manual_test_url` if set), what to do, what they should see. Seeding a local database for a specific scenario is fine and should be described.

If `dev_environment` is set but the command fails, **stop** and report; do not continue implementing against a broken environment without the user saying so.

### 5. Finish

When every step is ticked:

1. Run the full `test_command` (or the plan's stated check). If it fails, fix on the branch (commit as `fix: ... (#<n>)`) before proceeding.
2. Set `status: implemented`. Commit: `docs: #<n> implemented`.
3. Report: the worktree path, what changed (by step), test results, manual-test steps.
4. Do **not** open a PR. Do **not** remove the worktree; review and filing use it. Offer: "Run `landmark-review`?"
