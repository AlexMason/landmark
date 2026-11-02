---
name: landmark-init
description: Bootstrap a repository for the Landmark process. Initializes Git if needed, ensures the production and integration branches, creates docs/plans/, and adds or updates the Landmark settings block in AGENTS.md. Idempotent; safe on existing repos. Use when the user says "init landmark", "set up landmark here", or a landmark skill reports the repo is not initialized.
---

# landmark-init

Bootstrap the current repository for the Landmark process. Run once per repo; re-run to upgrade the recorded version.

## Rule

If any step cannot be completed as written, stop, say exactly what is missing, and offer the documented alternative. Do not improvise.

## Steps

### 1. Check tools

- `git --version` must succeed and report 2.5 or newer (Landmark implements in Git worktrees). If not: **stop**. Git with worktree support is required; there is no alternative.
- `gh` is tested in step 3, once the remote is known.

### 2. Ensure a repository

- Not inside a Git repository → `git init -b main`. If `-b` is unsupported (Git < 2.28), run `git init` then `git symbolic-ref HEAD refs/heads/main`. Tell the user you initialized Git and why (Landmark requires all work to be versioned).
- Already inside one → do nothing here. Note the current branch. If there are uncommitted changes, warn the user and proceed without touching them.

### 3. Test the remote and `gh` access

When a Git remote exists, `gh` is the interface to it for the rest of the process. Verify that it works now, while the user is present to fix it. On a re-run where `AGENTS.md` already has a settings block, test only if its `issue_tracker` is `github`; a stored `file` stands.

- `git remote -v`. Use `origin`; if there is no `origin` but other remotes, ask which one.
- No remote → skip the test; `issue_tracker` will be `file`. Tell the user why.
- Remote host is not GitHub (e.g. `gitlab.com`, `bitbucket.org`) → skip the test; `issue_tracker` will be `file`. Tell the user why.
- Otherwise run all three, in order, against the remote's host and `<owner>/<repo>`:
  1. `gh --version`
  2. `gh auth status --hostname <host>`
  3. `gh repo view <owner>/<repo>`
- All pass → `gh` is verified.
- Any fails → **stop**. Show which check failed and its output. Offer: fix it (install `gh`, run `gh auth login`, or create the repository on the remote) and re-run init; or explicitly choose `issue_tracker: file` for this repo. Do not pick for the user and do not continue with `github` unverified.

### 4. Determine settings

If `AGENTS.md` already has a `## Landmark settings` block, read it; those values stand and only `version` will change. Otherwise ask the user, in one batch:

1. **Branching** — `gitflow` (`main` + `dev`, the default) or `trunk` (one branch)?
2. **`test_command`** — how to run the test suite (empty if none yet).
3. **`coverage_command`** — optional.
4. **`dev_environment`** — the command that rebuilds and starts local services, if any.
5. **`manual_test_url`** — optional.

Derive the rest:

- `default_branch` — the repo's existing production branch name. Use `main` if it exists or the repo is new. If the repo uses another name (e.g. `master`), **do not rename it**; ask whether to treat it as production and record that name.
- `integration_branch` — `dev` under gitflow; the same value as `default_branch` under trunk.
- `issue_tracker` — `github` if step 3 verified `gh` access to a GitHub remote; `file` if there is no remote or it is not on GitHub (or the user explicitly chose `file` after a step 3 failure). Tell the user which and why.
- `merge_strategy` — `squash` unless the user says otherwise.

### 5. Write the files

**`docs/plans/`** — create it, with a `.gitkeep` if empty.

**`AGENTS.md`** — read `assets/AGENTS.md` in this skill's directory, then:

- no `AGENTS.md` → copy the asset in full;
- exists without a `## Landmark settings` section → append that section only (from the heading to the end of the asset), leaving existing content untouched;
- exists with a settings block → update only `version`.

Fill every key in the block from step 3. Write all keys explicitly, including `branching` and `integration_branch`; downstream skills read them literally.

**`CLAUDE.md`** — if absent, create it containing exactly `@AGENTS.md`. If present without a reference to `AGENTS.md`, append the line and tell the user. Other harnesses read `AGENTS.md` directly; create nothing else harness-specific.

**`docs/ISSUES.md`** — do not create it here. `landmark-issue` creates it on first use in file mode.

### 6. Commit and create branches

1. If the integration branch exists, check it out (sync it first: `git pull --ff-only` only if it has an upstream). Otherwise stay on `default_branch`.
2. Commit the bootstrap: `chore: initialize Landmark <version>`. On a brand-new repo this is the first commit.
3. Under gitflow, if `dev` does not exist: `git checkout -b dev` from the branch you just committed on. If a remote exists, `git push -u origin dev`.
4. Return to the branch the user was on, if it was something else.

### 7. Report

Tell the user:

- whether Git was initialized,
- which branches exist and which is the integration branch,
- the settings block as written,
- what `issue_tracker` was chosen and why, including the result of the `gh` access test when a remote exists.

Then offer: "Start with `landmark-issue` to capture the first unit of work?"
