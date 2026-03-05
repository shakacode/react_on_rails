# Conductor Compatibility (mise Version Manager)

## Problem

Conductor and coding agents run commands in non-interactive shells that don't source `.zshrc`. Without additional setup, mise's shell hook never runs and commands use system Ruby/Node instead of project-specified versions.

## Preferred Solution: Shell-Level mise Shims

The best fix is to activate mise shims in shell startup files that run for **all** shell types (interactive and non-interactive):

1. **`.zshenv`** — activate `mise activate zsh --shims` (runs for all zsh shells, including non-interactive)
2. **`.bashrc`** — activate `mise activate bash --shims` (for bash subprocesses)
3. **`.profile`** — activate `mise activate bash --shims` (for sh/login shells)
4. **Export `BASH_ENV` and `ENV`** from `.zshenv` — so non-interactive bash/sh child processes also get shims

Example `.zshenv`:

```bash
# Activate mise shims for ALL zsh shells (interactive + non-interactive).
# Non-interactive shells (Conductor, coding agents, tool calls) never source .zshrc,
# so without this they get system Ruby/Node instead of mise-managed versions.
# In interactive shells, `mise activate zsh` in .zshrc overrides shims with faster direct paths.
if [ -x /opt/homebrew/bin/mise ]; then
  eval "$(/opt/homebrew/bin/mise activate zsh --shims)"
elif [ -x /usr/local/bin/mise ]; then
  eval "$(/usr/local/bin/mise activate zsh --shims)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
fi

# Export BASH_ENV and ENV so non-interactive bash/sh child processes also get mise shims.
export BASH_ENV="$HOME/.bashrc"
export ENV="$HOME/.profile"
```

Example `.bashrc` and `.profile` (both similar):

```bash
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash --shims)"
fi
```

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
