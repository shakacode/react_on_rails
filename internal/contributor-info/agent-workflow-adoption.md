# Agent Workflow Adoption Guide

Use this guide when another repository wants to adopt the React on Rails agent workflow conventions for assigned issues, PR processing, review-comment handling, local validation, and CI backpressure.

The goal is not to copy React on Rails blindly. The goal is to copy the reusable workflow structure, then replace every project-specific command, label, path, and boundary with the target repository's real rules.

## Source Files To Copy

### Required baseline

- [AGENTS.md](../../AGENTS.md) - canonical agent entry point and repository policy.
- [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md) - default flow for assigned issues, existing PRs, review-fix passes, and multi-PR landing plans.
- [.agents/workflows/address-review.md](../../.agents/workflows/address-review.md) - generic non-Claude review-comment triage and fixing workflow.
- [.agents/skills/autoreview/SKILL.md](../../.agents/skills/autoreview/SKILL.md) - independent review skill used before commits, pushes, PRs, or merge readiness.

### Claude support

Copy these when the target repo uses Claude Code:

- [.agents/skills/address-review/SKILL.md](../../.agents/skills/address-review/SKILL.md) - shared address-review skill exposed to Claude Code as `/address-review`.
- [.claude/prompts/address-review.md](../../.claude/prompts/address-review.md) - optional compatibility pointer to the canonical reusable prompt; copy it only if the target repo keeps Claude prompt aliases.
- `.claude/skills -> ../.agents/skills` - symlink that lets Claude Code load the shared agent skills.

Keep the shared skill and `.agents/workflows/address-review.md` behavior aligned. If the target repo also copies a reusable prompt file, make it point at the canonical shared workflow instead of carrying a second full workflow copy. Tool syntax can differ; policy should not.

### Optional CI command workflow

Copy these only when the target repo wants PR-comment commands such as `+ci-run-full`, `+ci-stop-full`, `+ci-status`, and `+ci-skip-full`:

- [.github/read-me.md](../../.github/read-me.md) - maintainer-facing explanation of the CI command workflow.
- [.github/workflows/ci-commands.yml](../../.github/workflows/ci-commands.yml) - comment-command handler.
- [.github/actions/check-full-ci-label/action.yml](../../.github/actions/check-full-ci-label/action.yml) - helper used by workflows that react to the `full-ci` label.

Do not copy the CI workflow files as a bundle unless the target repo has the same workflow names, labels, permissions, and matrix strategy. Treat these files as implementation examples to adapt.

## Adoption Steps

1. Inventory the target repo.
   - Identify the base branch, package managers, lint commands, test commands, type checks, docs checks, release boundaries, generated files, and protected-branch requirements.
   - Identify which checks are cheap enough to run locally and which checks should be reserved for final CI.

2. Install the baseline docs.
   - Add or replace `AGENTS.md`.
   - Add `.agents/workflows/pr-processing.md`.
   - Add `.agents/workflows/address-review.md`.
   - Add `.agents/skills/autoreview/SKILL.md`, or replace the pre-push AI review gate with the target repo's direct review command.
   - Add Claude files only if Claude Code is used in that repo.

3. Rewrite `AGENTS.md` first.
   - Make it the canonical source for commands, testing, code style, git safety, PR policy, and documentation boundaries.
   - Remove React on Rails-specific package names, paths, Pro references, Shakapacker commands, and RSC guidance unless they truly apply.
   - Add only stable rules. Put temporary plans in planning docs, not in `AGENTS.md`.

4. Customize the PR processing workflow.
   - Replace `script/ci-changes-detector origin/main`, `bin/ci-local`, and the targeted command list with the target repo's real local validation commands.
   - Keep the self-review gate, reproduction/TDD gate, local-validation-first policy, batched pushes, and follow-up issue restraint.
   - Define the repo's high-risk categories so agents know when full CI or extra review is justified.
   - Treat high-risk categories (workflow, build-config, lockfiles, release tooling) as "Ask First" scope, not standing bans. Make any explicit grant or per-run prohibition a batch-prompt scope field so temporary lane restrictions are never inherited as permanent policy, and so the absence of a later prohibition never implies permission without a fresh grant.

5. Customize address-review behavior.
   - Keep the summary marker `<!-- address-review-summary -->` unless the repo already has a different checkpoint marker.
   - Keep the tiers: `MUST-FIX`, `DISCUSS`, `OPTIONAL`, and `SKIPPED`.
   - Keep `autopilot` as an initiation mode and `a` as the post-triage apply action.
   - Update bot assumptions, reviewer names, and any repo-specific reply or resolution rules.

6. Decide whether to adopt CI comment commands.
   - If adopted, create the labels the workflow expects, especially `full-ci`.
   - Update the workflow map in `ci-commands.yml` so it dispatches the target repo's actual expensive workflows.
   - Ensure each expensive workflow knows how to react to `full-ci` or manual dispatch.
   - If not adopted, remove `+ci-*` language from `AGENTS.md` and `pr-processing.md`, and replace it with the target repo's real full-CI trigger.

7. Validate with a dry run.
   - Ask an agent to process a low-risk issue and stop before opening a PR.
   - Ask an agent to triage one PR review and stop at the quick-action menu.
   - Confirm the agent uses the target repo's commands, does not invent missing tooling, does not create follow-up issues by default, and does not push before local validation.

## Repo-Specific Replacement Checklist

Update these before considering the workflow adopted:

- Base branch name: `main`, `master`, or another default branch.
- Package managers: `pnpm`, `npm`, `yarn`, `bundle`, `cargo`, `go`, `pip`, or project-specific wrappers.
- Local setup command.
- Build command.
- Lint commands.
- Unit, integration, E2E, type-check, docs, and workflow-lint commands.
- Local change detector or equivalent path-based CI guidance.
- Manual developer-flow checks for app startup, generated apps, examples, or test fixtures.
- PR labels such as `full-ci`, `benchmark`, and `ready-to-merge`.
- Full-CI trigger mechanism if `+ci-*` is not installed.
- Follow-up issue title convention. React on Rails uses `Follow-up:`.
- Documentation boundaries: public docs, internal docs, generated docs, changelog policy.
- Branch naming and merge strategy.
- Review bots and which ones can leave actionable feedback.
- Required checks and branch-protection exceptions.
- Tool-specific docs that must link back to `AGENTS.md`.

## What Not To Copy Blindly

- React on Rails package paths such as `react_on_rails/`, `packages/react-on-rails/`, and `react_on_rails_pro/`.
- Ruby, Rails, Shakapacker, RSC, SSR, and Pro-specific rules unless the target repo uses those concepts.
- Commands that do not exist in the target repo.
- The `+ci-*` workflow without adapting workflow names, permissions, labels, and dispatch inputs.
- Follow-up issue creation habits. The default should remain no new issue unless the user explicitly chooses bundled tracking.
- PR labels that are not created and documented in the target repo.

## Sync Policy

`AGENTS.md` should remain the policy source of truth in each repo. Tool-specific files should be thin wrappers or prompt forms that link back to the same policy.

When changing policy:

1. Update `AGENTS.md`.
2. Update `.agents/workflows/pr-processing.md` and `.agents/workflows/address-review.md`.
3. Update Claude skill or prompt files if they exist.
4. Run Markdown formatting and link checks.
5. Do one dry-run triage or PR-processing pass before declaring the copied workflow ready.

## Suggested Adoption PR Summary

```markdown
## Summary

- add canonical agent instructions in `AGENTS.md`
- add reusable PR processing and address-review workflows under `.agents/workflows/`
- add Claude skill/prompt support for the same review flow
- document local validation and full-CI escalation rules for this repository

## Validation

- markdown formatting check
- markdown link check
- dry-run issue or PR triage without code changes
```
