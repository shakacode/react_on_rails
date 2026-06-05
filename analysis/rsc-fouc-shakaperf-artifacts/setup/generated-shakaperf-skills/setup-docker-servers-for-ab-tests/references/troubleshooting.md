# Build/verify troubleshooting & A/B diligence

## Debugging inside the containers

The containers idle on `sleep infinity`, so you can poke around without anything crashing:

```bash
yarn shaka-perf servers run-cmd experiment bash      # interactive shell, one side
yarn shaka-perf servers run-cmd control "bundle exec rails runner 'puts 1'"  # one-off
yarn shaka-perf servers run-cmd-parallel "df -h"     # same command, both sides
```

Re-run a single build side after a Dockerfile fix instead of both: `yarn shaka-perf servers build -t experiment`. Add `-v` for the full docker output, `--no-cache` when you suspect a stale layer.

## Common failures → fixes

| Symptom                                                                                   | Likely cause & fix                                                                                                                                                                                                                                                                            |
| ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `EACCES` / permission denied writing logs, pids, db, assets                               | Container user UID/GID ≠ host, or files copied as root. Confirm the non-root user recipe (`writing-the-dockerfile.md`), use `COPY --chown`, and keep all paths under `/home/$NON_ROOT_USER`. Don't hardcode `UID`/`GID` — let `servers build` inject the host's.                              |
| Build can't find `Gemfile`/`package.json`/app files                                       | `dockerBuildDir` (build context) is wrong, or the dockerignore excludes them. Paths in `COPY` are relative to the context; paths in `Dockerfile.dockerignore` are too.                                                                                                                        |
| Build's `db:prepare`/`db:seed` step: "could not connect to server" / "connection refused" | The embedded service isn't running inside that `RUN`. Start it in the _same_ `RUN` before seeding (`initdb && pg_ctl start && rails db:prepare && rails db:seed && pg_ctl stop`) — service daemons don't persist between `RUN` layers.                                                        |
| `db:prepare` fails on auth / role does not exist                                          | DB username mismatch. Make `database.yml` username `ENV.fetch('DB_USERNAME', …)` and set `ENV DB_USERNAME=$NON_ROOT_USER` (Phase 4). For embedded Postgres, `initdb` creates a superuser matching the OS user — align them.                                                                   |
| App boots but every request 500s                                                          | Read container logs: `run-cmd <side> "tail -n 100 log/production.log"`. Usual culprits: a missing runtime `SECRET_KEY_BASE` or Docker `ENV`, a prod-only external call not guarded by `TWIN_SERVERS`, assets not precompiled, or an embedded daemon not started at runtime (its one legit `setupCommands` use). |
| Data missing / "no such table" at runtime though seeding ran at build                     | The seeded data wasn't baked where it survives. Put it outside the bind-mounted app dir (e.g. `~/pgdata`), or under the app dir (Docker repopulates the named volume from the image on start). Don't seed in `setupCommands` instead — fix where the build writes it.                         |
| Redirected to https / "page isn't redirecting properly"                                   | `force_ssl` still on. Gate it: `config.force_ssl = ENV['TWIN_SERVERS'] != 'true'`.                                                                                                                                                                                                            |
| Real emails/webhooks/API calls fire during the build's seed step                          | Seeding side effects not guarded. Add `return if ENV['TWIN_SERVERS'] == 'true'` (alongside the existing dev/test guard) and set third-party keys to skip/placeholder in `ENV`.                                                                                                                |
| `notify-server-started` times out though the app seems up                                 | The app isn't actually serving on the in-container `0.0.0.0:3000`, or `ports` in config doesn't match the host mapping. Confirm the server binds `0.0.0.0` (not `127.0.0.1`) and the Procfile/compose/`ports` all agree.                                                                      |
| "address already in use" on start                                                         | A previous Overmind/container left something bound. `yarn shaka-perf servers stop-containers`, remove a stale `.overmind.sock` in the project dir, then retry. Or the host port is taken — the config's `assignPortsAutomatically` normally avoids this.                                      |
| asset precompile fails for missing secret                                                 | Use a dummy only for that build command, for example `SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile` or `SECRET_KEY_BASE=dummy bundle exec rails assets:precompile`; avoid leaving secrets in image `ENV`.                                                                        |
| Image rebuilds on every run despite no real change                                        | Host-only files are in the build context. Tighten `Dockerfile.dockerignore` to exclude editor saves, host `node_modules`, test output — anything the container never reads.                                                                                                                   |
| `overmind: command not found`                                                             | Install it: `brew install overmind` (mac) / `go install github.com/DarthSim/overmind/v2@latest` (linux). `dockerize` and GNU `parallel` are also prerequisites.                                                                                                                               |

When a fix works only when applied by hand, fold it back into the Dockerfile (preferred — it bakes into the image) or, if it's an unavoidable runtime step like starting a daemon, a minimal `setupCommands` entry. A clean `build` + `start-containers` must reproduce a working setup on its own.

## A/B diligence checklist (Phase 8)

Twin-servers attributes every visual/perf difference to the code under test, so any difference the _harness_ introduces is a false regression — and those are brutal to diagnose after the fact. Verify, concretely:

- [ ] **Same base everything** — same base image tag, same dependency lockfiles, same embedded service versions on both sides. The Dockerfile is shared, so this is automatic _unless_ you branched logic on the side; don't.
- [ ] **No shared services or state** — each side has its own DB data dir, cache, search index, and bind-mount volume. Nothing is reachable from both. (Embedded services give this for free; composed services need the per-side `-control`/`-experiment` split.)
- [ ] **Env parity** — diff the two sides' `environment:` in compose. The only entries that may differ are the side flag (`PERF_EXPERIMENT`) and per-side service URLs. Everything else lives in the image identically.
- [ ] **Deterministic, identical seed data** — the build's migrate+seed (baked into the image) produces the same data on both sides, and any `setupCommands` are deterministic too. Random or time-based seeds make screenshots diverge for no real reason.
- [ ] **No leftover `CMD`/`ENTRYPOINT`** in the Dockerfile; Overmind owns the lifecycle.
- [ ] **Project untouched outside scope** — only `twin-servers/`, the `twinServers` config slice, and the minimal `TWIN_SERVERS` guards changed. Runtime version files (`.node-version`, `.ruby-version`, `engines`) are exactly as they were.
- [ ] **Both sides verified serving** — you saw real 2xx/3xx responses (Phase 7), not just "started" logs.
