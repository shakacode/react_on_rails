# Conductor Compatibility (mise Version Manager)

## Problem

Conductor runs commands in a non-interactive shell that doesn't source `.zshrc`. This means mise's shell hook (which reorders PATH based on `.tool-versions`) never runs. Commands will use system Ruby/Node instead of project-specified versions.

**Symptoms:**

- `ruby --version` returns system Ruby (e.g., 2.6.10) instead of project Ruby (e.g., 3.3.4)
- Pre-commit hooks fail with wrong tool versions
- `bundle` commands fail due to incompatible Ruby versions
- Node/pnpm commands use wrong Node version

## Solution

Use the `bin/conductor-exec` wrapper to ensure commands run with correct tool versions:

```bash
# Instead of:
ruby --version
bundle exec rubocop
pnpm install
git commit -m "message"

# Use:
bin/conductor-exec ruby --version
bin/conductor-exec bundle exec rubocop
bin/conductor-exec pnpm install
bin/conductor-exec git commit -m "message"  # Pre-commit hooks work correctly
```

## Reference

See [react_on_rails-demos#105](https://github.com/shakacode/react_on_rails-demos/issues/105) for detailed problem analysis and solution development.
