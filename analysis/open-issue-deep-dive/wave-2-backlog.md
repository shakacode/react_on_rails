# Wave 2 Backlog Issues (No Open PR at Snapshot)

Generated from open-issue triage snapshot dated 2026-03-22.

Field note: `Posted question` is the exact question posted to each issue during the 2026-03-22 triage pass.
Field note: Most `ci/tooling` entries intentionally share the same routing question to keep maintenance-wave triage consistent.

## #2575 Update Pro install CTA after reactonrails.com launch

- Domain: documentation
- Labels: documentation, P3
- Created: 2026-03-09
- Context excerpt: ## Context `react_on_rails/lib/generators/react_on_rails/pro_setup.rb` currently includes a temporary CTA with direct email for evaluation licenses. ## TODO Once the new `reactonrails.com` repository/site flow is ready, ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2574 AGENTS.md changes trigger unnecessary CI workflow runs

- Domain: ci/tooling
- Labels: ci-tooling, P3
- Created: 2026-03-09
- Context excerpt: ## Problem Pushing a docs-only commit to a PR re-triggers the full CI suite, even when the previous push already completed all checks successfully. ## What happened (PR #2569) ### Push 1: `dadc6524` (code changes — rake ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2572 Incorporate Everything Claude Code (ECC) patterns for enhanced AI-assisted development

- Domain: discussion/rfc
- Labels: enhancement, discussion, P3
- Created: 2026-03-09
- Context excerpt: ## Summary After reviewing [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (50K+ stars, Anthropic hackathon winner), several patterns would enhance our already solid Claude Code setup. ## Cur ...
- Posted question: Is this still active for implementation, or should it remain a discussion-only backlog item?

## #2552 RFC: Rename bundler-agnostic config files from *WebpackConfig.js to bundler-neutral names

- Domain: discussion/rfc
- Labels: enhancement, P3
- Created: 2026-03-07
- Context excerpt: # RFC: Rename bundler-agnostic config files from `*WebpackConfig.js` to bundler-neutral names ## Summary React on Rails generates config files like `serverWebpackConfig.js`, `clientWebpackConfig.js`, and `commonWebpackCo ...
- Posted question: Is this still active for implementation, or should it remain a discussion-only backlog item?

## #2546 Fix benchmark workflow

- Domain: ci/tooling
- Labels: ci-tooling, P3
- Created: 2026-03-06
- Context excerpt: The last report on https://bencher.dev/console/projects/react-on-rails-t8a9ncxo/reports?per_page=8&page=1 is from February 9. The workflow still runs and succeeds on master (https://github.com/shakacode/react_on_rails/ac ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2409 Align spec/dummy/Procfile.dev SERVER_BUNDLE_ONLY value with template convention

- Domain: developer-experience
- Labels: enhancement, P3
- Created: 2026-02-14
- Context excerpt: ## Description The `spec/dummy/Procfile.dev` uses `SERVER_BUNDLE_ONLY=true` while the project template at `lib/generators/react_on_rails/templates/base/base/Procfile.dev` uses `SERVER_BUNDLE_ONLY=yes`. Both values work e ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2224 Improve bundler caching in CI

- Domain: ci/tooling
- Labels: P3
- Created: 2025-12-15
- Context excerpt: Currently our CI caches gems manually, but https://github.com/ruby/setup-ruby/?tab=readme-ov-file#caching-bundle-install-manually says > It is also possible to cache gems manually, **but this is not recommended because i ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2214 Finish merging linting between Core and Pro

- Domain: ci/tooling
- Labels: P3
- Created: 2025-12-12
- Context excerpt: We currently have separate Prettier and ESLint configurations, as well as .github/workflows/pro-lint.yml. To simplify and speed up CI, they should all be unified and .github/workflows/pro-lint.yml removed. ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2199 Fix: Restore result-encoding in detect-invalid-ci-commands workflow

- Domain: ci/tooling
- Labels: P3
- Created: 2025-12-10
- Context excerpt: ## Summary The `result-encoding: string` parameter was accidentally removed from `.github/workflows/detect-invalid-ci-commands.yml` in commit 4970d2154 ("Fix JSON parsing error in detect-invalid-ci-commands workflow"). T ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2190 Add top-level setup script for unified dependency installation

- Domain: developer-experience
- Labels: AI_ON, P3
- Created: 2025-12-09
- Context excerpt: ## Problem Currently, setting up the development environment requires running multiple commands in different directories: ```bash # Root directory pnpm install bundle install # Dummy app cd spec/dummy pnpm install bundle ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #2184 Remove "Setup Node with V8 Crash Retry" action

- Domain: ci/tooling
- Labels: P3
- Created: 2025-12-08
- Context excerpt: It only seems to do something when using `yarn` https://github.com/shakacode/react_on_rails/blob/97fde8431e83631399dfb1df1f673b5c468dfd2a/.github/actions/setup-node-with-retry/action.yml#L43 but after #2121 we don't anym ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2182 Add support for react 19.2.1 and make a plan for implementing **Partial Pre-rendering** feature

- Domain: discussion/rfc
- Labels: P3
- Created: 2025-12-08
- Triage note: Issue body is template boilerplate with no concrete implementation details; currently labeled `P3` in this snapshot and kept in Wave 2 until scope is rewritten.
- Posted question: Should this remain parked until the issue is rewritten with concrete scope and acceptance criteria?

## #2180 Use pnpm catalogs to decrease duplication between `package.json` files

- Domain: ci/tooling
- Labels: P3
- Created: 2025-12-07
- Context excerpt: E.g. for React versions to be stated only once. See https://pnpm.io/catalogs. Note `convert` script will need to be updated as well. ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2169 Add performance tests for different SSR and client rendering operations

- Domain: ci/tooling
- Labels: P3
- Created: 2025-12-04
- Triage note: Inferred scope is adding reproducible SSR/client performance benchmarks with CI-noise controls and stable baselines before gating changes.
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2157 Improve test assertions: Replace ambiguous call_count patterns with explicit have_received checks

- Domain: testing
- Labels: P3
- Created: 2025-12-01
- Context excerpt: ## Summary Some tests in the codebase use indirect `call_count` counter patterns to verify method invocations. These patterns are ambiguous because they: 1. **Prove absence indirectly** - asserting a count is lower doesn ...
- Posted question: Should this run in the testing-quality maintenance wave, or be deferred behind release-critical runtime work?

## #2156 Add OpenTelemetry support for Node Renderer

- Domain: pro/observability
- Labels: P3
- Created: 2025-12-01
- Context excerpt: ## Summary Add OpenTelemetry instrumentation to the React on Rails Pro Node Renderer to enable distributed tracing and observability. ## Required Dependencies ```json "@opentelemetry/exporter-trace-otlp-http": "^0.203.0" ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2018 Investigate AI security scanners for React on Rails

- Domain: ci/tooling
- Labels: P3
- Created: 2025-11-14
- Context excerpt: https://joshua.hu/llm-engineer-review-sast-security-ai-tools-pentesters is a success report of using AI-native security scanners to find bugs in well-tested applications like curl. From the preface: > If you’re a technol ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2003 Question: Should Pro package tests use matrix exclusion logic?

- Domain: ci/tooling
- Labels: question, low priority, P3
- Created: 2025-11-12
- Context excerpt: ## Background The main test workflows (`main.yml`, `examples.yml`) have matrix exclusion logic to skip minimum dependency tests on PRs: ```yaml exclude: - dependency-level: ${{ github.event_name == 'pull_request' && gith ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2001 Discussion: Consider renaming /run-skipped-ci to /run-full-ci

- Domain: ci/tooling
- Labels: discussion, low priority, P3
- Created: 2025-11-12
- Context excerpt: ## Background Currently, the command to trigger the full CI suite (including minimum dependency tests) is `/run-skipped-ci`. ## Question Should we rename this to `/run-full-ci` for better clarity? ### Current name: `/run ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2000 CI: Improve workflow verification retry logic in run-skipped-ci

- Domain: ci/tooling
- Labels: enhancement, low priority, P3
- Created: 2025-11-12
- Context excerpt: ## Problem The `run-skipped-ci.yml` workflow uses a fixed 5-second wait before verifying that workflows are queued: ```javascript await new Promise(resolve => setTimeout(resolve, 5000)); ``` This approach has several iss ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?
