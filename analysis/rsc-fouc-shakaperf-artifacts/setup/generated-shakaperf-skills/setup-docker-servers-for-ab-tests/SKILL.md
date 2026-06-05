---
name: setup-docker-servers-for-ab-tests
description: Set up shaka-perf twin-servers — the Docker A/B testing infrastructure that runs your app twice (control vs experiment) so visreg/perf can compare two branches. Use this skill whenever the user wants to set up, configure, or debug twin-servers, "dockerize" their app for shaka-perf, write the twin-servers Dockerfile/Procfile/docker-compose, fill in the `twinServers` config, or get `shaka-perf servers` building and running — even if they just say "set up twin servers", "get the A/B servers running", or "make my app run under shaka-perf for perf testing".
argument-hint: [path-to-existing-Dockerfile] [services e.g. postgres,redis,elasticsearch]
---

# setup-docker-servers-for-ab-tests

Twin-servers runs **two production-mode copies of one app side by side** — `control` (the baseline branch) and `experiment` (your branch) — so `shaka-perf compare` can diff them for visual and performance regressions. This skill sets up the Docker infrastructure that makes that happen in the current project.

The whole point is an **apples-to-apples comparison**: control and experiment must be identical in every way _except the application code under test_ — same base image, dependencies, services, environment, data. Any incidental drift (a service only one side has, an env var that differs, a slower disk path) surfaces later as a phantom regression that's brutal to trace. Keep asking: _are these two sides truly identical?_

You produce, under a `twin-servers/` directory in the project:

| File                                   | Purpose                                                          |
| -------------------------------------- | ---------------------------------------------------------------- |
| `twin-servers/Dockerfile`              | Production-mode image (non-root user, embedded services, no CMD) |
| `twin-servers/Dockerfile.dockerignore` | Keeps the build context tight and stable                         |
| `twin-servers/Procfile`                | Tells Overmind which server processes to run per side            |
| `twin-servers/docker-compose.yml`      | **Only if needed** — the bundled default works for most projects |

…plus a few small `TWIN_SERVERS`-gated guards in the app itself. The `twinServers:` slice in `abtests.config.ts` is already there — `shaka-perf init` writes it pre-filled, so you review and adjust it (Phase 1) rather than create it.

## How the pieces run together

- **`shaka-perf servers build`** builds one Docker image per side. It auto-passes `UID`, `GID`, and `NON_ROOT_USER` build args from the host user, plus anything in `dockerBuildArgs`. If the control checkout is missing it offers to `git clone` it for you.
- **`shaka-perf servers start-containers`** brings the containers up with `command: sleep infinity` (they idle — no server yet), then runs your `setupCommands` **in both containers in parallel**.
- **`shaka-perf servers start-servers`** runs Overmind against the `Procfile`, which actually launches the app processes (puma, workers, SSR, …) inside the already-running containers.
- **`shaka-perf servers`** with no subcommand ties it together: rebuild if needed → start containers → interactive menu.

**Default to doing everything in the image.** The Dockerfile should install dependencies, build the app, install backing services, and **run migrations + seed the database at build time** so a built image is fully self-contained. The container then just runs. `setupCommands` and a multi-service docker-compose are escape hatches for the rare bits that genuinely can't be baked in — reach for them only with good reason (Phase 2 and Phase 6 explain when). So: **the Dockerfile builds and seeds the world; the Procfile starts the app; `setupCommands` cover only what can't be baked into the image.**

## Reference docs — load as needed

Detail too bulky for the main flow — read the relevant one when you hit that phase.

| File                                   | Read it when…                                                                                                                                                                                               |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `references/writing-the-dockerfile.md` | Writing or fixing `twin-servers/Dockerfile` — full annotated examples (minimal + a real multi-service app), the non-root-user recipe, embedding Postgres/Redis/Memcached, and every rule with its reasoning |
| `references/compose-and-procfile.md`   | Writing the `Procfile`, or deciding whether you need a custom `docker-compose.yml` and how to pair services per side                                                                                        |
| `references/troubleshooting.md`        | The build/verify loop fails, or before you call it done — failure→fix table and the A/B-diligence checklist                                                                                                 |

---

## Phase 0 — Survey the project (read-only)

Do not write anything yet. First understand what you're dockerizing, because the Dockerfile and config flow directly from it. Investigate:

- **Stack & server command** — Rails/puma? Node/Next? Django? How does the app normally boot in production, on what port? Check `Procfile`, `Procfile.dev`, `config/puma.rb`, `package.json` scripts, `bin/` scripts.
- **Existing production Dockerfile** — is there one to adapt? Adapting an existing, working production image is far safer than writing from scratch. Look in the repo root, `.docker/`, `config/`, CI files.
- **Backing services** — Postgres? MySQL? Redis? Memcached? Elasticsearch? Read `config/database.yml`, `docker-compose*.yml`, `Gemfile`/`package.json`, `.env.example`, and the project's dev-setup docs (README, `bin/setup`). Every service the app needs at runtime must exist for **both** sides.
- **Background processes** — Sidekiq/queues, an SSR/node renderer, asset watchers. Each becomes a Procfile line per side.
- **Runtime versions** — `.ruby-version`, `.node-version`, `package.json#engines`. You will pass these as build args; **never edit these project files** to suit Docker (see the rule in `references/writing-the-dockerfile.md`).
- **Existing setup scripts** — `bin/setup`, `db:prepare`, `db:seed`, migration tasks. Reuse these (run them in the Dockerfile build, so the prepared/seeded state is baked into the image) rather than reinventing them. Keep it DRY.

**Gate — write a short Project Profile before moving on.** A few lines: stack, server start command + port, list of services and how each will be provided (embedded in the image vs. a compose service), background processes, runtime versions, and which existing setup scripts you'll reuse. If you can't fill this in, you haven't surveyed enough — keep digging. This profile is the spec for everything that follows.

---

## Phase 1 — Fill in the `twinServers` config

`shaka-perf init` already wrote a `twinServers:` block in `abtests.config.ts`, pre-filled with sensible defaults: `controlDir` derives from the current dir name + `-control`, and the `CONTROL_PORT` / `EXPERIMENT_PORT` constants are reused so the host-port mapping, the URLs visreg/perf hit, and the Procfile's readiness check can't drift. Review and adjust to the project — the block below is the shape to aim for:

```ts
twinServers: {
  // This checkout is the experiment side.
  experimentDir: process.cwd(),
  // Where the baseline branch lives — defaults to a sibling dir named after
  // this one with `-control` appended. `servers build` offers to clone it here
  // if it doesn't exist yet, using this repo's git remote.
  controlDir: `../${path.basename(process.cwd())}-control`,
  // Docker build context. The SAME relative offset is applied under
  // experimentDir and controlDir when building each side's image.
  dockerBuildDir: '.',
  dockerfile: 'twin-servers/Dockerfile',
  procfile: 'twin-servers/Procfile',
  // Pass runtime versions etc. here — do NOT edit the project's version files.
  dockerBuildArgs: {
    // NODE_VERSION: '20.11.0',
  },
  ports: { control: CONTROL_PORT, experiment: EXPERIMENT_PORT },
  // LAST RESORT — most apps need none. Do all setup (install, build, migrate,
  // seed) in the Dockerfile. setupCommands run in BOTH containers at start;
  // use them only for what can't be baked into an image — chiefly starting an
  // embedded service daemon.
  // setupCommands: [
  //   { command: 'redis-server --daemonize yes', description: 'Starting Redis' },
  // ],
},
```

Notes that save you debugging later:

- **Image names and host volume dirs are auto-derived** from a slug of the project path — you don't (and can't) set them. Two checkouts of the same repo therefore never collide.
- **`composeFile` is optional.** Omit it and the bundled default compose is used. Only add it in Phase 6 if you genuinely need extra services.
- `controlDir`/`experimentDir`/`dockerBuildDir` are resolved relative to the project dir; `~` is expanded.

---

## Phase 2 — Write the production Dockerfile

Create `twin-servers/Dockerfile`. **Read `references/writing-the-dockerfile.md` first** — it has annotated end-to-end examples and the full rationale. The essentials, with the why:

- **Production-mode, but local.** Run as close to real production as possible (same build, asset precompile, env), except prod-only externals (real payment APIs, prod DB) are stubbed and disabled via a `TWIN_SERVERS=true` env var the app checks (Phase 4). Differences from prod are fine; differences _between the two sides_ are not.
- **Non-root user with host-matching UID/GID.** Containers bind-mount a host directory, so the in-container user must match the host user or you get permission errors. Declare `ARG NON_ROOT_USER`, `ARG UID`, `ARG GID` (re-declared after each `FROM`) — `servers build` fills them from the host automatically.
- **Put everything under that user's home** (`/home/$NON_ROOT_USER/app`, `…/bundle`, `…/node`), not `/app` or `/usr/local/...`, to avoid bind-mount permission conflicts.
- **`COPY --chown=$NON_ROOT_USER:$NON_ROOT_USER`** for every copy so the user owns its files.
- **Bake stable non-secret config into `ENV`, not docker-compose.** Placeholder API keys, `TWIN_SERVERS=true`, DB config, and cache endpoints belong in Dockerfile `ENV` so the image is self-contained and identical on both sides. Do not bake real secrets into image `ENV`; pass boot-only dummy values such as `SECRET_KEY_BASE` through the build command or the Procfile/runtime command when possible. Reserve compose `environment:` strictly for the few values that _must_ differ between sides (e.g. `PERF_EXPERIMENT`).
- **Embed backing services in the image** (install Postgres/Redis/Memcached in the Dockerfile) rather than as separate compose services. Simpler, fully isolated per side, no cross-container networking. See `references/writing-the-dockerfile.md`.
- **Do all setup at build time — including migrations and seeding.** Run `db:prepare`/`db:seed` in a `RUN` so the data is baked into the image, identical on both sides. (A _running_ daemon is the one thing you can't bake in — hence the narrow `setupCommands` exception.)
- **Pass runtime versions as build args**, e.g. `ENV NODE_VERSION=...` driven by `dockerBuildArgs`. Don't modify `.node-version`/`.ruby-version`/`engines`.
- **Remove `CMD` and `ENTRYPOINT`.** docker-compose uses `command: sleep infinity` so the container idles and Overmind starts/stops the server independently. Leave an `EXPOSE 3000` (or your port) and a comment explaining the removal.

---

## Phase 3 — Write the dockerignore

Create `twin-servers/Dockerfile.dockerignore`. Docker looks for `<dockerfile-path>.dockerignore` before the context-root `.dockerignore`, so naming it after the Dockerfile keeps twin-servers' ignore rules separate from any existing one. Paths are relative to the **build context** (`dockerBuildDir`), not to `twin-servers/`.

Two reasons it matters:

1. **A tight context builds faster** — don't ship `node_modules`, build artifacts, logs, `tmp`, `.git`, or secrets that are generated/installed inside the image.
2. **Stable context = stable rebuild signal.** twin-servers watches the files Docker actually ingests to decide whether a rebuild is needed. If host-only files (editor saves, host test runs, files the container never reads) are in the context, every such edit needlessly flips the rebuild signal. Ignore anything the container doesn't consume.

---

## Phase 4 — Add `TWIN_SERVERS` guards in the app

The image sets `TWIN_SERVERS=true`. Make the **smallest possible** app changes so production mode runs locally over HTTP without firing real-world side effects. Typical guards (adapt to the stack):

- **Disable forced SSL** — production usually forces HTTPS; twin-servers is local HTTP. e.g. `config.force_ssl = ENV['TWIN_SERVERS'] != 'true'`.
- **Guard external side effects during seeding/boot** — emails, webhooks, third-party API calls. Extend existing dev/test guards: `return if Rails.env.development? || ENV['TWIN_SERVERS'] == 'true'`.
- **Make the DB username configurable** if production hardcodes one that isn't the container user: `username: <%= ENV.fetch('DB_USERNAME', 'original') %>`, then `ENV DB_USERNAME=$NON_ROOT_USER` in the Dockerfile.

Keep these changes minimal and confined — the goal is to dockerize without rewriting the app. Anything you can express as an `ENV` in the Dockerfile, prefer that over touching app code.

---

## Phase 5 — Write the Procfile

Create `twin-servers/Procfile`. One process line per app process **per side**, plus a readiness notifier per side. See `references/compose-and-procfile.md` for SSR/worker variants. Minimal Rails example:

```procfile
control-rails: yarn shaka-perf servers run-overmind-command control "bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:3000"
experiment-rails: yarn shaka-perf servers run-overmind-command experiment "bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:3000"
notify-control-server-started: yarn shaka-perf servers notify-server-started control
notify-experiment-server-started: yarn shaka-perf servers notify-server-started experiment
```

- `run-overmind-command <side> "<cmd>"` runs the command inside that side's container with PID tracking, so Overmind can stop/restart it cleanly. The command binds to `0.0.0.0:3000` _inside_ the container; the host port mapping comes from `ports`.
- `notify-server-started <side>` waits for the side's port (from `ports`), announces it, then idles to keep Overmind happy. Run background workers (Sidekiq, SSR) as their own lines per side — never share a worker between sides.

---

## Phase 6 — Custom docker-compose (only if you actually need it)

The bundled default compose handles the common case (two app containers, bind-mount volumes, the `PERF_EXPERIMENT` flag) — **omit `composeFile` and skip this phase** if you embedded all services in the image, which is the recommended path.

Only write a custom compose when a service genuinely can't be embedded (e.g. it already has a maintained Docker image you want to reuse, like Elasticsearch). If so, run `yarn shaka-perf servers customize-docker-compose` to get an editable copy, and follow the hard rule in `references/compose-and-procfile.md`: **every backing service gets its own `-control` and `-experiment` instance — the two sides must never share one.** Keep it minimal; push everything you can back into the Dockerfile.

---

## Phase 7 — Build and verify (the loop that actually matters)

A setup that looks right but doesn't boot is worth nothing — drive it until both servers actually serve. Budget most of your effort here.

1. **Build.** `yarn shaka-perf servers build` (add `-v` for verbose, `--no-cache` if you suspect a stale layer). If control isn't checked out, accept the clone prompt.
2. **Start containers.** `yarn shaka-perf servers start-containers`. This runs any `setupCommands` in both sides — usually just starting embedded daemons, since install/build/migrate/seed already happened in the image. A db/seed failure should surface during `build`, not here.
3. **Start servers.** `yarn shaka-perf servers start-servers`. This runs Overmind in the **foreground and does not return** — the notifier processes idle to keep it alive. So start it in the background (or a separate terminal) and keep its log, otherwise you'll hang waiting on it. Don't use the interactive no-subcommand `yarn shaka-perf servers` here — its menu needs a human.
4. **Verify both sides respond** — the ground truth. Once the logs show both servers announced, hit each port and confirm a real page, not a 5xx:
   ```bash
   curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:$CONTROL_PORT
   curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:$EXPERIMENT_PORT
   ```
   Don't trust "server started" logs alone — an app can boot and still 500 on every request.
5. **When something fails**, debug inside the container with `yarn shaka-perf servers run-cmd <side> bash` (or run a one-off command). Read `references/troubleshooting.md` for the common failure→fix table (permission errors, missing services, asset/precompile failures, port conflicts, db setup). Fix the Dockerfile / config / guards, then re-run from the right step. Iterate until both sides return success.

**Gate:** both `curl`s return a 2xx/3xx (a real rendered page) before you proceed. If a side only works after a manual fix, fold that fix into the Dockerfile (preferred) — or, if it's an unavoidable runtime step, a minimal `setupCommands` entry — so a clean rebuild reproduces it. A setup that only works by hand is not done.

---

## Phase 8 — A/B diligence review (final gate)

Before declaring success, walk the diligence checklist in `references/troubleshooting.md` and confirm every box — it's the guard against phantom regressions (shared state, env drift, non-deterministic seeds, a leftover `CMD`, project files touched outside scope).

Then summarize for the user: the files you created, services embedded vs. composed, the build/verify result (with the HTTP codes you saw), any app guards you added, and any manual steps still required. Point them at `shaka-perf compare` as the next step now that both servers are up.
