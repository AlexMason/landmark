---
name: landmark-issue
description: Capture a unit of work as an issue — current state and desired state only, no design. Creates a GitHub issue when the repo's Landmark settings say issue_tracker is github, otherwise appends to docs/ISSUES.md. Use when the user describes a bug, feature, or task that is not yet tracked, or says "create an issue", "track this", "log this".
---

# landmark-issue

Record *what* and *why*. Not *how*. Design belongs in `landmark-plan`.

## Preconditions

1. Read the `## Landmark settings` block in `AGENTS.md`. If absent, **stop** and suggest `landmark-init`.
2. Note `issue_tracker` (`github` | `file`) and `integration_branch`. Do not re-detect; the settings are authoritative.

## Rule

If any step cannot be completed as written, stop, say what is missing, and offer the documented alternative. Do not improvise.

## Steps

### 1. Gather the four fields

From what the user has said, draft:

- **Title** — one line, imperative or noun phrase.
- **Type** — `feature` | `fix` | `chore` | `docs`.
- **Current state** — what happens today, concretely. For a bug: how to reproduce.
- **Desired state** — what should happen instead, concretely. Acceptance criteria if the user can give them.

Ask only for what is genuinely missing or ambiguous, in one batch. Do not research the codebase here beyond what is needed to describe current state accurately (e.g. confirming a file or command the user named exists). Do not propose solutions. If the user starts designing, capture a one-line pointer under desired state ("user suggests X; evaluate in planning") and move on.

### 2. Duplicate check

- `github`: `gh issue list --state open --search "<key terms>"`.
- `file`: search `docs/ISSUES.md` for the key terms.

If a likely duplicate exists, show it and ask whether to add to it instead of creating a new one.

### 3. Create

**`issue_tracker: github`**

```
gh label create <type> 2>/dev/null || true
gh issue create --title "<title>" --label "<type>" --body "<body>"
```

Body format:

```
## Current state
...

## Desired state
...
```

If `gh` fails for auth or permission reasons, **stop** and offer two alternatives: fix auth and retry, or switch this repo to `issue_tracker: file` (edit the settings block, tell the user, then continue below).

**`issue_tracker: file`**

Use the integration-branch procedure so tracker edits never land on a feature branch:

1. `git stash --include-untracked` **only if** the working tree is dirty. Note the branch you are on.
2. `git checkout <integration_branch>`; `git pull --ff-only` only if it has an upstream.
3. If `docs/ISSUES.md` does not exist, create it from `assets/ISSUES.md` in this skill's directory.
4. Read `Next ID: <n>`. Use `<n>` as the issue number; increment the counter.
5. Append an entry under `## Open` in the commented example's format, `Status: open`, today's date, `Plan:` left blank.
6. Commit: `docs: open issue #<n> — <title>`. Push only if the branch has an upstream.
7. `git checkout -` back to the original branch; `git stash pop` if you stashed.

### 4. Report and hand off

Show the issue number and link (or file path). Then offer:

> Plan it now with `landmark-plan`?
