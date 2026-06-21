# Unify Lint Configs Between Core and Pro (#2214)

Design spec for [issue #2214](https://github.com/shakacode/react_on_rails/issues/2214):
"Finish merging linting between Core and Pro."

## Goal

Eliminate the duplicate Prettier and ESLint configurations between the Core and Pro
packages, and remove `.github/workflows/pro-lint.yml`. After this change, there is a
single ESLint config and a single Prettier config covering the whole monorepo, and
CI runs JS lint and format checks exactly once per change.

## Non-Goals

- No changes to lint rules' intent (errors stay errors, warnings stay warnings). Where
  Core enforces a rule Pro previously disabled, the Core rule wins after triage.
- No changes to Pro Ruby/RBS/TypeScript checks beyond moving where they run in CI.
- No reformatting churn outside what unified Prettier produces (any reformat ships as
  a separate prep commit, reviewable on its own).
- No refactor of the lefthook framework beyond simplifying the two scripts that
  currently shard files by directory.

## Current State

**Configs (4 files):**

- `.prettierrc` (root) — printWidth 110, semi, singleQuote, trailingComma all, plus
  CSS/SCSS, JSON, and `.*rc → yaml` overrides
- `.prettierignore` (root) — excludes `react_on_rails_pro/` so root prettier never
  touches Pro
- `react_on_rails_pro/.prettierrc` — functionally identical Prettier options for
  JS/TS/JSON/CSS; explicit `parser: css` / `parser: json` (defaults, no effect); no
  `.*rc → yaml` override
- `react_on_rails_pro/.prettierignore` — Pro-scoped ignores

- `eslint.config.ts` (root) — flat config, `globalIgnores(['react_on_rails_pro/', ...])`.
  Already contains override blocks for `packages/react-on-rails-pro/**`,
  `packages/react-on-rails-pro-node-renderer/**`, and `react_on_rails_pro/spec/dummy/**`.
- `react_on_rails_pro/eslint.config.mjs` — parallel flat config. Pro-only rules:
  `lines-between-class-members` enforce, `no-mixed-operators: off`,
  `no-restricted-syntax: off`, `import/extensions: off`, `import/prefer-default-export: off`,
  `@typescript-eslint/no-floating-promises` with FastifyReply known-safe,
  `no-restricted-imports` for integrations, e2e overrides
  (`no-empty-pattern { allowObjectPatternsAsParameters: true }`,
  `react-hooks/rules-of-hooks: off`).

**Pre-commit hooks (lefthook):**

- `bin/lefthook/eslint-lint` — splits changed files into root vs `react_on_rails_pro/`
  vs `packages/react-on-rails-pro/`, runs ESLint twice (once from repo root, once from
  inside `react_on_rails_pro/`).
- `bin/lefthook/prettier-format` — same split, runs Prettier twice.

**CI workflows (relevant):**

- `.github/workflows/lint-js-and-ruby.yml` — root ESLint, root Prettier check, root
  rubocop, RBS validate, type-check, stylelint, attw/publint. `paths-ignore` excludes
  `react_on_rails_pro/**`.
- `.github/workflows/pro-lint.yml` — sets up Pro Ruby gems, Pro dummy gems, runs
  `generate_packs`, builds the `react-on-rails-pro` package, then runs Pro rubocop
  (`--ignore-parent-exclusion`), Pro `rake rbs:validate`, Pro ESLint, Pro Prettier
  check, Pro `pnpm run nps check-typescript`.
- `.github/workflows/pro-test-package-and-gem.yml` — Pro gem and JS package tests
  (already sets up Pro Ruby + pnpm).

## Approach

**Approach 1: Full merge into root** (chosen).

Delete Pro's parallel ESLint and Prettier configs. Promote Pro-only rules to scoped
override blocks in root `eslint.config.ts`. Remove the `react_on_rails_pro/` ignore
line from root `.prettierignore`. Simplify lefthook scripts to a single invocation
each. Move Pro Ruby + RBS + TypeScript checks out of the deleted `pro-lint.yml` into
a new `pro-lint` job inside `pro-test-package-and-gem.yml`. Update CI triggers and
documentation accordingly.

Rejected alternatives:

- **Shared base config imported by two configs** — keeps two config files, retains
  drift risk, doesn't enable removing `pro-lint.yml` cleanly.
- **Keep two configs, just merge CI invocation** — misses the spirit of "unified."

## Detailed Design

### 1. Unified ESLint config

Root `eslint.config.ts`:

1. Remove `'react_on_rails_pro/'` from `globalIgnores(...)` (currently line 26).
2. Extend the existing `react_on_rails_pro/spec/dummy/**` override block to also
   include `react_on_rails_pro/spec/execjs-compatible-dummy/**`. Both disable
   `import/no-unresolved` (dummy app deps may not be installed during lint).
3. Add three new override blocks for Pro-only rules:
   - `packages/react-on-rails-pro-node-renderer/src/integrations/**`
     (ignoring `…/integrations/api.ts`) — `no-restricted-imports`
     `{ patterns: ['../*'] }` to keep integrations on the public API only.
   - `react_on_rails_pro/spec/dummy/e2e-tests/**/*` —
     `no-empty-pattern { allowObjectPatternsAsParameters: true }` and
     `react-hooks/rules-of-hooks: 'off'` (Playwright fixtures + Playwright `test`
     function false-positives).
   - `packages/react-on-rails-pro-node-renderer/**/*.ts` —
     `@typescript-eslint/no-floating-promises` with FastifyReply allowed as a
     known-safe promise.
4. Drop the broader Pro-only rule relaxations (`no-restricted-syntax: off`,
   `lines-between-class-members` enforce, `no-mixed-operators: off`,
   `import/extensions: off`, `import/prefer-default-export: off`). Triage step 6
   below handles surfaced violations.
5. Delete `react_on_rails_pro/eslint.config.mjs`.
6. Triage new violations from running root ESLint against Pro paths:
   - Mechanically fix safe ones (e.g., trivial import reordering).
   - Where Pro source has a structural reason a rule can't apply, add a narrowly
     scoped override (preferably a specific file glob) in root config.
   - Surface the final triage list to reviewer before merging.

### 2. Unified Prettier config

Root `.prettierrc`: **no changes**. Pro's `.prettierrc` is a functional subset.

Root `.prettierignore`:

1. Remove the line `react_on_rails_pro/` (currently line 6, including its comment).
2. Add `**/.node-renderer-bundles` (Pro-only path).
3. Other Pro ignores (`**/tmp`, `**/public`, `**/.yalc/**`, `**/generated`,
   `**/vendor`, `**/package.json`, `.rubocop.yml`) are already covered by existing
   root patterns or the `*.yml` global ignore.

Deletions:

- `react_on_rails_pro/.prettierrc`
- `react_on_rails_pro/.prettierignore`

After deletion, run `pnpm exec prettier --write .` from the repo root and commit any
formatting diffs as a separate prep commit (reviewable independently). The two
configs produced identical Prettier output for JS/TS/JSON, so diffs should be
minimal — likely limited to files that the Pro config processed but root's pattern
matchers had not seen before.

### 3. CI workflow changes

`.github/workflows/lint-js-and-ruby.yml`:

1. Remove `react_on_rails_pro/**` from `paths-ignore` so Pro changes trigger this
   workflow.
2. No lint command changes — `pnpm run eslint --report-unused-disable-directives`
   and `pnpm start format.listDifferent` cover Pro automatically after the global
   ignore is removed.
3. No new setup steps unless verification (Section 5) proves they're needed. The
   root config already disables `import/no-unresolved` for `packages/react-on-rails-pro/**`,
   `packages/react-on-rails-pro-node-renderer/**`, and the Pro dummy paths, so the
   build/generate steps from `pro-lint.yml` should be unnecessary. If a rule does
   need them, prefer scope-disabling that rule over re-adding the build step.

`.github/workflows/pro-test-package-and-gem.yml`:

Add a new `pro-lint` job (parallel to existing test jobs, gated by the same
`detect-changes` outputs). Steps:

- Setup Ruby 3.3.7, bundler 2.5.4, Node 22.11.0, pnpm.
- Install Pro Ruby gems for the gem itself.
- `pnpm install --frozen-lockfile`.
- Install Pro dummy app Ruby gems.
- `bundle exec rake react_on_rails:generate_packs` in `spec/dummy` (needed for the
  TypeScript check to see the generated entrypoints).
- `pnpm --filter react-on-rails-pro build` (needed for the TypeScript check).
- `cd react_on_rails_pro && bundle exec rubocop --ignore-parent-exclusion`
- `cd react_on_rails_pro && bundle exec rake rbs:validate`
- `cd react_on_rails_pro && pnpm run nps check-typescript`

One job rather than three jobs: all three checks share the heaviest setup
(Ruby gem install, pnpm install, dummy gem install) and splitting would triple
setup time for negligible parallelism benefit.

`.github/workflows/pro-lint.yml`:

Delete the file.

`script/ci-changes-detector` and any related GitHub Actions:

Audit for references to `run_pro_lint` and `pro-lint`. JS/Prettier triggers fold
into existing `run_lint`; Ruby/RBS/TS triggers fold into existing `run_pro_tests`
(which already gates `pro-test-package-and-gem.yml`).

### 4. Pre-commit hooks (lefthook)

`bin/lefthook/eslint-lint`:

Replace the directory-splitting body with a single `pnpm exec eslint $files --fix`
invocation. Drop the `cd react_on_rails_pro && pnpm exec eslint` branch. Preserve
the early-exit on no matching files and the `CONTEXT` echo lines.

`bin/lefthook/prettier-format`:

Same simplification — single `pnpm exec prettier --write $files` for all files.
Drop the `cd react_on_rails_pro && pnpm exec prettier` branch.

`.lefthook.yml`: no changes.

### 5. Documentation

`react_on_rails_pro/CLAUDE.md`:

- Replace the "Linting" subsection. Pro no longer has its own configs; commands
  are run from repo root.
- Update the "Pro CI Workflows" section: remove the `pro-lint.yml` entry.
- Update the "Key Differences from Open-Source" table: remove the
  "Lint/format config" row.

`react_on_rails_pro/package-scripts.yml`: keep as-is. The `eslint`, `format`, and
`lint` nps scripts will resolve the root unified configs via cosmiconfig, so they
keep working unchanged.

Root `AGENTS.md` / `CLAUDE.md` / docs index: grep for `pro-lint.yml` and "Pro has
its own" mentions and update.

### 6. Verification (executed during implementation)

1. After Sections 1–2: run `pnpm install && pnpm run eslint --report-unused-disable-directives`
   from root. Expect clean, or a finite triage list (apply step 6 from Section 1).
2. After Sections 1–2: run `pnpm exec prettier --check .` from root. If diffs,
   commit `pnpm exec prettier --write .` output as a prep commit.
3. After Section 4: stage a sample file in `react_on_rails_pro/` and run
   `bundle exec lefthook run pre-commit` to confirm hooks lint and format Pro
   files using the unified config without the directory split.
4. After Section 3: push the branch and verify on PR:
   - `lint-js-and-ruby.yml` runs and passes (now exercising Pro paths).
   - `pro-test-package-and-gem.yml` runs the new `pro-lint` job and passes.
   - `pro-lint.yml` workflow does not appear in the checks list.

## Risk and Mitigations

- **Surfaced ESLint violations in Pro** — handled by per-file scope-disables and a
  pre-merge triage list. Worst case the override blocks grow by a handful of lines.
- **Prettier reformat diffs in Pro** — shipped as a separate prep commit so the
  unification commit is review-clean. The two configs produced identical output
  for JS/TS so diffs should be small.
- **Pro CI setup hidden dependency** — if unified ESLint actually does need
  `generate_packs` or the built Pro package to lint Pro source, the root lint job
  would need a setup expansion. Verification step 1 will catch this. Fallback is
  to scope-disable the offending rule for Pro paths rather than bloat the root
  lint job.
- **CI trigger coverage** — `paths-ignore` removal on `lint-js-and-ruby.yml` means
  Pro changes now trigger root lint. This is the desired outcome; it ensures Pro
  lint regressions are caught even when Pro test jobs are skipped by docs-only
  paths.

## Out of Scope

- Reformatting Pro source beyond what unified Prettier produces.
- Refactoring rule sets to be more or less strict than the union of today's two
  configs.
- Touching unrelated CI workflows.
- Renaming or moving `pro-test-package-and-gem.yml`.
