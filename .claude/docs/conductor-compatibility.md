# Conductor Compatibility (mise Version Manager)

## Problem

Conductor and coding agents run commands in non-interactive shells that don't source `.zshrc`. Without additional setup, mise's shell hook never runs and commands use system Ruby/Node instead of project-specified versions.

## Preferred Solution: Shell-Level mise Shims

The best fix is to activate mise shims in shell startup files that run for **all** shell types (interactive and non-interactive):

1. **`.zshenv`** — activate `mise activate zsh --shims` (runs for all zsh shells, including non-interactive)
2. **`.bashrc`** — activate `mise activate bash --shims` (for bash subprocesses)
3. **`.profile`** — activate `mise activate bash --shims` (for sh/login shells)
4. **Export `BASH_ENV` and `ENV`** from `.zshenv` — so non-interactive bash/sh child processes also get shims

See [justin808-dotfiles](https://github.com/justin808/justin808-dotfiles) for a reference implementation.

With this setup, `bin/conductor-exec` is unnecessary — all shells automatically get mise-managed tool versions.

**Caveat:** Ensure no system binaries shadow mise shims on PATH (e.g., `/usr/local/bin/node`). If they do, either remove the conflicting binary or use `conductor-exec` as a fallback.

## Fallback: `bin/conductor-exec` Wrapper

If you haven't configured shell-level shims, use the `bin/conductor-exec` wrapper. It calls `mise exec --` which bypasses PATH entirely:

```bash
bin/conductor-exec ruby --version
bin/conductor-exec bundle exec rubocop
bin/conductor-exec pnpm install
bin/conductor-exec git commit -m "message"  # Pre-commit hooks work correctly
```

## Reference

See [react_on_rails-demos#105](https://github.com/shakacode/react_on_rails-demos/issues/105) for detailed problem analysis and solution development.
