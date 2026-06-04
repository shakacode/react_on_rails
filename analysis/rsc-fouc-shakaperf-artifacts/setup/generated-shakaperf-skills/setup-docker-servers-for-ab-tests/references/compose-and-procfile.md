# Procfile & docker-compose reference

## The Procfile

`twin-servers/Procfile` lists the processes Overmind runs. Each app process gets **one line per side**, plus a readiness notifier per side. Lines run as host processes that exec into the right container.

Two helper subcommands do the work:

- `shaka-perf servers run-overmind-command <side> "<cmd>"` — runs `<cmd>` inside that side's container with PID tracking, so Overmind can stop/restart just that process without bouncing the container. The command binds **inside** the container (`tcp://0.0.0.0:3000`); the host port comes from `ports`.
- `shaka-perf servers notify-server-started <side>` — waits for the side's configured port (via `dockerize -wait`), announces it (TTS + stdout), then idles to keep Overmind happy. The TTS calls take a per-user lock so the two announcements don't talk over each other.

### Minimal (single web process)

```
control-rails: yarn shaka-perf servers run-overmind-command control "bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:3000"
experiment-rails: yarn shaka-perf servers run-overmind-command experiment "bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:3000"
notify-control-server-started: yarn shaka-perf servers notify-server-started control
notify-experiment-server-started: yarn shaka-perf servers notify-server-started experiment
```

### Multiple processes (web + SSR renderer + worker)

Add a line per extra process **per side**. Workers and SSR run inside the same app container as the web process — not separate containers (this is a perf rig; A/B isolation and simplicity beat production-style scaling). Never let a process serve both sides.

```
control-rails: yarn shaka-perf servers run-overmind-command control "bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:3000"
control-ssr: yarn shaka-perf servers run-overmind-command control "yarn tsx app/javascript/ssr-server.ts"
control-sidekiq: yarn shaka-perf servers run-overmind-command control "bundle exec sidekiq -C config/sidekiq.yml"
experiment-rails: yarn shaka-perf servers run-overmind-command experiment "bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:3000"
experiment-ssr: yarn shaka-perf servers run-overmind-command experiment "yarn tsx app/javascript/ssr-server.ts"
experiment-sidekiq: yarn shaka-perf servers run-overmind-command experiment "bundle exec sidekiq -C config/sidekiq.yml"
notify-control-server-started: yarn shaka-perf servers notify-server-started control
notify-experiment-server-started: yarn shaka-perf servers notify-server-started experiment
```

Commented-out lines are fine as scaffolding for optional processes (e.g. a renderer you may not need):

```
# control-renderer: yarn shaka-perf servers run-overmind-command control "node node-renderer.js"
```

---

## docker-compose — usually leave it to the default

The package bundles a default `docker-compose.yml`. **The common, recommended path embeds all services in the image (see `writing-the-dockerfile.md`), in which case you need no custom compose at all — omit `composeFile` from the config and don't create the file.**

The default gives you, per side: the app image, the host-port mapping (`${CONTROL_PORT}:3000` / `${EXPERIMENT_PORT}:3000`), the bind-mount volume, `command: sleep infinity`, and the `PERF_EXPERIMENT` flag that lets the app tell which side it's on. `CONTROL_IMAGE_NAME`, `EXPERIMENT_IMAGE_NAME`, `CONTROL_VOLUME_DIR`, `EXPERIMENT_VOLUME_DIR`, and the ports are injected by twin-servers automatically.

### When you do need a custom compose

Only when a backing service genuinely shouldn't be embedded — typically because it has a maintained official image you'd rather reuse (Elasticsearch is the classic case). Get an editable copy:

```bash
yarn shaka-perf servers customize-docker-compose
```

Then set `composeFile: 'twin-servers/docker-compose.yml'` in the config.

**The hard rule: every backing service gets its own `-control` and `-experiment` instance. The two sides must never share a service.** Shared state — one Elasticsearch index, one cache — is the number-one source of phantom A/B regressions: experiment writes, control reads its data, and the diff is meaningless. Wire each app side to its own service via a per-side env var.

```yaml
services:
  elasticsearch-control:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.10
    environment:
      - discovery.type=single-node
      - 'ES_JAVA_OPTS=-Xms512m -Xmx512m'
    healthcheck:
      test: ['CMD-SHELL', 'curl -fsSL http://localhost:9200/_cluster/health || exit 1']
      interval: 1s
      timeout: 5s
      retries: 10
      start_period: 30s

  elasticsearch-experiment:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.10
    environment:
      - discovery.type=single-node
      - 'ES_JAVA_OPTS=-Xms512m -Xmx512m'
    healthcheck:
      test: ['CMD-SHELL', 'curl -fsSL http://localhost:9200/_cluster/health || exit 1']
      interval: 1s
      timeout: 5s
      retries: 10
      start_period: 30s

  control-server:
    image: ${CONTROL_IMAGE_NAME}
    ports: ['${CONTROL_PORT}:3000']
    depends_on:
      elasticsearch-control: { condition: service_healthy }
    environment:
      ELASTICSEARCH_URL: http://elasticsearch-control:9200 # per-side wiring
      PERF_EXPERIMENT: 'false'
    volumes: ['control_volume:/home/${USER}/app']
    command: sleep infinity

  experiment-server:
    image: ${EXPERIMENT_IMAGE_NAME}
    ports: ['${EXPERIMENT_PORT}:3000']
    depends_on:
      elasticsearch-experiment: { condition: service_healthy }
    environment:
      ELASTICSEARCH_URL: http://elasticsearch-experiment:9200
      PERF_EXPERIMENT: 'true'
    volumes: ['experiment_volume:/home/${USER}/app']
    command: sleep infinity

volumes:
  control_volume:
    driver: local
    driver_opts: { type: none, o: bind, device: '${CONTROL_VOLUME_DIR}' }
  experiment_volume:
    driver: local
    driver_opts: { type: none, o: bind, device: '${EXPERIMENT_VOLUME_DIR}' }
```

Keep it minimal. Anything that can move into the Dockerfile (build steps, env vars, setup) belongs there, not here — compose owns only twin-server concerns (ports, per-side volumes, the side flag, and any unavoidable per-side external service).
