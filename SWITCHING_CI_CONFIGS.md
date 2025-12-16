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
- **Shakapacker**: 9.4.0
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

You must have a version manager installed to manage Ruby and Node versions. The script supports:

- **[mise](https://mise.jdx.dev/)** - Recommended, modern, manages both Ruby and Node
- **[asdf](https://asdf-vm.com/)** - Legacy option, manages both Ruby and Node
- **[rvm](https://rvm.io/) + [nvm](https://github.com/nvm-sh/nvm)** - Separate managers for Ruby and Node

### Option 1: mise (Recommended)

```bash
# Install mise
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# mise automatically reads from .tool-versions
```

### Option 2: asdf

```bash
# Install asdf
brew install asdf
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc

# Install plugins
asdf plugin add ruby
asdf plugin add nodejs
```

### Option 3: rvm + nvm

```bash
# Install rvm for Ruby
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm

# Install nvm for Node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
# Add to shell config (the installer usually does this automatically)
```

**Important Notes:**

- If you only have rvm (no nvm) or only nvm (no rvm), the script will detect this and provide helpful error messages guiding you to install the missing manager or switch to mise/asdf.
- **Do not mix version managers** (e.g., don't install both mise and rvm). The script prioritizes mise > asdf > rvm+nvm, so mise/asdf will always take precedence. Using multiple managers can cause confusion about which versions are active.

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
   - Shakapacker 9.4.0 → 8.2.0
   - React 19.0.0 → 18.0.0
   - Remove ESLint and other packages incompatible with Node 20
3. Clean `node_modules` and `pnpm-lock.yaml`
4. Reinstall dependencies without `--frozen-lockfile`
5. Clean and reinstall react_on_rails/spec/dummy dependencies

**After switching, run:**

```bash
# Reload your shell to pick up new Ruby/Node versions
cd <project-root>
mise current           # For mise users
# asdf current         # For asdf users
# rvm current && nvm current  # For rvm+nvm users

# Build and test
rake node_package
cd react_on_rails/spec/dummy
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
3. Clean `node_modules` and `pnpm-lock.yaml`
4. Reinstall dependencies with `--frozen-lockfile`
5. Clean and reinstall react_on_rails/spec/dummy dependencies

**After switching, run:**

```bash
# Reload your shell to pick up new Ruby/Node versions
cd <project-root>
mise current           # For mise users
# asdf current         # For asdf users
# rvm current && nvm current  # For rvm+nvm users

# Build and test
rake node_package
cd react_on_rails/spec/dummy
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
- `react_on_rails/spec/dummy/package.json` - React and Shakapacker versions
- `packages/react-on-rails-pro/package.json` - Test scripts modified
- `node_modules/`, `pnpm-lock.yaml` - Cleaned and regenerated
- `react_on_rails/spec/dummy/node_modules/`, `react_on_rails/spec/dummy/pnpm-lock.yaml` - Cleaned and regenerated

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
cd react_on_rails/spec/dummy
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
cd react_on_rails/spec/dummy && bin/shakapacker-precompile-hook && RAILS_ENV=test bin/shakapacker && cd ../..
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

**For rvm + nvm:**

```bash
# Install and use specific Ruby version
rvm install 3.2.8   # or 3.4.3
rvm use 3.2.8

# Install and use specific Node version
nvm install 20.18.1  # or 22.12.0
nvm use 20.18.1

# Verify versions
ruby --version
node --version
```

### PNPM install fails

If you get package resolution errors:

```bash
# Clean everything and try again
rm -rf node_modules pnpm-lock.yaml react_on_rails/spec/dummy/node_modules react_on_rails/spec/dummy/pnpm-lock.yaml
pnpm install -r
cd react_on_rails/spec/dummy && pnpm install
```

### Git complains about modified files

The script will warn you if you have uncommitted changes. You can:

- Commit or stash your changes first, OR
- Proceed (script will ask for confirmation)

### Switching back doesn't restore everything

If `git restore` doesn't work:

```bash
# Manually restore from git
git restore Gemfile.development_dependencies package.json react_on_rails/spec/dummy/package.json packages/react-on-rails-pro/package.json

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
