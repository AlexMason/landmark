# Project instructions

<!-- Describe the project here: what it is, how it is laid out, conventions
     an agent needs to know. Keep this section yours; Landmark only owns the
     settings block below. -->

## Landmark settings

This repository uses the Landmark process. Agents read this block before any
phase. The process itself ships with the `landmark-*` skills; if those are not
installed, see https://github.com/alexmason/landmark.

```yaml
landmark:
  version: "0.1.0"
  branching: gitflow            # gitflow (main + dev) | trunk (main only)
  default_branch: main          # production branch
  integration_branch: dev       # under trunk: same value as default_branch
  issue_tracker: github         # github | file — decided once by landmark-init
  merge_strategy: squash        # squash | merge | rebase
  test_command: ""              # e.g. "npm test"; empty means none configured
  coverage_command: ""          # optional, e.g. "npm run coverage"
  dev_environment: ""           # (re)build + start local services, e.g. "docker compose up -d --build"
  manual_test_url: ""           # optional, e.g. http://localhost:3000
```

Non-negotiables regardless of harness:

- All work is on `<type>/<n>-<slug>` branches off the integration branch. PRs target the integration branch. The integration → production merge is a human decision.
- Every unit of work has an issue and a plan under `docs/plans/`.
- When a required tool is missing or a step cannot be done as written, stop and say so. Do not improvise a workaround without explicit approval.
