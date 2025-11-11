# Switching Between CI Configurations Locally

This guide explains how to switch between different CI test configurations locally to replicate CI failures.

## Quick Start

```bash
# Check your current configuration
bin/ci-switch-config status

# Switch to minimum dependencies (Ruby 3.2, Node 20)
bin/ci-switch-config minimum

# Switch back to latest dependencies (Ruby 3.4, Node 22)
bin/ci-switch-config latest
```

## CI Configurations

The project runs tests against two configurations:

### Latest (Default Development)

- **Ruby**: 3.4
- **Node**: 22
- **Shakapacker**: 9.3.0
- **React**: 19.0.0
- **Dependencies**: Latest versions with `--frozen-lockfile`
- **When it runs**: Always on PRs and master

### Minimum (Compatibility Testing)

- **Ruby**: 3.2
- **Node**: 20
- **Shakapacker**: 8.2.0
- **React**: 18.0.0
- **Dependencies**: Minimum supported versions
- **When it runs**: Only on master branch

## When to Switch Configurations

**Switch to minimum when:**

- CI fails on `dummy-app-integration-tests (3.2, 20, minimum)` but passes on latest
- You're debugging compatibility with older dependencies
- You want to verify minimum version support before releasing

**Switch to latest when:**

- You're done testing minimum configuration
- You want to return to normal development
- CI failures are on latest configuration

## Prerequisites

You must have a version manager like [mise](https://mise.jdx.dev/) (recommended) or [asdf](https://asdf-vm.com/) installed to manage Ruby and Node versions.

```bash
# Install mise (recommended, modern alternative to asdf)
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# OR install asdf (legacy option)
brew install asdf
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc

# Install plugins (only needed for asdf, mise reads from mise.toml)
asdf plugin add ruby
asdf plugin add nodejs
```

## Detailed Usage

### 1. Check Current Configuration

```bash
bin/ci-switch-config status
```

This shows:

- Current Ruby and Node versions
- Dependency versions (Shakapacker, React)
- Which configuration you're currently on

### 2. Switch to Minimum Configuration

```bash
bin/ci-switch-config minimum
```

This will:

1. Create `.tool-versions` with Ruby 3.2.8 and Node 20.18.1
2. Run `script/convert` to downgrade dependencies:
   - Shakapacker 9.3.0 → 8.2.0
   - React 19.0.0 → 18.0.0
   - Remove ESLint and other packages incompatible with Node 20
3. Clean `node_modules` and `yarn.lock`
4. Reinstall dependencies without `--frozen-lockfile`
5. Clean and reinstall spec/dummy dependencies

**After switching, run:**

```bash
# Reload your shell to pick up new Ruby/Node versions
cd <project-root>
mise current  # or: asdf current

# Build and test
rake node_package
cd spec/dummy
bin/shakapacker-precompile-hook
RAILS_ENV=test bin/shakapacker
cd ../..
bundle exec rake run_rspec:all_dummy
```

### 3. Switch Back to Latest Configuration

```bash
bin/ci-switch-config latest
```

This will:

1. Create `.tool-versions` with Ruby 3.4.3 and Node 22.12.0
2. Restore files from git (reverting changes made by `script/convert`)
3. Clean `node_modules` and `yarn.lock`
4. Reinstall dependencies with `--frozen-lockfile`
5. Clean and reinstall spec/dummy dependencies

**After switching, run:**

```bash
# Reload your shell to pick up new Ruby/Node versions
cd <project-root>
mise current  # or: asdf current

# Build and test
rake node_package
cd spec/dummy
bin/shakapacker-precompile-hook
RAILS_ENV=test bin/shakapacker
cd ../..
bundle exec rake run_rspec:all_dummy
```

## What Gets Modified

When switching to **minimum**, these files are modified:

- `.tool-versions` - Ruby/Node versions
- `Gemfile.development_dependencies` - Shakapacker gem version
- `package.json` - React versions, dev dependencies removed
- `spec/dummy/package.json` - React and Shakapacker versions
- `packages/react-on-rails-pro/package.json` - Test scripts modified
- `node_modules/`, `yarn.lock` - Cleaned and regenerated
- `spec/dummy/node_modules/`, `spec/dummy/yarn.lock` - Cleaned and regenerated

When switching to **latest**, these files are restored from git.

## Common Workflows

### Debugging a Minimum Config CI Failure

```bash
# 1. Check current config
bin/ci-switch-config status

# 2. Switch to minimum
bin/ci-switch-config minimum

# 3. Reload shell
cd <project-root>

# 4. Verify versions changed
ruby --version  # Should show 3.2.x
node --version  # Should show v20.x

# 5. Build and test
rake node_package
cd spec/dummy
bin/shakapacker-precompile-hook
RAILS_ENV=test bin/shakapacker
cd ../..

# 6. Run the failing tests
bundle exec rake run_rspec:all_dummy

# 7. Fix the issue

# 8. Switch back when done
bin/ci-switch-config latest
```

### Quick Test in Both Configurations

```bash
# Test in latest (current default)
bin/ci-switch-config status
bundle exec rake run_rspec:all_dummy

# Switch and test in minimum
bin/ci-switch-config minimum
rake node_package
cd spec/dummy && bin/shakapacker-precompile-hook && RAILS_ENV=test bin/shakapacker && cd ../..
bundle exec rake run_rspec:all_dummy

# Switch back
bin/ci-switch-config latest
```

## Troubleshooting

### "No version is set for ruby" or version didn't change

After switching, you need to reload your shell:

```bash
cd <project-root>
# The cd command will trigger mise/asdf to load the new versions
ruby --version  # Verify it changed
```

### Ruby/Node version didn't change

If your version manager doesn't automatically switch:

**For mise:**

```bash
mise install  # Install missing versions from mise.toml or .tool-versions
```

**For asdf:**

```bash
asdf install  # Install missing versions from .tool-versions
asdf reshim ruby
asdf reshim nodejs
```

### Yarn install fails

If you get package resolution errors:

```bash
# Clean everything and try again
rm -rf node_modules yarn.lock spec/dummy/node_modules spec/dummy/yarn.lock
yarn install
cd spec/dummy && yarn install
```

### Git complains about modified files

The script will warn you if you have uncommitted changes. You can:

- Commit or stash your changes first, OR
- Proceed (script will ask for confirmation)

### Switching back doesn't restore everything

If `git restore` doesn't work:

```bash
# Manually restore from git
git restore Gemfile.development_dependencies package.json spec/dummy/package.json packages/react-on-rails-pro/package.json

# Then run latest again
bin/ci-switch-config latest
```

## Integration with CI Debugging Tools

This script works well with the other CI debugging tools:

```bash
# 1. Check what failed in CI
bin/ci-rerun-failures

# 2. If it's a minimum config failure, switch
bin/ci-switch-config minimum

# 3. Run the specific failing tests
pbpaste | bin/ci-run-failed-specs

# 4. Switch back when done
bin/ci-switch-config latest
```

## See Also

- `CLAUDE.md` - Main development guide with CI debugging info
- `bin/ci-rerun-failures` - Re-run only failed CI jobs locally
- `bin/ci-run-failed-specs` - Run specific failing RSpec examples
- `bin/ci-local` - Smart test detection based on changes
