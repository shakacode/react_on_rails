# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

React on Rails is a Ruby gem and NPM package that seamlessly integrates React components into Rails applications with server-side rendering, hot module replacement, and automatic bundle optimization. This is a **dual-package project** maintaining both a Ruby gem (for Rails integration) and an NPM package (for React client-side functionality).

## Essential Development Commands

### Setup

```bash
# Initial setup for gem development
bundle && yarn

# Full setup including examples
bundle && yarn && rake shakapacker_examples:gen_all && rake node_package && rake

# Install git hooks (automatic on setup)
bundle exec lefthook install
```

### Testing

```bash
# All tests (excluding examples) - recommended for local development
rake all_but_examples

# Run specific test suites
bundle exec rspec                    # All Ruby tests from project root
rake run_rspec:gem                   # Top-level gem tests only
rake run_rspec:dummy                 # Dummy app tests with turbolinks
rake run_rspec:dummy_no_turbolinks   # Dummy app tests without turbolinks
yarn run test                        # JavaScript tests (Jest)

# Run single example test
rake run_rspec:shakapacker_examples_basic

# Test environment diagnosis
rake react_on_rails:doctor
VERBOSE=true rake react_on_rails:doctor  # Detailed output
```

### Linting & Formatting (CRITICAL BEFORE EVERY COMMIT)

```bash
# Auto-fix all violations (RECOMMENDED workflow)
rake autofix  # Runs eslint --fix, prettier --write, and rubocop -A

# Manual linting
bundle exec rubocop                  # Ruby - MUST pass before commit
rake lint                            # All linters (ESLint + RuboCop)
yarn run lint                        # ESLint only
rake lint:rubocop                    # RuboCop only

# Check formatting without fixing
yarn start format.listDifferent
```

### Building

```bash
# Build NPM package (TypeScript → JavaScript)
yarn run build                       # One-time build
yarn run build-watch                 # Watch mode for development

# Type checking
yarn run type-check
```

### Development Server (Dummy App)

```bash
cd react_on_rails/spec/dummy

# Start development with HMR
foreman start                        # Uses Procfile.dev (default)
bin/dev                              # Alternative

# Other modes
bin/dev static                       # Static assets
bin/dev prod                         # Production-like environment
```

### Local Testing with Yalc

```bash
# In react_on_rails directory
yarn run build
yalc publish

# In test app directory
yalc add react-on-rails

# After making changes (CRITICAL STEP)
cd /path/to/react_on_rails
yalc push                            # Push updates to all linked apps

cd /path/to/test_app
yarn                                 # Update dependencies
```

## Critical Pre-Commit Requirements

**⚠️ MANDATORY BEFORE EVERY COMMIT:**

1. **Run `bundle exec rubocop` and fix ALL violations**
2. **Ensure all files end with a newline character**
3. **Use `rake autofix` to auto-fix formatting issues**
4. **NEVER manually format code** - let Prettier and RuboCop handle it

**Note:** Git hooks (via Lefthook) run automatically and check all changed files (staged + unstaged + untracked).

## Architecture Overview

### Dual Package Structure

This project maintains two distinct but integrated packages:

#### Ruby Gem (`lib/`)

- **Purpose:** Rails integration and server-side rendering
- **Key Components:**
  - `helper.rb` - Rails view helpers (`react_component`, etc.)
  - `server_rendering_pool.rb` - Manages Node.js processes for SSR
  - `configuration.rb` - Global configuration management
  - `packs_generator.rb` - Auto-bundling and pack generation
  - `engine.rb` - Rails engine integration
  - Generators in `lib/generators/react_on_rails/`

#### NPM Package (`node_package/src/`)

- **Purpose:** Client-side React integration
- **Key Components:**
  - `ReactOnRails.ts` - Main entry point for client-side functionality
  - `serverRenderReactComponent.ts` - Server-side rendering logic
  - `clientStartup.ts` - Client-side component mounting
  - `pro/` - React on Rails Pro features (React Server Components, etc.)

### Data Flow

1. Rails view calls `react_component` helper
2. Helper generates HTML markup with props
3. Server-side rendering (if enabled) runs component in Node.js
4. Client-side JavaScript hydrates/renders component in browser
5. Auto-bundling system dynamically generates packs based on file structure

### Build System

- **Ruby:** Standard gemspec-based build → published as `react_on_rails` gem
- **JavaScript:** TypeScript compilation (`node_package/src/` → `node_package/lib/`)
- **Testing:** RSpec for Ruby, Jest for JavaScript
- **Linting:** ESLint (JS/TS), RuboCop (Ruby), Prettier (formatting)

### Key Architectural Patterns

#### Server-Side Rendering

- Uses isolated Node.js processes via `connection_pool`
- Separate server bundles can be configured for SSR-specific code
- React Server Components (RSC) support in Pro version

#### Auto-Bundling

- File-system-based automatic bundle generation
- Components in designated directories are auto-discovered
- Eliminates manual `javascript_pack_tags` configuration
- See `packs_generator.rb` for implementation

#### Component Registration

- Manual: `ReactOnRails.register({ ComponentName })` in pack files
- Auto: Components auto-registered via `auto_load_bundle: true` option

## Testing & Examples

### Dummy App (`react_on_rails/spec/dummy/`)

- Full Rails app for integration testing
- Examples of various React on Rails features
- Uses Shakapacker for webpack configuration
- Includes SSR, Redux, React Router examples

### Generated Examples (`gen-examples/`)

- Created via `rake shakapacker_examples:gen_all`
- Ignored by git
- Used for comprehensive generator testing
- Should be excluded from IDE to prevent slowdown

### Important Test Patterns

- Use `yalc` for local package testing, not `npm link`
- Always run `yalc push` after changes to see updates in test apps
- Test both with/without Shakapacker pre-installed
- Verify React components are interactive, not just rendering

## Common Development Workflows

### Making Code Changes

1. Make changes to Ruby or TypeScript code
2. For NPM changes: `yarn run build` or `yarn run build-watch`
3. For Yalc testing: `yalc push`
4. Run relevant tests
5. **Run `rake autofix`** to fix all linting
6. Commit changes

### Fixing Bugs

1. Create failing test that reproduces issue
2. Implement minimal fix
3. Ensure all tests pass
4. Run linting: `bundle exec rubocop` and `yarn run lint`
5. Update documentation if needed

### Adding Features

1. Plan implementation (use TODO list for complex tasks)
2. Write tests first (TDD)
3. Implement feature
4. Test with dummy app or examples
5. Run full test suite: `rake all_but_examples`
6. Update relevant documentation

### Testing Generator Changes

```bash
# Create test Rails app
rails new test-app --skip-javascript
cd test-app
echo 'gem "react_on_rails", path: "../react_on_rails"' >> Gemfile
bundle install

# Run generator
./bin/rails generate react_on_rails:install

# Test with yalc for full functionality
cd /path/to/react_on_rails
yalc publish
yalc push

cd /path/to/test-app
yarn install
bin/dev
```

## Formatting Rules

**Prettier is the SOLE authority for non-Ruby files. RuboCop is the SOLE authority for Ruby files.**

### Standard Workflow

1. Make code changes
2. Run `rake autofix`
3. Commit

### Merge Conflict Resolution

1. Resolve logical conflicts only (don't manually format)
2. `git add .`
3. `rake autofix`
4. `git add .`
5. `git rebase --continue` or `git commit`

**NEVER manually format during conflict resolution** - this causes formatting wars.

## RuboCop Common Issues

### Trailing Whitespace

Remove all trailing whitespace from lines

### Line Length (120 chars max)

Break long lines into multiple lines using proper indentation

### Named Subjects (RSpec)

```ruby
# Good
subject(:method_result) { instance.method_name(arg) }
```

### Security/Eval Violations

```ruby
# rubocop:disable Security/Eval
# ... code with eval
# rubocop:enable Security/Eval
```

## IDE Configuration

**Exclude these directories to prevent IDE slowdowns:**

- `/coverage`, `/tmp`, `/gen-examples`
- `/node_package/lib`, `/node_modules`
- `/react_on_rails/spec/dummy/app/assets/webpack`
- `/react_on_rails/spec/dummy/log`, `/react_on_rails/spec/dummy/node_modules`, `/react_on_rails/spec/dummy/tmp`
- `/spec/react_on_rails/dummy-for-generators`

## Important Constraints

### Package Manager

- **ONLY use Yarn Classic (1.x)** - never use npm
- Package manager enforced via `packageManager` field in package.json

### Dependencies

- Shakapacker >= 6.0 required (v16+ drops Webpacker support)
- Ruby >= 3.0
- Node.js >= 18 (tested: 18-22)
- Rails >= 5.2

### Pro Features

- React Server Components (RSC)
- Streaming SSR
- Loadable Components
- Code splitting with React Router
- Requires separate Pro subscription

## Troubleshooting

### React Components Not Rendering

- Ensure yalc setup is complete
- Run `yalc push` after changes
- Check browser console for errors
- Verify component is registered correctly

### Generator Issues

- Run `rake react_on_rails:doctor`
- Check Shakapacker is properly installed
- Ensure package.json exists
- Test with `bin/dev kill` to stop conflicting processes

### Test Failures

- Run tests from correct directory (project root vs react_on_rails/spec/dummy)
- Check that `bundle install` and `yarn install` are current
- Verify git hooks are installed: `bundle exec lefthook install`

### Linting Failures

- **Always run `bundle exec rubocop` before pushing**
- Use `rake autofix` to fix most issues automatically
- Check `.rubocop.yml` for project-specific rules

## Monorepo Merger (In Progress)

The project is merging `react_on_rails` and `react_on_rails_pro` into a unified monorepo. During this transition:

- Continue contributing to current structure
- License compliance is critical (no Pro code in MIT areas)
- See `docs/MONOREPO_MERGER_PLAN_REF.md` for details

## Additional Resources

- [CONTRIBUTING.md](./CONTRIBUTING.md) - Comprehensive contributor guide
- [CODING_AGENTS.md](./CODING_AGENTS.md) - AI-specific development patterns
- [CLAUDE.md](./CLAUDE.md) - Claude Code specific guidance
- [docs/](./docs/) - Full documentation
- [Shakapacker](https://github.com/shakacode/shakapacker) - Webpack integration
