---
name: landmark-file
description: Run tests and coverage, bring the branch up to date, and open the PR against the integration branch (or present a local "PR" for acceptance and merge it when there is no GitHub tracker). Never merges to production. Use when the user says "file it", "open the PR", "ship it", or a plan has status reviewed.
---

# landmark-file

Prove it, then open the PR. The integration → production merge is never this skill's job.

## Preconditions

1. Read the `## Landmark settings` block in `AGENTS.md`. If absent, **stop** and suggest `landmark-init`. Note `issue_tracker`, `integration_branch`, `default_branch`, `merge_strategy`.
2. Locate the plan (named, or the single plan with `status: reviewed`; ask if several; **stop** if none).
3. Validate `status`: `reviewed` → proceed. Anything else → **stop** and explain. The user may override ("file it anyway"); if so, add `Filed without review sign-off at user's request` under the plan's **Review** section before continuing.
4. `git checkout <branch>`. If the working tree is dirty, **stop** and ask.

## Rule

If a step cannot be completed as written, stop, say what is missing, and offer the documented alternative. Do not improvise.

## Steps

### 1. Prove it

Run, in order, and **stop on any failure**:

1. `test_command`. If it is empty, say so and ask the user to confirm filing without automated tests; proceed only on an explicit yes.
2. `coverage_command`, if set. Report the number. Landmark enforces no threshold of its own; if the coverage tool fails because the project configured one, that is a failure like any other.

Do not fix failures here by weakening tests. Fix the code on the branch (`fix: ... (#<n>)`), re-run, or return to review if the fix is non-trivial.

### 2. Bring the branch up to date

```
git fetch                                  # only if a remote exists
git rebase <integration_branch>            # merge_strategy: squash | rebase
git merge  <integration_branch>            # merge_strategy: merge
```

Use `origin/<integration_branch>` when a remote exists. Conflicts are a **stop**: show them, propose resolutions, get agreement, resolve, re-run `test_command`.

### 3. Mark filed, then file

The `filed` state must travel with the branch into the integration branch, so it is committed **before** the PR or merge.

**`issue_tracker: github`**

1. Set `status: filed` (leave `pr: ""`). Commit `docs: #<n> filed`. `git push -u origin <branch>`.
2. Build the PR body from the plan:

   ```
   Closes #<n>

   ## Goal
   <plan Goal>

   ## Decisions
   <plan Decisions table>

   ## Testing
   <what was run and results; manual test steps>

   ## Review
   <summary of the Review section: findings fixed, issues opened>

   Plan: docs/plans/<file>
   ```

3. `gh pr create --base <integration_branch> --title "<type>: <title> (#<n>)" --body-file <tmp>`.
4. Write the PR URL into the plan's `pr:` field. Commit `docs: #<n> PR link`. Push.

If `gh` fails (missing, unauthenticated, no permission), **stop** and offer: fix auth and retry, or leave the branch pushed and give the user the compare URL (`https://github.com/<org>/<repo>/compare/<integration_branch>...<branch>`) to open the PR themselves; in that case ask for the URL back and record it.

**`issue_tracker: file`**

1. Set `status: filed` and `pr: local`. Commit `docs: #<n> filed`.
2. The "PR" is a message to the user: the title, the body above, `git log <integration_branch>..<branch> --oneline`, `git diff <integration_branch>...<branch> --stat`, and the test results. Ask: **accept** or **changes requested**.
3. On **accept**: `git checkout <integration_branch>`; merge per `merge_strategy` (`git merge --squash <branch>` + commit with the PR title | `git merge --no-ff <branch>` | `git rebase` already done → `git merge --ff-only <branch>`). Then move the issue from **Open** to **Closed** in `docs/ISSUES.md` with `Status: done`; commit `docs: close issue #<n>`. Push only if the branch has an upstream.
4. On **changes requested**: set `status` back to `implemented` or `in-review` as appropriate, commit, and hand off to `landmark-implement` or `landmark-review`.

### 4. Report and stop

Tell the user: PR link (or merge result), test and coverage results, anything skipped and why.

Then:

- Merge a GitHub PR **only if the user asks**: `gh pr merge --<merge_strategy> --delete-branch`.
- Help create the `<integration_branch>` → `<default_branch>` PR **only if the user asks**. Never open it on your own initiative; that merge is a human decision.
- After any merge, offer to delete the local feature branch.
