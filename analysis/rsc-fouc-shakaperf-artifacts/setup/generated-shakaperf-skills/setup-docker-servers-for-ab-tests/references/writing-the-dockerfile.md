# twin-servers Dockerfile reference

How to write `twin-servers/Dockerfile` so both sides build into identical, bind-mountable, production-mode images that Overmind can drive.

## Contents

- [The rules and why they exist](#the-rules-and-why-they-exist)
- [The non-root user recipe](#the-non-root-user-recipe)
- [Embedding backing services](#embedding-backing-services)
- [Example 1 — minimal Rails app](#example-1--minimal-rails-app)
- [Example 2 — real multi-service app](#example-2--real-multi-service-app)

---

## The rules and why they exist

**Adapt an existing production Dockerfile if one exists.** A working prod image already solves the hard parts (dependency install, asset build, version pinning). Copy it into `twin-servers/Dockerfile` and apply the changes below, rather than starting blank.

**Multi-stage build.** A `base` stage with the runtime, a `build` stage that installs deps and compiles assets (it may need root + build-essential), and a lean `production` stage that copies only the built artifacts. This keeps the final image small and the two sides fast to rebuild.

**Non-root user with host-matching UID/GID — the single most important rule.** twin-servers bind-mounts a host directory into the container so you can inspect/edit code without rebuilding. If the container writes as root (or any UID ≠ the host user), the host sees root-owned files and the container can't write host-owned files — every db-prepare, log write, or asset build then fails with EACCES. Declaring `ARG UID`/`GID`/`NON_ROOT_USER` lets `servers build` inject the host identity so the two match. ARGs do **not** survive a `FROM`, so re-declare them at the top of every stage that uses them.

**Everything under the user's home.** Use `/home/$NON_ROOT_USER/app`, `…/bundle`, `…/node`. Paths like `/app` or `/usr/local/bundle` are root-owned and collide with the bind mount. Home-relative paths are owned by the non-root user from the start.

**`COPY --chown` on every copy in the build stage.** Files copied without `--chown` land as root. One `--chown=$NON_ROOT_USER:$NON_ROOT_USER` per `COPY` is cheaper and more reliable than chowning afterward.

**Recreate writable dirs in the production stage.** `log`, `tmp/pids`, `tmp/cache`, `storage` (and any runtime-written dir) must exist and be owned by the user — `mkdir -p … && chown -R`.

**Config goes in `ENV`, not docker-compose.** Bake `SECRET_KEY_BASE`, placeholder/skip values for third-party API keys, `TWIN_SERVERS=true`, cache server addresses, and DB config as `ENV` directives. Why: the image becomes self-contained and provably identical on both sides, and compose stays a thin per-side differentiator. The _only_ things that belong in compose `environment:` are values that must differ between control and experiment.

**Pass runtime versions as build args; never edit the project's version files.** Dockerizing must not require touching `.node-version`, `.ruby-version`, `package.json#engines`, or any app file outside `twin-servers/` and the minimal `TWIN_SERVERS` guards. Drive the version from `dockerBuildArgs` → `ARG`/`ENV` in the Dockerfile. If you change `.node-version` to make Docker happy, you've changed what every developer and CI runs.

**Remove `CMD` and `ENTRYPOINT`.** docker-compose sets `command: sleep infinity`, so the container idles and Overmind owns the server lifecycle (start/stop/restart a single process without bouncing the container). Keep `EXPOSE <port>` and leave a comment:

```dockerfile
EXPOSE 3000

# For twin-servers A/B testing: CMD and ENTRYPOINT are removed.
# docker-compose uses 'command: sleep infinity' instead, so servers can be
# started/stopped via Overmind without restarting containers.
```

---

## The non-root user recipe

This block (in the `base` stage) creates a user whose UID/GID match the host. The `groupdel` line handles macOS hosts whose primary GID (e.g. 20 = `staff`) already exists in the Debian base image.

```dockerfile
ARG NON_ROOT_USER=rails
ARG UID=1000
ARG GID=1000
ARG APP_PATH=/home/${NON_ROOT_USER}/app

FROM ruby:${RUBY_VERSION}-bullseye AS base

# Re-declare after FROM — ARGs don't cross stage boundaries.
ARG NON_ROOT_USER
ARG UID
ARG GID
ARG APP_PATH

# macOS/Linux GID compatibility: drop any pre-existing group on that GID.
RUN getent group $GID | cut -d: -f1 | xargs -r groupdel || true

RUN groupadd --gid $GID ${NON_ROOT_USER} && \
    useradd ${NON_ROOT_USER} --uid $UID --gid $GID --create-home --shell /bin/bash
RUN mkdir -p $APP_PATH && chown -R ${NON_ROOT_USER}:${NON_ROOT_USER} /home/${NON_ROOT_USER}
WORKDIR $APP_PATH
USER ${NON_ROOT_USER}
```

---

## Embedding backing services

Install Postgres/Redis/Memcached **into the image**, over running them as separate docker-compose services. Each side then owns its own fully isolated copy with zero cross-container networking — exactly the isolation A/B testing demands. (The exception: a service with a maintained official image you'd rather reuse, like Elasticsearch — see `compose-and-procfile.md`.)

Install in the Dockerfile (Postgres example needs the PGDG apt repo for newer majors; Redis ≥6.2 needs the redis.io repo on Bullseye):

```dockerfile
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      postgresql-14 redis-server memcached libpq5 \
    && rm -rf /var/lib/apt/lists/*
ENV PATH=/usr/lib/postgresql/14/bin:$PATH
```

### Prepare and seed the database at build time, not at runtime

The default is to bake **everything** into the image, including a fully migrated and seeded database. Do it in a `RUN` step that starts the DB, runs the setup, and stops it — the data directory becomes part of the image:

```dockerfile
RUN initdb -D ~/pgdata && \
    pg_ctl -D ~/pgdata -l ~/pgdata/logfile start && \
    bin/rails db:prepare && bin/rails db:seed && \
    pg_ctl -D ~/pgdata stop
```

Why this beats seeding at runtime:

- **Self-contained & deterministic.** A built image already holds the prepared data, identical on both sides. Nothing about a run depends on a setup step succeeding (or differing) at start.
- **It survives the bind mount.** twin-servers mounts the app dir as a _named volume_; Docker populates an empty named volume from the image on start, and `start-containers` empties it each run — so data baked under the app dir (e.g. a SQLite file in `storage/`) is restored to the baked state on every start. Data outside the app dir (e.g. `~/pgdata`) simply stays in the image. Either way the baked state is what runs.
- **Failures surface at `build`,** where they're easy to read, not mid-startup.

### The one thing you can't bake in: a running daemon

A `RUN` can't leave a process running into the final image. So for service-backed apps the _only_ legitimate runtime step is starting the daemon — and that's the entire justifiable contents of `setupCommands` (they run in both containers in parallel before the servers start):

```ts
setupCommands: [
  { command: 'pg_ctl -D ~/pgdata -l ~/pgdata/logfile start', description: 'Starting PostgreSQL' },
  { command: 'redis-server --save "" --appendonly no --daemonize yes', description: 'Starting Redis' },
  { command: 'memcached -d', description: 'Starting Memcached' },
],
```

Note there is **no** `db:prepare`/`db:seed` here — that happened at build time. If your `setupCommands` grow past starting daemons, that's a smell: the extra work belongs in the Dockerfile. An app with no separate daemon (e.g. SQLite) needs **no `setupCommands` at all**.

Run workers (Sidekiq etc.) inside the main app container via the Procfile, **not** as separate worker containers — this is a perf rig, not a production deployment, and A/B isolation + simplicity beat scaling.

---

## Example 1 — minimal Rails app

A small app whose only external need is a DB it can run on SQLite or an embedded Postgres. Monorepo-style build context (`docker build -f twin-servers/Dockerfile <context>`):

```dockerfile
# syntax = docker/dockerfile:1
ARG RUBY_VERSION=3.3.7
ARG NON_ROOT_USER=rails
ARG UID=1000
ARG GID=1000
ARG BUNDLE_PATH=/home/${NON_ROOT_USER}/bundle
ARG NODE_PATH=/home/${NON_ROOT_USER}/node
ARG APP_PATH=/home/${NON_ROOT_USER}/app

FROM ruby:${RUBY_VERSION}-bullseye AS base
ARG NON_ROOT_USER
ARG UID
ARG GID
ARG BUNDLE_PATH
ARG NODE_PATH
ARG APP_PATH

ENV NODE_VERSION=24.13.0
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
      curl libjemalloc2 libvips sqlite3 libpq-dev build-essential git \
      libyaml-dev pkg-config psmisc net-tools \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=$NODE_PATH/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" ${NODE_PATH} && \
    corepack enable && rm -rf /tmp/node-build-master

ENV RAILS_ENV="production" \
    NODE_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH=${BUNDLE_PATH} \
    BUNDLE_WITHOUT="development test" \
    SECRET_KEY_BASE="not-a-real-secret-just-for-perf-testing" \
    RAILS_LOG_TO_STDOUT="true" \
    RAILS_SERVE_STATIC_FILES="true" \
    TWIN_SERVERS="true"

RUN getent group $GID | cut -d: -f1 | xargs -r groupdel || true
RUN groupadd --gid $GID ${NON_ROOT_USER} && \
    useradd --uid $UID --gid ${NON_ROOT_USER} --shell /bin/sh --create-home ${NON_ROOT_USER}
RUN mkdir -p $APP_PATH && chown -R ${NON_ROOT_USER}:${NON_ROOT_USER} /home/${NON_ROOT_USER}
WORKDIR $APP_PATH
USER ${NON_ROOT_USER}

# Install gems
COPY --chown=${NON_ROOT_USER}:${NON_ROOT_USER} Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# App code + asset build
COPY --chown=${NON_ROOT_USER}:${NON_ROOT_USER} . .
RUN bundle exec bootsnap precompile --gemfile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Writable dirs
RUN mkdir -p log tmp/pids tmp/cache storage && \
    chown -R ${NON_ROOT_USER}:${NON_ROOT_USER} log tmp storage

# Prepare + seed the DB at build time so the image is self-contained. SQLite
# has no daemon, so the seeded file under storage/ is the whole database — it
# gets baked in here and needs zero setupCommands at runtime.
RUN ./bin/rails db:prepare && ./bin/rails db:seed

EXPOSE 3000
# For twin-servers: CMD/ENTRYPOINT removed — compose uses `sleep infinity`.
```

This app needs **no `setupCommands`** — leave the field out of the config.

---

## Example 2 — real multi-service app

A production Rails app with **embedded Postgres + Redis + Memcached**, an SSR node process, and Sidekiq — i.e. several backing services and several runtime processes. (Elasticsearch, which has a good official image, is left to compose as a per-side pair — see `compose-and-procfile.md`.) This shows how the rules scale up.

```dockerfile
ARG RUBY_VERSION=3.1.2
ARG NON_ROOT_USER=rails
ARG UID=1000
ARG GID=1000
ARG BUNDLE_PATH=/home/${NON_ROOT_USER}/bundle
ARG NODE_PATH=/home/${NON_ROOT_USER}/node
ARG APP_PATH=/home/${NON_ROOT_USER}/app

# ── base: runtime + embedded services ──────────────────────────────────────
FROM ruby:${RUBY_VERSION}-bullseye AS base
ARG NON_ROOT_USER
ARG UID
ARG GID
ARG BUNDLE_PATH
ARG NODE_PATH
ARG APP_PATH

ENV NODE_VERSION=18.20.4
# Config baked in — identical on both sides. Third-party keys are placeholders;
# the app must no-op them under TWIN_SERVERS (see Phase 4).
ENV SECRET_KEY_BASE=dummy-secret-key-base \
    TWIN_SERVERS=true \
    DB_USERNAME=${NON_ROOT_USER} \
    CAMPAIGN_MONITOR_API_KEY=skip \
    RECAPTCHA_SECRET_KEY=placeholder \
    RECAPTCHA_SITE_KEY=placeholder \
    MEMCACHEDCLOUD_SERVERS=localhost:11211

ENV PATH=$NODE_PATH/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" ${NODE_PATH} && \
    npm install -g yarn@1.22.22 && rm -rf /tmp/node-build-master

# Embedded services: PGDG for Postgres 14, redis.io for Redis ≥6.2.
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/redis.gpg] https://packages.redis.io/deb bullseye main" > /etc/apt/sources.list.d/redis.list
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      libpq5 libvips42 libjemalloc2 curl redis-server memcached postgresql-14 \
    && rm -rf /var/lib/apt/lists/*
ENV PATH=/usr/lib/postgresql/14/bin:$PATH

ENV RAILS_ENV=production NODE_ENV=production \
    RAILS_LOG_TO_STDOUT=true RAILS_SERVE_STATIC_FILES=true \
    BUNDLE_WITHOUT="development:test" BUNDLE_DEPLOYMENT=1 BUNDLE_PATH=${BUNDLE_PATH} \
    LD_PRELOAD=libjemalloc.so.2

RUN getent group $GID | cut -d: -f1 | xargs -r groupdel || true
RUN groupadd --gid $GID ${NON_ROOT_USER} && \
    useradd ${NON_ROOT_USER} --uid $UID --gid $GID --create-home --shell /bin/bash
RUN mkdir -p $APP_PATH && chown -R ${NON_ROOT_USER}:${NON_ROOT_USER} /home/${NON_ROOT_USER}
RUN chown ${NON_ROOT_USER}:${NON_ROOT_USER} /var/run/postgresql
WORKDIR $APP_PATH
USER ${NON_ROOT_USER}

# ── build: deps + assets (needs root for -dev headers) ─────────────────────
FROM base AS build
ARG NON_ROOT_USER
ARG BUNDLE_PATH
USER root
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      build-essential libpq-dev libvips-dev git && rm -rf /var/lib/apt/lists/*
USER ${NON_ROOT_USER}

COPY --chown=${NON_ROOT_USER}:${NON_ROOT_USER} Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
COPY --chown=${NON_ROOT_USER}:${NON_ROOT_USER} package.json yarn.lock ./
RUN NODE_ENV=development yarn install --frozen-lockfile
COPY --chown=${NON_ROOT_USER}:${NON_ROOT_USER} . .
RUN bundle exec bootsnap precompile --gemfile app/ lib/
RUN bundle exec rails assets:precompile
RUN yarn cache clean

# ── production: lean final image ───────────────────────────────────────────
FROM base AS production
ARG NON_ROOT_USER
ARG UID
ARG GID
ARG BUNDLE_PATH
ARG APP_PATH
COPY --from=build --chown=${UID}:${GID} ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=build --chown=${UID}:${GID} ${APP_PATH} ${APP_PATH}
RUN mkdir -p log tmp/pids tmp/cache storage && \
    chown -R ${NON_ROOT_USER}:${NON_ROOT_USER} log tmp storage

# Bake a migrated + seeded database into the image. Postgres data lives at
# ~/pgdata (outside the bind-mounted app dir), so it ships in the image. Start
# only what seeding touches, run setup, then stop — the final image keeps no
# running process, just the data. (If seeding hits Redis/Memcached, start those
# here too.)
RUN initdb -D ~/pgdata && \
    pg_ctl -D ~/pgdata -l ~/pgdata/logfile start && \
    bundle exec rails db:prepare && bundle exec rails db:seed && \
    pg_ctl -D ~/pgdata stop

EXPOSE 3000
# For twin-servers: CMD/ENTRYPOINT removed — compose uses `sleep infinity`,
# Overmind starts puma / SSR / sidekiq independently.
```

The data is already in the image, so its `setupCommands` only start the embedded daemons (the one thing a build can't bake in) — no `db:prepare`/`db:seed`:

```ts
setupCommands: [
  { command: 'pg_ctl -D ~/pgdata -l ~/pgdata/logfile start', description: 'Starting PostgreSQL' },
  { command: 'redis-server --save "" --appendonly no --daemonize yes', description: 'Starting Redis' },
  { command: 'memcached -d', description: 'Starting Memcached' },
],
```
