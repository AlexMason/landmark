# Installing Landmark

This file is written for the agent doing the install. If you are a human, you can follow it too, but the fastest path is to tell your agent: *"Read INSTALL.md and install Landmark."*

## What you are installing

Seven skills in the [Agent Skills](https://agentskills.io) format, found under `skills/`. Each skill is a directory containing a `SKILL.md` plus any templates or references it needs. Skills are self-contained; they do not reference each other's files.

Installation is **user-level** (global to the harness), not per-project. A project gets only an `AGENTS.md` and a `docs/` folder, which `landmark-init` creates later.

## Rule for this install

If a step below cannot be completed as written (a command is missing, a path does not exist, a permission is denied), **stop and report it**. Offer the documented alternative if there is one. Do not improvise a different install method without the user's explicit approval.

## Step 1: Identify the harness

Determine which harness you are running in. If you cannot tell, ask the user. The user may want more than one harness set up; do them in sequence.

## Step 2: Install the skills

### Preferred: Skills CLI (any harness)

```sh
npx skills add <owner>/landmark
```

This copies every skill under `skills/` into the harness's user-level skills directory. Use `-a <agent>` to target specific harnesses, e.g. `-a claude-code -a codex`. Requires Node.js; if `npx` is unavailable, use the manual path below (that is a documented alternative, not a workaround).

### Manual: copy the skill directories

Copy each directory under `skills/` into the harness's user-level skills location:

| Harness          | User-level skills directory                 | Notes |
| ---------------- | ------------------------------------------- | ----- |
| Claude Code      | `~/.claude/skills/<skill-name>/SKILL.md`    | Project-level alternative: `.claude/skills/`. |
| oh-my-pi (omp)   | `~/.omp/agent/skills/<skill-name>/SKILL.md` | Project-level alternative: `.omp/skills/`. omp also discovers skills installed for other harnesses (`~/.claude/skills`, `~/.agents/skills`, …), so a Claude Code install is picked up with no extra step. |
| Pi (upstream)    | `~/.pi/agent/skills/<skill-name>/SKILL.md`  | Project-level alternative: `.pi/skills/`. |
| OpenAI Codex CLI | `~/.agents/skills/<skill-name>/SKILL.md`    | Project-level alternative: `.agents/skills/`. |
| Other            | See your harness's documentation for its Agent Skills directory. | If the harness does not read `SKILL.md` at all, see the fallback below. |

Copy the whole directory, not just `SKILL.md`; several skills carry `assets/` or `references/`.

### Fallback: harness without skill support

Give the agent `docs/process.md` as a context or rules file. It is the full process in one document. You lose per-phase invocation, but the agent will still follow the workflow.

## Step 3: Verify

Start (or restart) the harness so it rescans skills, then confirm the seven `landmark-*` skills are discoverable. In most harnesses, typing `/landmark-status` in any directory is enough; it should load and report that no plans were found.

## Step 4: Initialize a repository

In the project you want to work on:

```
/landmark-init
```

This is idempotent. It will:

- initialize Git if needed and tell the user it did so,
- ensure `main` and `dev` exist,
- create `docs/plans/`,
- create or extend `AGENTS.md` with a Landmark settings block (asking about test and dev-environment commands),
- add a `CLAUDE.md` shim containing `@AGENTS.md` for Claude Code (other harnesses read `AGENTS.md` directly).

## Updating

Re-run Step 2. Then, in each repo, run `/landmark-init` again; it will update the `version` field in the settings block and leave everything else alone.

## Report back

When done, tell the user:

- which harness(es) you installed into and where the files went,
- whether verification succeeded,
- anything you could not do and why.
