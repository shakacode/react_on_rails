# AGENTS.md

Instructions for AI coding agents working on the React on Rails codebase.

React on Rails is a Ruby gem + npm package that integrates React with Ruby on Rails, providing server-side rendering (SSR) via Node.js or ExecJS. This is a monorepo: the open-source gem lives at `react_on_rails/`, the npm package at `packages/react-on-rails/`, and the Pro package at `react_on_rails_pro/`.

## Reusable Workflows

- `AGENTS.md`: canonical entry point for agent instructions and workflow discovery
- `.agents/skills/`: agent skills; `.claude/skills` is a symlink here so Claude Code exposes the same workflows as slash commands
- `.agents/workflows/`: shared prompt templates and reusable workflows for Codex, GPT, and other non-Claude tools
- `internal/contributor-info/agent-workflow-adoption.md`: guide for copying these agent workflows into other repositories
- `internal/contributor-info/agent-pr-batch-skills.md`: contributor guide for choosing and sequencing `$plan-pr-batch` and `$pr-batch`
- When the user wants to choose issues or PRs for a future Codex batch, use `.agents/skills/plan-pr-batch/SKILL.md` to produce a ready `$pr-batch` goal; a short invocation is `$plan-pr-batch` or "Plan a Codex batch"
- When the user wants a multi-issue or multi-PR Codex batch, use `.agents/skills/pr-batch/SKILL.md`; a short invocation is `$pr-batch` or "Run a Codex batch"
- When the user wants to audit merged batch work, missed reviews, release-candidate risk, or possible bad merges, use `.agents/skills/post-merge-audit/SKILL.md`; reusable prompts live in `.agents/workflows/post-merge-audit.md`
- When the user wants an adversarial PR review, red-team review, Claude/Codex comparison review, or a stricter pre-merge gate, use `.agents/skills/adversarial-pr-review/SKILL.md`; reusable prompts live in `.agents/workflows/adversarial-pr-review.md`
- When the user assigns an issue, PR, review-fix pass, or merge queue to an agent, follow `.agents/workflows/pr-processing.md`
- When the user asks to address PR review comments, use `.agents/skills/address-review/SKILL.md`; `.agents/workflows/address-review.md` remains a copy/paste prompt for assistants without skill support
- Default simplify model: `claude-opus-4-8`

## Canonical Agent Policy

`AGENTS.md` is the canonical source for repository-wide agent rules:

- Commands and test/lint workflow
- Code style and formatting expectations
- Git/PR boundaries and safety rules
- Directory and documentation boundaries

Other agent-facing docs (for example `CLAUDE.md`) should contain only tool-specific workflow notes and link back here.
If there is a conflict, `AGENTS.md` wins.

## Commands

```bash
# Install dependencies
bundle && pnpm install

# Build TypeScript → JavaScript
pnpm run build

# Lint (MANDATORY before every commit)
(cd react_on_rails && bundle exec rubocop)                       # OSS Ruby lint — CI-equivalent
# Pro Ruby lint — CI-equivalent when Pro files or RuboCop config change
(cd react_on_rails_pro && bundle exec rubocop --ignore-parent-exclusion)
pnpm run lint                                                    # JS/TS via ESLint
pnpm start format.listDifferent                                  # Check Prettier formatting
rake lint                                                        # All linting (Ruby + JS + formatting)

# Optional Ruby diagnostic from the repo root (not the CI contract)
bundle exec rubocop

# Auto-fix formatting
rake autofix                         # Preferred for all formatting

# Run tests
rake run_rspec:gem                   # Ruby unit tests (gem code)
rake run_rspec:dummy                 # Ruby integration tests (dummy Rails app)
pnpm run test                        # JavaScript/TypeScript tests
rake                                 # Full suite (lint + all tests except examples)

# Type checking
pnpm run type-check                  # TypeScript
bundle exec rake rbs:validate        # RBS signatures

# Additional test subsets
rake run_rspec                       # All Ruby tests
rake all_but_examples                # All tests except generated examples
rake run_rspec:shakapacker_examples_basic  # Single example test

# Documentation checks
script/check-docs-sidebar            # Validate docs sidebar coverage
bin/check-links                      # Markdown link checks (requires lychee)

# Full initial setup
bundle && pnpm install && rake shakapacker_examples:gen_all && rake node_package && rake

# CI/workflow linting
actionlint                           # GitHub Actions lint
yamllint .github/                    # YAML lint (do NOT run RuboCop on .yml files)

# Dependency version updates
rake shakapacker:update_version[9.6.1]  # Update shakapacker across the monorepo
```

### Updating Shakapacker

Use `rake shakapacker:update_version[VERSION]` to update shakapacker across the entire monorepo. This single command updates all Gemfiles, package.json files, Gemfile.lock files, and pnpm-lock.yaml. Do **not** manually edit individual version references — always use the rake task to keep everything in sync.

The task handles Ruby version switching for apps that require a different Ruby version (set `RUBY_VERSION_MANAGER` to `rvm`, `rbenv`, `asdf`, or `mise` if needed; defaults to `rvm`). It continues gracefully if a single lock file update fails (e.g., due to a missing Ruby version).

## Testing

- **Prefer local testing over CI iteration** — don't push "hopeful" fixes. Apply the **15-minute rule**: if 15 more minutes of local testing would catch the issue before CI does, spend the 15 minutes.
- **Never claim a test is "fixed" without running it locally first.** Use "This SHOULD fix..." or "Proposed fix (UNTESTED)" for unverified changes.
- **Automated tests passing is necessary but not sufficient.** If your changes affect how the app starts, builds, or serves, you must also verify the dev environment manually. See [Manual Dev Environment Testing](.claude/docs/manual-dev-environment-testing.md) for the full checklist.
- **Ruby**: RSpec. Unit tests in `react_on_rails/spec/react_on_rails/`, integration tests via a dummy Rails app in `react_on_rails/spec/dummy/`.
- **JavaScript/TypeScript**: Jest. Tests in `packages/react-on-rails/tests/`.
- **E2E**: Playwright. Tests in `react_on_rails/spec/dummy/e2e/playwright/e2e/`. Run with `cd react_on_rails/spec/dummy && pnpm test:e2e`.
- **The dummy app** (`react_on_rails/spec/dummy/`) is a full Rails application used for integration testing. Many tests require it.

Run specific test files:

```bash
bundle exec rspec react_on_rails/spec/react_on_rails/path/to/spec.rb
cd react_on_rails/spec/dummy && bundle exec rspec spec/path/to/spec.rb
```

## Project Structure

| Directory                                        | Purpose                                                                                  |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `react_on_rails/lib/react_on_rails/`             | Ruby gem source — helpers, configuration, SSR pool, engine                               |
| `react_on_rails/lib/generators/`                 | Rails generators for `react_on_rails:install`                                            |
| `react_on_rails/spec/`                           | RSpec tests (unit + integration via dummy app)                                           |
| `react_on_rails/spec/dummy/`                     | Full Rails app for integration testing and E2E                                           |
| `packages/react-on-rails/src/`                   | TypeScript source — client-side React integration                                        |
| `packages/react-on-rails/tests/`                 | Jest tests for the npm package                                                           |
| `react_on_rails_pro/`                            | Pro package (separate gem + npm)                                                         |
| `rakelib/`                                       | Rake task definitions                                                                    |
| `docs/oss/`                                      | OSS documentation — published to the [ShakaCode website](https://reactonrails.com/docs/) |
| `docs/pro/`                                      | Pro documentation — installation, configuration, RSC, node renderer, caching             |
| `internal/contributor-info/`                     | Internal contributor docs (not published to the website)                                 |
| `internal/planning/`                             | Internal planning docs, drafts, and historical analysis                                  |
| `internal/react_on_rails_pro/contributors-info/` | Internal Pro contributor docs (not published to the website)                             |
| `analysis/`                                      | Investigation and analysis documents (kebab-case `.md` files)                            |

## Code Style

### Ruby (RuboCop)

Line length max 120 characters. Run `bundle exec rubocop [file]` to check.

**Line length — break long chains:**

```ruby
# Bad
content = pack_content.gsub(/import.*from.*['"];/, "").gsub(/ReactOnRails\.register.*/, "")

# Good
content = pack_content.gsub(/import.*from.*['"];/, "")
                      .gsub(/ReactOnRails\.register.*/, "")
```

**Named subjects in RSpec:**

```ruby
# Bad
subject { instance.method_name(arg) }

# Good
subject(:method_result) { instance.method_name(arg) }
```

**Security violations — scope disable comments tightly:**

```ruby
# rubocop:disable Security/Eval
expect { evaluate(sanitized_content) }.not_to raise_error
# rubocop:enable Security/Eval
```

### JavaScript/TypeScript

Prettier handles all formatting. Never manually format — run `rake autofix` instead.

### GitHub Actions

For GitHub Actions jobs that install Ruby gems, prefer `.github/actions/setup-bundle` over hand-written `actions/cache` plus `bundle install` steps.
The action validates a committed `Gemfile.lock`, configures the bundle path and Bundler version for later `bundle exec` steps,
restores/saves the gem cache, and supports non-frozen installs via `frozen: 'false'` for minimum-dependency jobs.

## Git Workflow

**Branch naming**: `type/descriptive-name` (e.g., `fix/ssr-hydration-mismatch`)

**Commit messages**: Explain why, not what. One logical change per commit.

**Squash merges**: When completing a GitHub squash merge, include the PR number in the squash commit title using the format `<PR title> (#<PR number>)`, for example `Docs: clarify rails new JavaScript skip flag (#3666)`. For CLI merges, pass `--subject "<PR title> (#<PR number>)"` to `gh pr merge --squash` and verify the title before confirming the merge.

**PR creation**: Use `gh pr create` with a clear title, summary, and test plan.

**PR processing**: Before pushing a review-fix batch, opening a PR, marking a PR ready, requesting full CI, or reporting merge-readiness, run the agent PR processing flow in `.agents/workflows/pr-processing.md`: verify the work is worth doing, self-review the diff, run local validation, use the pre-push AI review and simplify gate when appropriate, batch fixes, and document exact verification evidence plus churn notes. After a PR and its reviews exist, wait for configured review agents and triage actionable review feedback before marking ready, requesting merge, or merging.

**Full CI usage**: Do not use full CI as the first real validation pass. Prefer local checks and targeted CI first. Use the `+ci-*` PR comment commands for an auditable full-CI decision: `+ci-status` before deciding on full CI, `+ci-run-full` only at the final readiness gate, `+ci-stop-full` when an iterating PR should stop rerunning full CI, `+ci-skip-full [reason]` only with explicit maintainer approval for a low-risk waiver, and `+ci-help` when syntax is unclear. Put one `+ci-*` command per PR comment.

**GitHub follow-up issues**: Follow-up issues are the exception. Prefer fixing or declining review feedback in the PR. If deferred work remains valuable, present one bundled deferred-work summary and ask whether to track it. Prefer an existing issue; otherwise create at most one bundled issue per PR unless the user explicitly approves more. New follow-up issue titles must begin with `Follow-up:`. Build multi-line issue bodies as Markdown files and pass them with `gh issue create --body-file`; do not pass escaped newline strings through `--body`.

## Release Mode And Auto-Merge Coordination

Use the current release tracker to decide whether PRs are in normal development, accelerated RC, strict RC, or final-release mode. The tracker is the live source of truth for the mode; committed docs define how to interpret it.

- An active tracker is an open release gate issue, usually found by the existing `release` and `TRACKING` labels or the `Release gate:` title. The mode must be recorded in the issue body, not encoded by adding more labels.
- If no active tracker exists, assume `development` mode. This is not a blocker; it means the repo is moving toward the next beta/RC/final.
- If multiple active trackers exist for different release targets or conflicting modes, report `release-mode-conflict` and do not auto-merge until resolved.
- For duplicate trackers with the same final release target, the oldest open tracker is canonical unless it explicitly says it is superseded by another tracker. Agents may close clean duplicates only after preserving non-conflicting useful information in the canonical tracker.
- Agents do not auto-create release trackers. A maintainer creates one when entering accelerated RC, strict RC, or final-release coordination.
- To avoid concurrent issue-body overwrites, re-read the tracker immediately before editing it. Prefer append-only comments for per-PR/batch status from concurrent agents, and only edit the tracker body when preserving the latest body content. If the latest tracker body changed in a way the agent cannot safely merge, post a comment with the intended update and report the conflict.

During `accelerated-rc`, affected areas such as SSR, RSC, hydration, package release, generators, CI, benchmarks, and Pro/core boundaries do not cap confidence by themselves. They choose the validation checklist. Actual uncertainty, missing proof, failed checks, or unresolved findings lower confidence.

Auto-merge during accelerated RC requires a finalized PR-body confidence block. The authoring agent may draft it, but a separate coordinator, finalizer, or review agent must finalize it. Keep only the latest finalized block in the PR body.

```text
## Agent Merge Confidence

Mode: accelerated-rc
Score: 8/10
Auto-merge recommendation: yes
Affected areas: RSC, Pro/core boundary, CI
CI detector: `script/ci-changes-detector origin/main` -> <summary>
Validation run:
- <command> -> <result>
Review/check gate:
- Claude review: complete for <head SHA>, no confirmed blocker
- Fallback review, if Claude quota-limited: <Cursor or Codex result>
- GitHub checks: complete for <head SHA>, failures/skips explained
Known residual risk: <none or concise risk>
Finalized by: <agent/person>
```

Auto-merge threshold in accelerated RC is `8/10`. A score of `7/10` permits human merge after review, but not auto-merge. Final-release mode is stricter and should run a post-merge audit before publishing the final release.

## Review Workflow

### PR CI Labels

Agents should recommend PR labels based on change complexity and risk. The goal is to keep low-risk PRs mergeable on fast, path-relevant CI while still escalating high-risk PRs (HPRs) before merge.

- **Default: no CI-expansion label.** For docs-only changes, focused tests, small isolated fixes, and refactors with no cross-package behavior change, rely on the standard path-based CI selection and local verification.
- **Use `full-ci`** (or ask a maintainer to comment `+ci-run-full`) when the PR is high-risk or broad: CI workflow/detector changes, dependency or lockfile updates, package manager/Ruby/Node version changes, release/build/package publishing logic, generator output, dummy app boot/build behavior, SSR or hydration behavior, cross-cutting core Ruby changes, Pro/core boundary changes, or changes where skipped suites would leave a credible regression path.
- **Use `benchmark`** for performance-sensitive changes: server rendering paths, Node renderer, caching, bundle generation, asset serving/precompile behavior, concurrency/pooling, or anything expected to affect throughput, latency, memory, or bundle size. `full-ci` does not trigger benchmarks; use both labels when a PR is both high-risk and performance-sensitive.
- **Remove `full-ci` when no longer needed** with `+ci-stop-full` if the PR returns to a low-risk state after splitting or reverting broad changes.
- **Record intentional full-CI waivers** with `+ci-skip-full [optional reason]`. This is especially important for admins: the comment creates a SHA-bound audit trail without forcing docs-only or low-risk PRs to run the full matrix.
- In PR descriptions and handoffs, state the recommended label decision explicitly: `Labels: none`, `Labels: full-ci`, `Labels: benchmark`, or `Labels: full-ci, benchmark`, with one sentence explaining why.

### For All PRs

- Merge qualification is: CI is passing, all current review comments and threads are addressed or explicitly triaged by tier, and no major question or discussion item needs maintainer attention.
- Treat AI review systems such as Claude, CodeRabbit, Cursor Bugbot, Greptile, and similar tools as advisory unless they identify a confirmed blocker: a correctness regression, failing test, security issue, API contract break, data-loss risk, or missing required maintainer approval.
- Do not wait for CodeRabbit.ai, Claude, or any other AI system to approve when CI is green, blocking review feedback is addressed, and no major question or discussion item remains.
- If branch protection still reports `REVIEW_REQUIRED`, verify whether a formal GitHub approving review is missing. Positive AI issue comments such as "LGTM" or "Ready to merge" support triage but do not satisfy a required review.
- Security-category findings such as XSS, injection, exposed secrets, or auth bypass still require investigation before dismissal, regardless of source.

For auto-merge, all GitHub checks for the current head SHA must be complete. Skipped checks count as complete when the PR body explains why they are expected. Failed checks block auto-merge unless a maintainer explicitly waives them. If checks are noisy or unnecessary, fix the CI selection process instead of bypassing them silently.

For auto-merge, use the GitHub `claude-review` check as the preferred independent review gate. Wait while it is queued or running for the current head SHA. If it fails due to quota, usage limit, unavailable model, or equivalent capacity failure, fall back to Cursor Bugbot or Codex review and record that fallback in the PR body. Other Claude failures block until understood. CodeRabbit remains advisory and is not a required approval gate.

For small, focused PRs (roughly 5 files changed or fewer and one clear purpose):

- Use at most one AI reviewer that leaves inline comments. Additional AI tools should be summary-only or used manually.
- Wait for the first full review pass to finish before pushing follow-up commits.
- Before merge, wait for configured review agents such as Claude review, CodeRabbit, Greptile, Cursor Bugbot, and Codex review to finish for the current head SHA, then triage their reviews/comments. A green or skipped check is not enough if actionable comments exist.
- Treat AI review systems as advisory unless they identify a confirmed blocker: correctness regression, failing test, security issue, API contract break, data-loss risk, or missing required maintainer approval. AI approvals, positive issue comments, and "no actionable comments" summaries are useful evidence, but they are not required maintainer approvals or special merge gates.
- If the user requests Claude review from a Codex-run PR process, prefer the repo-local `/adversarial-pr-review <PR_URL>` handoff after a draft PR exists. `/pr-review-toolkit:review-pr` is useful input, but it is not by itself the merge gate. Classify and resolve or waive Claude's actionable findings before final readiness.
- Batch review fixes into one follow-up push when practical. Do not create a new commit for each minor comment.
- Treat as blocking only: correctness bugs, failing tests, regressions, and clear inconsistencies with adjacent code. Nits and style suggestions are optional unless a maintainer asks for them.
- Verify language, runtime, and library claims locally before changing code in response to AI review comments.
- Deduplicate repeated bot comments before acting on them. Fix the underlying issue once, then resolve the duplicates.
- Rebase or merge `main` once, near the end of the review cycle. For `CHANGELOG.md` conflicts, prefer resolving them as the final step before merge.
- When asking an agent to address review comments, instruct it to classify comments into `blocking`, `optional`, and `noise`, then apply only the `blocking` items plus any explicitly selected optional items.

## Boundaries

### Always

- Run the CI-equivalent Ruby lint before committing, not the root `bundle exec rubocop`:
  ```bash
  (cd react_on_rails && bundle exec rubocop)
  # Also run when touching Pro Ruby or RuboCop config:
  (cd react_on_rails_pro && bundle exec rubocop --ignore-parent-exclusion)
  ```
  Root `bundle exec rubocop` is a broad local sweep, not the CI contract.
- Use `pnpm` for all JS operations — never `npm` or `yarn`
- Use `bundle exec` for Ruby commands
- Ensure all files end with a newline
- Let Prettier and RuboCop handle formatting — never format manually
- When adding docs under `docs/oss/` or `docs/pro/`, also add the doc ID to `docs/sidebars.ts` and run `script/check-docs-sidebar` — CI will fail otherwise. To intentionally exclude a doc from the sidebar, add its ID to `docs/.sidebar-exclusions` with a reason comment.
- Pro package, CI workflow, build-configuration, package-script, dependency, and lockfile edits do not require special approval. Keep the diff focused on the assigned issue/PR/batch and run the validation that covers the changed surface, such as Pro-specific lint/tests, `actionlint`, `yamllint .github/`, package-script smoke checks, dependency consistency checks, and `script/ci-changes-detector origin/main`.

### Destructive Git Requires Confirmation

- Destructive git operations: `reset --hard` on a branch with work, branch deletion, or force-push that drops/squashes commits, republishes a conflicted rebase, or runs when the remote has commits you don't have locally. (Force-push after a clean rebase — no conflicts, all commits preserved — is OK without asking.)

### Never

- Skip pre-commit hooks (`--no-verify`)
- Commit secrets, credentials, or `.env` files
- Commit `package-lock.json`, `yarn.lock`, or other non-pnpm lock files
- Add files to the `docs/` root — OSS docs go in `docs/oss/` subdirectories (`getting-started/`, `core-concepts/`, `building-features/`, `configuration/`, `api-reference/`, `deployment/`, `migrating/`, `upgrading/`, `misc/`); Pro docs go in `docs/pro/`
- Force push to `main` or `master`
- Reintroduce conditional gem declarations like `gem "turbolinks" if ENV["DISABLE_TURBOLINKS"].nil?` in `react_on_rails/Gemfile.development_dependencies` — conditional inclusion diverges from the lockfile and breaks `bundle install --frozen` in CI. See the comment in that Gemfile for the full explanation.

## Main branch health

The `main` branch must stay green. CI failures on `main` block releases:
`rake release` refuses to publish over a red `main` unless you explicitly
override (via `RELEASE_CI_STATUS_OVERRIDE=true` or the 4th positional arg).
Stable releases require every check to pass; pre-releases require only the
GitHub-branch-protection-required checks.

Claude Code sessions get `main`'s CI status injected at session start (and
again before `gh pr create` / pushing to `main`) via
`.claude/hooks/main-ci-status.sh`. Read it.

If `main` is red:

1. **Decide whether the failure is related to your work.** If yes, your job
   is to fix it (or revert) before adding new commits on top.
2. **If unrelated, decide whether your work is safe to merge on top.** PRs
   that add risk on top of a known-broken `main` should usually wait.
3. **If you're the one merging a PR**, check `main` post-merge within 30
   minutes (see `.claude/docs/main-health-monitoring.md`).

**Never silently override the release CI gate.** If you set
`RELEASE_CI_STATUS_OVERRIDE=true`, document in the PR / release notes why
the red checks are unrelated to the release.

## Key Concept: File Suffixes vs. RSC Directive

React on Rails has two **independent** systems that both use "client" and "server" terminology. Do not confuse them.

### 1. Bundle Placement (`.client.` / `.server.` file suffixes)

A React on Rails auto-bundling feature that controls which webpack bundle imports a file. This exists independently of React Server Components and is used with or without RSC:

- `Component.client.jsx` → imported only in the **client bundle** (browser)
- `Component.server.jsx` → imported only in the **server bundle** (and RSC bundle when RSC enabled)
- `Component.jsx` (no suffix) → imported in **both** bundles

This controls where the source file is loaded, nothing more. A `.server.jsx` file is NOT a React Server Component — it is simply a file that webpack includes in the server bundle (and the RSC bundle when RSC is enabled). These suffixes only make sense for client components, as server components exist only in the RSC bundle.

### 2. RSC Classification (`'use client'` directive)

The `'use client'` directive is part of the React Server Components architecture. It marks a component as a React Client Component. Components without it are treated as React Server Components.

When auto-bundling is enabled with RSC support (Pro feature), React on Rails uses this directive to control:

- **Registration**: `'use client'` → `ReactOnRails.register()`, no `'use client'` → `registerServerComponent()`
- **RSC bundling**: The RSC webpack loader uses this directive to decide whether a component is included in the RSC bundle or replaced with a client reference in that bundle

The `client_entrypoint?` method in `packs_generator.rb` checks for this directive.

### They Are Orthogonal

A `.client.jsx` file can be a React Server Component (if it lacks `'use client'`), and a `.server.jsx` file can be a React Client Component (if it has `'use client'`). In practice, paired `.client.`/`.server.` files should have consistent `'use client'` status because the client and server must agree on the component's RSC role for hydration to work.

## Changelog

Update `/CHANGELOG.md` for **user-visible changes only** (features, bug fixes, breaking changes, deprecations, performance improvements). Do **not** add entries for linting, formatting, refactoring, tests, or doc fixes.

- **Format**: `[PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username)` (no hash before PR number)
- **Pro-only changes** use an inline `**[Pro]**` tag prefix within the standard category sections (e.g., `- **[Pro]** **Feature name**: Description...`); do NOT create separate `#### Pro` subsections
