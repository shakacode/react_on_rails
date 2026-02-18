# AGENTS.md

Instructions for AI coding agents working on the React on Rails codebase.

React on Rails is a Ruby gem + npm package that integrates React with Ruby on Rails, providing server-side rendering (SSR) via Node.js or ExecJS. This is a monorepo: the open-source gem lives at `react_on_rails/`, the npm package at `packages/react-on-rails/`, and the Pro package at `react_on_rails_pro/`.

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
bundle exec rubocop                  # Ruby — must pass with zero offenses
pnpm run lint                        # JS/TS via ESLint
pnpm start format.listDifferent      # Check Prettier formatting
rake lint                            # All linting (Ruby + JS + formatting)

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

# Full initial setup
bundle && pnpm install && rake shakapacker_examples:gen_all && rake node_package && rake

# CI/workflow linting
actionlint                           # GitHub Actions lint
yamllint .github/                    # YAML lint (do NOT run RuboCop on .yml files)
```

## Testing

- **Prefer local testing over CI iteration** — don't push "hopeful" fixes. Apply the **15-minute rule**: if 15 more minutes of local testing would catch the issue before CI does, spend the 15 minutes.
- **Never claim a test is "fixed" without running it locally first.** Use "This SHOULD fix..." or "Proposed fix (UNTESTED)" for unverified changes.
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

| Directory                            | Purpose                                                                                                 |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `react_on_rails/lib/react_on_rails/` | Ruby gem source — helpers, configuration, SSR pool, engine                                              |
| `react_on_rails/lib/generators/`     | Rails generators for `react_on_rails:install`                                                           |
| `react_on_rails/spec/`               | RSpec tests (unit + integration via dummy app)                                                          |
| `react_on_rails/spec/dummy/`         | Full Rails app for integration testing and E2E                                                          |
| `packages/react-on-rails/src/`       | TypeScript source — client-side React integration                                                       |
| `packages/react-on-rails/tests/`     | Jest tests for the npm package                                                                          |
| `react_on_rails_pro/`                | Pro package (separate gem + npm, own lint config)                                                       |
| `rakelib/`                           | Rake task definitions                                                                                   |
| `docs/`                              | Published to the [ShakaCode website](https://www.shakacode.com/react-on-rails/docs/) — user-facing only |
| `docs/contributor-info/`             | Internal contributor docs (excluded from website)                                                       |
| `analysis/`                          | Investigation and analysis documents (kebab-case `.md` files)                                           |

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

## Git Workflow

**Branch naming**: `type/descriptive-name` (e.g., `fix/ssr-hydration-mismatch`)

**Commit messages**: Explain why, not what. One logical change per commit.

**PR creation**: Use `gh pr create` with a clear title, summary, and test plan.

## Boundaries

### Always

- Run `bundle exec rubocop` before committing — CI will reject violations
- Use `pnpm` for all JS operations — never `npm` or `yarn`
- Use `bundle exec` for Ruby commands
- Ensure all files end with a newline
- Let Prettier and RuboCop handle formatting — never format manually

### Ask First

- Destructive git operations (force push, reset --hard, branch deletion)
- Changes to CI workflows (`.github/workflows/`)
- Changes to build configuration (`package.json` scripts, webpack config)
- Modifying the Pro package (`react_on_rails_pro/`)

### Never

- Skip pre-commit hooks (`--no-verify`)
- Commit secrets, credentials, or `.env` files
- Commit `package-lock.json`, `yarn.lock`, or other non-pnpm lock files
- Add files to the `docs/` root — they must go in a subdirectory (`getting-started/`, `core-concepts/`, `building-features/`, `api-reference/`, `deployment/`, `migrating/`, `upgrading/`, `contributor-info/`, `misc/`)
- Force push to `main` or `master`

## Key Concept: File Suffixes vs. RSC Directive

React on Rails has two **independent** systems that both use "client" and "server" terminology. Do not confuse them.

### 1. Bundle Placement (`.client.` / `.server.` file suffixes)

A React on Rails auto-bundling feature that controls which webpack bundle imports a file. This exists independently of React Server Components and is used with or without RSC:

- `Component.client.jsx` → imported only in the **client bundle** (browser)
- `Component.server.jsx` → imported only in the **server bundle** (and RSC bundle when RSC enabled)
- `Component.jsx` (no suffix) → imported in **both** bundles

This controls where the source file is loaded, nothing more. A `.server.jsx` file is NOT a React Server Component — it's just a file that webpack includes only in the server bundle.

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
- **Pro-only changes** go in the `#### Pro` section of `/CHANGELOG.md`; shared changes go in the main section only (do not duplicate into Pro)
