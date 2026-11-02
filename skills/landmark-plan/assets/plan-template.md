---
issue: <n>
title: <title>
type: <feature | fix | chore | docs>
branch: <type>/<n>-<slug>
status: draft
created: <YYYY-MM-DD>
pr: ""
---

# <title>

Issue: #<n>

## Goal

One paragraph. What will be true when this is done that is not true now.

## Non-goals

What this unit of work deliberately does not do. Anything a reviewer might reasonably expect that is out of scope.

## Context

What the research pass found: relevant files, existing patterns to follow, constraints, prior art in the codebase. Link paths, not prose.

## Decisions

Each decision made during the interview, with the alternative rejected and why. These are the things that must not be re-litigated during implementation.

| # | Decision | Alternative considered | Reason |
| - | -------- | ---------------------- | ------ |
| 1 |          |                        |        |

## Design

How it will work. Data shapes, interfaces, control flow, error handling. Diagrams welcome. Detailed enough that implementation is transcription, not invention.

## Testing

What will be tested, at what level (unit / integration / end-to-end), and how. Include manual test steps if `dev_environment` applies.

## Steps

One checkbox per committable unit. Each step should leave the branch in a working state. Ordered so that tests exist before or alongside the code they test.

- [ ] 1. 
- [ ] 2. 
- [ ] 3. 

## Risks & open questions

Empty when the plan is approved, or each item is explicitly marked *accepted*.

## Implementation notes

Filled in during implementation. Deviations from the plan and why, each agreed with the user before proceeding.

## Review

Filled in during review. Reconciled findings, what was fixed, what became an issue, what was dismissed and why.
