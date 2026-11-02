---
name: landmark-status
description: Report where every Landmark unit of work stands — reads docs/plans/ frontmatter, the current branch, and open issues, and names the next skill to run. Use when the user asks "where was I", "what's in progress", "landmark status", or when resuming work in a new session or harness.
---

# landmark-status

Read-only. Tells any agent, in any harness, where things stand and what to do next.

## Steps

### 1. Settings

Read the `## Landmark settings` block in `AGENTS.md`. If absent, report *"Landmark is not initialized here"* and suggest `landmark-init`. Stop.

### 2. Plans

List `docs/plans/*.md`. Treat only files whose frontmatter has an `issue:` key as plans; ignore the rest. For each plan, read `issue`, `title`, `branch`, `status`, `pr`. For plans with `status: implementing`, also count ticked vs. total **Steps**. For `in-review`, note the `Mode:` line under **Review** if present.

If `docs/plans/` is empty or missing, say so. If `docs/reviews/` contains files, mention them: each is a user-driven review in progress.

### 3. Git

- Current branch, and whether it matches any plan's `branch`.
- Uncommitted changes (`git status --porcelain`), yes/no.
- Whether the current branch is behind the integration branch (`git rev-list --count HEAD..<integration_branch>`; `git fetch` first only if a remote exists).

### 4. Issues without plans

- `github`: `gh issue list --state open` and subtract issues that have a plan.
- `file`: entries under `## Open` in `docs/ISSUES.md` with `Status: open`.

If the tracker cannot be read (no `gh`, no file), say so and skip; this is informational.

### 5. Report

A short table, one row per plan, then the git facts, then unplanned issues. Highlight the plan matching the current branch. For each plan, name the next action from this map:

| `status`       | Next                                                         |
| -------------- | ------------------------------------------------------------ |
| `draft`        | Review the plan; approve it in `landmark-plan`.              |
| `approved`     | `landmark-implement`                                         |
| `implementing` | `landmark-implement` (resumes at step *i*/*total*)           |
| `implemented`  | `landmark-review`                                            |
| `in-review`    | `landmark-review` (resume; check the plan's Review section)  |
| `reviewed`     | `landmark-file`                                              |
| `filed`        | Merge the PR, or wait. Delete the branch once merged.        |
| `abandoned`    | Nothing. Delete the branch if it still exists.               |

End with one sentence: the single most likely next step for the user, given the current branch.
