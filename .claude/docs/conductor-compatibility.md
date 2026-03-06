# Conductor Compatibility (mise Version Manager)

## Problem

Conductor and coding agents run commands in non-interactive shells that don't source `.zshrc`. Without additional setup, mise's shell hook never runs and commands use system Ruby/Node instead of project-specified versions.

**Symptoms:**

- `ruby --version` returns system Ruby (e.g., 2.6.10) instead of project Ruby (e.g., 3.3.4)
- Pre-commit hooks fail with wrong tool versions
- `bundle` commands fail due to incompatible Ruby versions
- Node/pnpm commands use wrong Node version

## Preferred Solution: Shell-Level mise Shims

The best fix is to activate mise shims in startup files used by non-interactive shells:

1. **`.zshenv`** — activate `mise activate zsh --shims` (runs for all zsh shells, including non-interactive)
2. **`~/.bash_env`** — a minimal, script-safe file for non-interactive `bash` shells
3. **`.profile`** — optionally activate `mise activate bash --shims` for login `sh` shells when `/bin/sh` is bash-compatible (for example, macOS); if your `/bin/sh` rejects it (common with `dash`), skip this step and use `conductor-exec` for `sh` paths
4. **Export `BASH_ENV` and `ENV`** from `.zshenv` — `BASH_ENV` makes non-interactive `bash -c` source `~/.bash_env`; `ENV` only affects interactive `sh`/`dash` (non-interactive `sh -c` and `#!/bin/sh` still need `conductor-exec`)

Example `.zshenv`:

```zsh
# Activate mise shims for ALL zsh shells (interactive + non-interactive).
# Non-interactive shells (Conductor, coding agents, tool calls) never source .zshrc,
# so without this they get system Ruby/Node instead of mise-managed versions.
# In interactive shells, `mise activate zsh` in .zshrc overrides shims with faster direct paths.
if [ -x /opt/homebrew/bin/mise ]; then
  eval "$(/opt/homebrew/bin/mise activate zsh --shims)"
elif [ -x /usr/local/bin/mise ]; then
  eval "$(/usr/local/bin/mise activate zsh --shims)"
elif [ -x /usr/bin/mise ]; then
  eval "$(/usr/bin/mise activate zsh --shims)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
fi

# Export BASH_ENV so non-interactive bash child processes source a minimal file.
# Avoid pointing BASH_ENV at .bashrc: interactive guards can skip activation and
# heavy .bashrc setup slows every non-interactive bash invocation.
export BASH_ENV="$HOME/.bash_env"

# ENV is only sourced by interactive POSIX sh/dash shells.
# It does not help with non-interactive sh -c or #!/bin/sh scripts.
export ENV="$HOME/.profile"
```

Example `~/.bash_env` (minimal and script-safe):

```bash
if [ -x /opt/homebrew/bin/mise ]; then
  eval "$(/opt/homebrew/bin/mise activate bash --shims)"
elif [ -x /usr/local/bin/mise ]; then
  eval "$(/usr/local/bin/mise activate bash --shims)"
elif [ -x /usr/bin/mise ]; then
  eval "$(/usr/bin/mise activate bash --shims)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash --shims)"
fi
```

Using a dedicated `~/.bash_env` avoids the common `.bashrc` silent failure where a non-interactive guard such as
`[ -z "$PS1" ] && return` or `[[ $- != *i* ]] && return` exits before the mise snippet runs.
If you still point `BASH_ENV` at `.bashrc`, place the activation block before any such guard.

Example `.profile` (optional; safest with a bash guard so `dash`/strict `sh` just skip it):

```sh
if [ -n "${BASH_VERSION:-}" ]; then
  if [ -x /opt/homebrew/bin/mise ]; then
    eval "$(/opt/homebrew/bin/mise activate bash --shims)"
  elif [ -x /usr/local/bin/mise ]; then
    eval "$(/usr/local/bin/mise activate bash --shims)"
  elif [ -x /usr/bin/mise ]; then
    eval "$(/usr/bin/mise activate bash --shims)"
  elif [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash --shims)"
  fi
fi
```

Do not use full `mise activate bash` in `.profile`; that output is bash-specific.

With this setup, most `zsh` and `bash` commands get mise-managed tool versions automatically.
Keep `bin/conductor-exec` for non-interactive `sh`/`dash` paths (`sh -c`, `#!/bin/sh`) and other cases where startup files are skipped.

`mise activate --shims` is a compatibility trade-off, not full shell activation: most shell hooks do not run, `mise.toml` env vars are applied when a shimmed tool executes instead of across the whole shell, and `which <tool>` points to the shim rather than the real binary. Use `bin/conductor-exec` (or raw `mise exec --`) when you need a single command to run under the full mise-managed environment or want to sidestep shim shadowing while debugging.

**Caveat:** Ensure no system binaries shadow mise shims on PATH (for example, `/usr/local/bin/node`). If they do, prefer reordering PATH so the mise shims win, renaming or moving a user-installed conflicting binary, or using `conductor-exec` as a fallback. Only remove a conflicting binary if you're sure nothing else depends on it.

## Fallback: `bin/conductor-exec` Wrapper

If you haven't configured shell-level shims, use the `bin/conductor-exec` wrapper. It calls `mise exec --`, which prepends the correct tool directories to PATH for the invoked command:

```bash
bin/conductor-exec bundle exec ruby --version
bin/conductor-exec bundle exec rubocop
bin/conductor-exec pnpm install
bin/conductor-exec git commit -m "message"  # Pre-commit hooks work correctly
```

## Reference

See [react_on_rails-demos#105](https://github.com/shakacode/react_on_rails-demos/issues/105) for detailed problem analysis and solution development.
