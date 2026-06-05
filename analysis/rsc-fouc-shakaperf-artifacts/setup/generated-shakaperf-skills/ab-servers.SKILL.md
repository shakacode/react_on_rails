---
name: ab-servers
description: How to drive shaka-perf twin-servers (the control + experiment Docker pair) from an agent — which subcommand to use for build, start containers, start the app, stop, run a command inside a side, or sync code changes. Bare `shaka-perf servers` is for humans (interactive menu); agents must call subcommands directly. Use whenever you need to bring twin-servers up, restart them after a change, or run something inside a container. Triggers include "servers", "twin servers", "ab servers", "control/experiment server", "run X in  container", "ab tests failing".
---

# Driving twin-servers from an agent

`shaka-perf servers` (no subcommand) auto-rebuilds, starts containers, then drops into an **interactive menu** — that's the path for humans, not agents. As an agent, call the subcommands directly.

## The dispatch table is the documentation

| Subcommand | With `shaka-perf servers` running → **proxied** | Without `shaka-perf servers` → **local** |
|---|---|---|
| `build [--target control\|experiment] [--no-cache]` | Rebuilds image(s) **and restarts the servers** (containers re-created — in-container state reset). | Builds the Docker image(s) only; doesn't touch a running session. |
| `start-containers` | Recreates containers **and restarts the servers** (state reset). | Brings containers up idle and runs `setupCommands` on both sides. |
| `stop-containers` | Stops containers and ends the menu session. | Stops containers and removes volumes. |
| `start-servers` | Restarts overmind in the live session (containers untouched). | Launches the app via Overmind in this terminal — **blocks**; run in background. |
| `run-cmd <control\|experiment> <cmd>` | Same as local — `docker exec`s into the named side (queued behind any in-flight lifecycle work). | Runs a one-off command inside the named side via `docker exec`. |
| `run-cmd-parallel <cmd>` | Same as local — `docker exec`s into both sides in parallel (queued behind lifecycle work). | Runs the same command in both containers in parallel. |
| `sync-changes <control\|experiment>` | **Fails** — the menu's `fs.watch` already auto-syncs the build context on every save; re-running would race the watcher. Just edit your files. | Syncs local git changes into the side's bind-mount volume. |
| `get-config <key>` | Local — pure read; the value belongs on the caller's stdout. | Reads a resolved config field (e.g. `dockerfile`, `ports`). |
| `say <message>` | Local. | Speaks the message via TTS (macOS/Linux). |
| `notify-server-started <control\|experiment>` | Local — Procfile helper. | Waits for the side's URL to respond, announces it via TTS, then sleeps to keep Overmind happy. |
| `run-overmind-command <control\|experiment> <cmd>` | Local — Procfile helper. | Runs a command inside a container with PID tracking (used inside Procfile lines). |
| `copy-changes-to-ssh <port> <host> [control\|experiment\|all]` | Local. | Copies local git changes to a CI SSH host for debugging. |
| `forward-ports <port> <host> [controlPort] [experimentPort]` | Local. | Forwards CI container ports to localhost via SSH. |
| `customize-docker-compose` | Local. | Copies the bundled `docker-compose.yml` into the project for local editing. |

**Lifecycle from cold start (no menu)**: `build` → `start-containers` → `start-servers`. Inside a running menu, the proxied versions of `build` / `start-containers` already include the restart step.

## Behaviour with `shaka-perf servers` running

The proxied work runs *inside* the menu's process, so its logs land in the user's interactive window and you just see the exit code on stderr after a `→ proxying to running shaka-perf servers (pid …)` notice.

- If another action is already in flight (menu item or earlier proxied command), your subcommand **queues** on the menu's session lock and the client just hangs until the slot opens — no fast-fail.
- Exit code `75` (`EX_TEMPFAIL`) is reserved for terminal states only: the menu is shutting down, or hadn't finished booting yet — try again in a moment.
- To change the running servers' environment (env vars, config file), ask the user to kill the interactive `shaka-perf servers` so your direct subcommands can take over.
