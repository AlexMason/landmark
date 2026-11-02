---
name: landmark-review
description: Review an implemented Landmark branch with three fresh-context reviewers (plan conformance & correctness, code quality, security & scalability), reconcile their findings, fix or file them, then hand the user a running environment for manual review. Use when the user says "review", "code review", or a plan has status implemented or in-review.
---

# landmark-review

Independent eyes on the diff before it leaves the branch. The reviewers must not share context with the agent that wrote the code.

## Preconditions

1. Read the `## Landmark settings` block in `AGENTS.md`. If absent, **stop** and suggest `landmark-init`.
2. Locate the plan (named by the user, or the single plan with `status: implemented` or `in-review`; ask if several; **stop** if none).
3. Validate `status`: `implemented` → fresh review; `in-review` → read the plan's **Review** section, which records the mode chosen and how far it got, and resume there (if the section is empty, start at step 2); anything else → **stop** and explain.
4. `git checkout <branch>`. If the working tree is dirty, **stop** and ask the user to commit or stash.

## Rule

If a step cannot be completed as written, stop, say what is missing, and offer the documented alternative. Do not improvise.

## Steps

### 1. Mark in review

Set `status: in-review`. Commit: `docs: #<n> in review`.

### 2. Capability check — can this harness spawn fresh-context sub-agents?

Determine honestly whether you have a tool that runs a separate agent with its own context (a sub-agent, task, or worker tool) and returns its output.

**Yes →** record `Mode: sub-agents` under the plan's **Review** section, commit `docs: #<n> review started`, and proceed to step 3.

**No →** **stop** and offer these documented alternatives, in order of preference. Do not pick one for the user. Once chosen, record `Mode: <a|b|c>` under **Review** and commit before doing anything else, so a resumed session knows what was started.

- **(a) Shell-driven.** If the harness has a non-interactive mode invokable from the shell (a `-p`/`--prompt` flag or similar), write each lens prompt to a temp file outside the repo and run three separate invocations, collecting their output. Continue at step 4.
- **(b) User-driven.** Write the three filled-in lens prompts to `docs/reviews/<plan-basename>.md` (create the directory), commit it, and ask the user to run each in a fresh session and paste the findings back. End the turn. When the findings arrive — possibly in a new session — resume at step 4; delete the prompts file at step 5.
- **(c) Same-context self-review.** Only if the user explicitly accepts the lower confidence. Review each lens yourself and label every finding *"self-review, same context"* in the plan. Continue at step 4.

### 3. Dispatch three reviewers

Read `references/lenses.md` in this skill's directory. For each lens (A, B, C), build the prompt from the common preamble plus that lens, filling in:

- `{plan_path}` — the plan file
- `{branch}` — from the plan's frontmatter
- `{base_branch}` — `integration_branch` from settings

Give each reviewer **nothing else**: not the implementation conversation, not your own opinion of the code. Run the three in parallel where the harness allows.

### 4. Reconcile

Merge the three result sets:

1. **Deduplicate.** Same location + same claim → one finding, note which lenses raised it (multi-lens agreement raises confidence).
2. **Resolve contradictions.** If reviewers disagree, read the code yourself and decide; record the reasoning.
3. **Verify blockers and majors** by reading the cited code. Downgrade or drop anything the reviewer marked unverified that you cannot confirm.
4. **Classify** each finding:
   - *Related* — caused by or within the scope of this PR.
   - *Unrelated but important* — pre-existing, discovered incidentally.
   - *Dismissed* — wrong, or a deliberate decision recorded in the plan (cite it).

### 5. Present and act

Show the user the reconciled list, grouped by classification, ordered by severity.

- For each **related** finding, offer to fix now. Each fix is its own commit: `fix: <summary> (#<n> review)`. Re-run tests after fixes.
- For each **unrelated** finding, offer to open an issue with `landmark-issue` (current state = the finding, desired state = the suggestion). Invoke it if the harness lets skills call skills; otherwise list the issues to open and let the user run it.
- Record everything — findings, fixes, issues opened, dismissals with reasons — under the plan's **Review** section. If `docs/reviews/<plan-basename>.md` exists, delete it. Commit: `docs: #<n> review findings`.

### 6. Hand over for manual review

If `dev_environment` is set:

1. Run it so services reflect the reviewed branch (rebuild, not just restart).
2. Confirm they are up (a health check, a curl, a log line — whatever the project offers).
3. Give the user the manual-test steps from the plan's **Testing** section and `manual_test_url`.

If it is not set, give the manual-test steps anyway and say the environment is theirs to bring up.

Then **wait**. Do not proceed to filing until the user says the manual review is done.

### 7. Sign off

On the user's confirmation: set `status: reviewed`, commit `docs: #<n> reviewed`, and offer: "File it with `landmark-file`?"

If the user finds problems during manual review, treat them as related findings: fix, commit, return to step 6.
