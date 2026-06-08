# Agent Workflow Adoption Guide

Use this guide when another repository wants to adopt the React on Rails agent workflow conventions for assigned issues, PR processing, review-comment handling, local validation, and CI backpressure.

The goal is not to copy React on Rails blindly. The goal is to copy the reusable workflow structure, then replace every project-specific command, label, path, and boundary with the target repository's real rules.

## Source Files To Copy

### Required baseline

- [AGENTS.md](../../AGENTS.md) - canonical agent entry point and repository policy.
- [.agents/skills/pr-batch/SKILL.md](../../.agents/skills/pr-batch/SKILL.md) - memorable entry point for multi-issue or multi-PR batches; interviews for missing targets, trust, permissions, concurrency, and `/goal` handoff details.
- [.agents/skills/post-merge-audit/SKILL.md](../../.agents/skills/post-merge-audit/SKILL.md) - post-merge batch audit workflow for missed review gates, missing changelog entries, cross-PR interactions, and release risk.
- [.agents/skills/adversarial-pr-review/SKILL.md](../../.agents/skills/adversarial-pr-review/SKILL.md) - skeptical pre-merge or post-merge PR review gate for release risk, missed review comments, changelog gaps, and Codex/Claude comparison.
- [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md) - default flow for assigned issues, existing PRs, review-fix passes, and multi-PR landing plans.
- [.agents/workflows/post-merge-audit.md](../../.agents/workflows/post-merge-audit.md) - reusable prompts for completed-batch handoffs, independent Codex/Claude audits, comparison, approved issue creation, and Claude PR review handoffs.
- [.agents/workflows/adversarial-pr-review.md](../../.agents/workflows/adversarial-pr-review.md) - reusable prompts for independent adversarial PR reviews and Codex/Claude comparison.
- [.agents/workflows/address-review.md](../../.agents/workflows/address-review.md) - generic non-Claude review-comment triage and fixing workflow.
- [.agents/skills/autoreview/SKILL.md](../../.agents/skills/autoreview/SKILL.md) - independent review skill used before commits, pushes, PRs, or merge readiness.

### Claude support

Copy these when the target repo uses Claude Code:

- [.agents/skills/address-review/SKILL.md](../../.agents/skills/address-review/SKILL.md) - shared address-review skill exposed to Claude Code as `/address-review`.
- [.agents/skills/adversarial-pr-review/SKILL.md](../../.agents/skills/adversarial-pr-review/SKILL.md) - shared adversarial review skill exposed to Claude Code as `/adversarial-pr-review`.
- [REVIEW.md](../../REVIEW.md) - optional Claude Code Review instruction file for managed review behavior.
- [.claude/prompts/address-review.md](../../.claude/prompts/address-review.md) - optional compatibility pointer to the canonical reusable prompt; copy it only if the target repo keeps Claude prompt aliases.
- [.claude/prompts/adversarial-pr-review.md](../../.claude/prompts/adversarial-pr-review.md) - optional compatibility pointer to the canonical adversarial review prompt.
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
   - Add `.agents/skills/pr-batch/SKILL.md`.
   - Add `.agents/skills/post-merge-audit/SKILL.md`.
   - Add `.agents/skills/adversarial-pr-review/SKILL.md`.
   - Add `.agents/workflows/pr-processing.md`.
   - Add `.agents/workflows/post-merge-audit.md`.
   - Add `.agents/workflows/adversarial-pr-review.md`.
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
   - Keep the pre-push review/simplify gate: commit locally before pushing, run `codex review --base origin/main` or the target repo's equivalent on the clean diff, add Claude Code review when requested or high-risk, run `/simplify` only after a review-clean commit, accept only behavior-preserving simplifications, rerun validation/review before pushing, and record the gates used in PR evidence or churn notes.
   - Treat high-risk categories (workflow, build-config, lockfiles, release tooling) as allowed implementation scope that requires focused diffs, appropriate validation, self-review, and clear PR evidence. Do not make them standing pre-approval categories; only a per-run user instruction should narrow them for that run.
   - Keep the high-concurrency launch gates: exact target confirmation for filter-based batches, trusted-list permission preflight, untrusted GitHub content handling, and resumable coordination state.
   - Keep the review-completion gate: configured review agents must finish for the current head SHA, and actionable review comments must be triaged before merge.
   - Keep AI review systems advisory: CodeRabbit.ai, Claude, Cursor Bugbot, Greptile, Codex review, and similar tools should not become special approval gates unless they identify a confirmed blocker.
   - Keep the adversarial review gate for high-risk or concurrent-batch PRs, and do not treat `/pr-review-toolkit:review-pr` as sufficient by itself.
   - Keep the post-merge audit checks for late reviews, untriaged `Must Fix` comments, missing changelog entries, and cross-PR interactions.
   - Keep the post-merge issue plan gate: Codex and Claude independent audits draft issue entries only; one coordinator dedupes fingerprints and creates issues only after user approval.

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
   - Ask an agent to run `$pr-batch` with a filter-based request and confirm it stops with an exact target list and `/goal` prompt before spawning workers.
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
- Batch coordination labels such as `codex-ready`, `codex-wip`, or `codex-pending-question`, if adopted; otherwise remove or replace those examples and rely on exact lane assignments plus structured claim comments.
- Full-CI trigger mechanism if `+ci-*` is not installed.
- Follow-up issue title convention. React on Rails uses `Follow-up:`.
- Documentation boundaries: public docs, internal docs, generated docs, changelog policy.
- Branch naming and merge strategy.
- Review bots and which ones can leave actionable feedback.
- Review bots that must finish before merge, and how to detect late or asynchronous review comments.
- Claude Code slash commands such as `/adversarial-pr-review` or `/pr-review-toolkit:review-pr`, if the target repo uses them, and the fallback when Codex cannot execute Claude commands directly.
- Required checks and branch-protection exceptions.
- Tool-specific docs that must link back to `AGENTS.md`.

## What Not To Copy Blindly

- React on Rails package paths such as `react_on_rails/`, `packages/react-on-rails/`, and `react_on_rails_pro/`.
- Ruby, Rails, Shakapacker, RSC, SSR, and Pro-specific rules unless the target repo uses those concepts.
- Commands that do not exist in the target repo.
- The `+ci-*` workflow without adapting workflow names, permissions, labels, and dispatch inputs.
- High-concurrency no-approval execution for arbitrary public issue or PR filters. Require a maintainer-approved exact target list first.
- `codex-ready`, `codex-wip`, or `codex-pending-question` labels unless the target repo creates them and defines their meaning. Labels are dashboard hints, not durable locks.
- Merge-readiness claims based only on green checks while reviewer comments are untriaged. Review comments can arrive separately from checks.
- Treating AI reviewer approvals, positive issue comments, or "no actionable comments" summaries as required maintainer approvals. AI review systems are advisory unless they identify a confirmed blocker.
- Treating `/pr-review-toolkit:review-pr` as a complete adversarial gate. Use a repo-specific adversarial workflow when release risk, review timing, changelog coverage, or untrusted PR content matters.
- Independent Codex and Claude agents creating GitHub issues directly from their separate reports. Use draft issue entries, then dedupe and create issues from one coordinator.
- Follow-up issue creation habits. The default should remain no new issue unless the user explicitly chooses bundled tracking.
- PR labels that are not created and documented in the target repo.

## Sync Policy

`AGENTS.md` should remain the policy source of truth in each repo. Tool-specific files should be thin wrappers or prompt forms that link back to the same policy.

When changing policy:

1. Update `AGENTS.md`.
2. Update `.agents/skills/pr-batch/SKILL.md`, `.agents/skills/post-merge-audit/SKILL.md`, `.agents/skills/adversarial-pr-review/SKILL.md`, `.agents/workflows/pr-processing.md`, `.agents/workflows/post-merge-audit.md`, `.agents/workflows/adversarial-pr-review.md`, and `.agents/workflows/address-review.md`.
3. Update Claude skill or prompt files if they exist.
4. Run Markdown formatting and link checks.
5. Do one dry-run batch launch, triage, or PR-processing pass before declaring the copied workflow ready.

## Suggested Adoption PR Summary

```markdown
## Summary

- add canonical agent instructions in `AGENTS.md`
- add a `pr-batch` skill for safe multi-issue and multi-PR launch planning
- add a `post-merge-audit` skill for missed review gates, changelog gaps, and release-risk checks
- add an `adversarial-pr-review` skill for stricter Codex/Claude pre-merge and post-merge review gates
- add reusable PR processing, post-merge audit, adversarial-review, and address-review workflows under `.agents/workflows/`
- add Claude skill/prompt support for the same review flow
- document local validation and full-CI escalation rules for this repository

## Validation

- markdown formatting check
- markdown link check
- dry-run issue or PR triage without code changes
```
