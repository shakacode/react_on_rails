# Agent Workflow Adoption Guide

Use this guide to share the React on Rails agent workflows (the `pr-batch` family, PR
processing, review handling, post-merge audit, adversarial review, and related skills) with
another repository **and keep that repository updated as the workflows evolve**.

The model is a shared, vendored library, not a one-time copy:

- The portable workflow logic lives in one canonical upstream, `shakacode/agent-workflows`.
- Each consumer repo vendors it into `.agents/` with `git subtree` and pulls updates from
  the same upstream. The vendored tree is **byte-identical across repos and never edited
  in place**, so updates stay conflict-free.
- Every per-repo difference — commands, branch, labels, paths, policy — lives in one place
  in the consumer's `AGENTS.md`: the **Agent Workflow Configuration** section (the seam).

```
shakacode/agent-workflows            canonical upstream (skills/ + workflows/)
        │  git subtree
        ▼
consumer repo
  .agents/            vendored subtree — byte-identical, NEVER hand-edited
  .claude/skills → ../.agents/skills   per-repo glue (Claude Code slash commands)
  AGENTS.md           per-repo SEAM: Agent Workflow Configuration
```

> Do not edit files under `.agents/` in a consumer repo. Changes to shared workflow logic
> go to `shakacode/agent-workflows`, then flow back via a sync. Editing `.agents/` locally
> reintroduces the merge conflicts this model exists to avoid.

## One-time adoption

1. **Inventory the target repo.** Identify base branch, package managers, setup/build/lint/
   test/type-check/docs commands, the local change detector or equivalent, release
   boundaries, generated files, protected-branch requirements, review bots, and which
   checks are cheap locally vs reserved for hosted CI.

2. **Vendor the shared tree.** From the repo root:

   ```bash
   git subtree add --prefix=.agents https://github.com/shakacode/agent-workflows.git main --squash
   ```

   Or, once `.agents/bin/agent-workflows-sync` is present, just run it — it vendors on the
   first run and updates afterward.

3. **Expose skills to Claude Code** (if the repo uses it):

   ```bash
   ln -s ../.agents/skills .claude/skills
   ```

   Add optional `.claude/prompts/*.md` pointers only if the repo keeps Claude prompt
   aliases; have them link the canonical shared workflow rather than carry a second copy.

4. **Add the seam to `AGENTS.md`.** Add an `## Agent Workflow Configuration` section using
   the template below, filled with the target repo's real values. This is the only place
   the shared files resolve repo-specific values, so it must be complete.

5. **Make `AGENTS.md` the canonical policy.** It owns commands, testing, code style, git/PR
   safety, and documentation boundaries. Tool-specific files (e.g. `CLAUDE.md`) stay thin
   and link back. Remove React on Rails-specific rules (Ruby, Shakapacker, RSC, Pro) that do
   not apply.

6. **Validate with a dry run** (see Validation).

## The seam: `## Agent Workflow Configuration`

Copy this into the consumer's `AGENTS.md` and replace every value. The shared `.agents/`
files reference these by name ("the repo's local validation command", "the hosted-CI
trigger", etc.); if a value is missing here, the shared files cannot resolve it.

```markdown
## Agent Workflow Configuration

The shared `.agents/` skills and workflows are repo-agnostic and resolve every repo-specific
value through this section.

- **Base branch**: <main | master | …> (fetch/compare via `origin/<base>`).
- **Pre-push local validation**: <command an agent runs before pushing, e.g. `bin/ci-local`>.
- **CI change detector**: <command, or "n/a">.
- **Hosted-CI trigger**: <how an agent requests hosted CI: comment command, label, or n/a>.
- **Benchmark labels**: <labels, or "n/a">.
- **Follow-up issue prefix**: <e.g. `Follow-up:`>.
- **Changelog**: <path + policy + entry format, or "n/a">.
- **Lint / format**: <lint, autofix, and format-check commands>.
- **Build / type checks**: <build, type-check, signature-validation commands, or "n/a">.
- **Tests**: <unit / integration / e2e commands>.
- **Merge ledger**: <machine-checkable merge-readiness command, or "n/a">.
- **Review gate**: <preferred independent review check name, or "n/a">.
- **Approval-exempt change categories**: <categories allowed on trusted assignments>.
- **Coordination backend**: <shared backend for multi-batch work, or the public
  claim-comment fallback>.
```

Anything marked `n/a` simply means the matching shared guidance degrades to "do the
equivalent manually" — the workflow structure still transfers.

## Shared vs repo-local skills

The subtree is all-or-nothing for the `.agents/` prefix, so the upstream contains only
**portable** skills/workflows: `pr-batch`, `plan-pr-batch`, `plan-issue-triage`, `triage`,
`evaluate-issue`, `post-merge-audit`, `adversarial-pr-review`, `autoreview`,
`address-review`, `verify`, `verify-pr-fix`, `run-ci`, `update-changelog`, and the
`pr-processing` / `post-merge-audit` / `adversarial-pr-review` / `address-review` /
`continuous-evaluation-loop` / `evaluate-issue` workflows.

Genuinely repo-specific skills stay **out of the shared upstream** and local to their repo
(React on Rails keeps `stress-test`, a destructive RSC/SSR demo-workspace QA pass). A
consumer that receives an unused shared skill simply never invokes it.

## Keeping it updated

1. **Pull updates** with `.agents/bin/agent-workflows-sync` (wraps
   `git subtree pull --prefix=.agents … main --squash`, records the synced upstream SHA in
   `.agents/UPSTREAM`, and prints the post-sync checklist).
2. **Check `.agents/UPSTREAM`** to see which upstream SHA a repo is on.
3. **Run the validation gate** after each sync (markdown format + link check + skill `bin/`
   tests + a dry run).
4. **Never resolve a sync by editing `.agents/`.** If a pull conflicts, something edited the
   vendored tree locally — revert that edit and move the change upstream instead.

To change shared workflow logic: edit `shakacode/agent-workflows`, then sync each consumer.
To change a repo-specific value: edit only that repo's `AGENTS.md` seam.

## Repo-specific replacement checklist

Before considering adoption complete, confirm the seam and `AGENTS.md` define: base branch;
package managers; setup/build/lint/format/test/type-check/docs commands; local change
detector; hosted-CI trigger and labels; benchmark labels; follow-up prefix; changelog path,
policy, and entry format; merge ledger (if any); review gate; approval-exempt categories;
coordination backend; branch naming and merge strategy; required checks and branch-protection
exceptions; and which review bots may leave actionable feedback.

## What not to copy blindly

- React on Rails package paths (`react_on_rails/`, `packages/react-on-rails/`,
  `react_on_rails_pro/`) and Ruby/Rails/Shakapacker/RSC/Pro rules unless the repo uses them.
- Commands that do not exist in the target repo — set them in the seam instead.
- High-concurrency no-approval execution from arbitrary public filters. Require a
  maintainer-approved exact target list first.
- Coordination labels (`codex-ready`, etc.) unless the repo creates and defines them.
- Treating AI reviewer approvals or "no actionable comments" summaries as required maintainer
  approvals — they are advisory unless they identify a confirmed blocker.

## Cross-repo coordination (optional)

For multi-machine, multi-batch, or cross-repo work, also adopt
[`internal/contributor-info/agent-coordination-backend.md`](agent-coordination-backend.md)
and [`internal/contributor-info/multi-batch-operations.md`](multi-batch-operations.md).
ShakaCode-internal repos share the private `shakacode/agent-coordination` backend (claims and
heartbeats namespaced by full repo name). External adopters use the structured public
claim-comment fallback in
[`.agents/workflows/pr-processing.md`](../../.agents/workflows/pr-processing.md) until a
public backend spec is available.

## Validation

- Markdown formatting check and link check (this repo: `pnpm start format.listDifferent`,
  `bin/check-links`).
- Skill `bin/` unit tests under `.agents/skills/**/bin/*-test.*`.
- A dry run: ask an agent to run `$pr-batch` with a filter and confirm it stops with an exact
  target list and `/goal` prompt before spawning workers; ask it to triage one PR review and
  stop at the menu. Confirm it resolves the seam values (base branch, validation command,
  labels) and does not invent missing tooling.

## Suggested adoption PR summary

```markdown
## Summary

- vendor the shared agent workflows into `.agents/` via git subtree
- add the `## Agent Workflow Configuration` seam to `AGENTS.md` with this repo's values
- symlink `.claude/skills -> ../.agents/skills` for Claude Code (if used)
- document local validation and hosted-CI escalation for this repo

## Validation

- markdown formatting + link check
- skill bin tests
- dry-run `$pr-batch` and PR-review triage without code changes
```
