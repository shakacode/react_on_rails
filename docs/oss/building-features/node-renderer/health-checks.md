# Node Renderer Health and Readiness Endpoints

> **Pro Feature** — Available with [React on Rails Pro](../../../pro/react-on-rails-pro.md).
> Free or very low cost for startups and small companies. [Upgrade or licensing details →](../../../pro/upgrading-to-pro.md#try-pro-risk-free)

The node renderer ships built-in, opt-in probe endpoints so container orchestrators (Kubernetes, ECS, Docker Compose,
Control Plane) can check renderer liveness and readiness without custom Fastify code:

- **`GET /health`** — liveness. Returns `200` with `{ "status": "ok" }` whenever the process can answer, i.e. the
  event loop is responsive. It intentionally checks **no** dependencies (no bundle, Rails, or license state), so a
  transient dependency issue never restarts the container.
- **`GET /ready`** — readiness. Returns `200` with `{ "status": "ready" }` only when the renderer can actually serve
  render requests: the worker answering the probe is online **and** at least one server bundle has been compiled into
  its VM pool. Until then it returns `503` with `{ "status": "waiting_for_bundle" }`, because a renderer with zero
  bundles responds `410` to render requests until the Rails client uploads one.

Both endpoints return status-only JSON bodies — no runtime versions, file paths, or license details — so leaving them
reachable exposes nothing sensitive. Like [`/info`](./js-configuration.md#built-in-endpoints), they are plain `GET`
routes outside the authenticated render and asset endpoints and do not require the renderer `password` (orchestrator
probes cannot carry it). Keep the renderer on `localhost` or private networking as usual; see
[Network Security](./basics.md#network-security).

## Status-Code Contract

Probe tooling that uses `curl --fail` / `-f` (which `-sf` and `-fsS` both include) exits non-zero on any HTTP status
`>= 400`. Whether `--fail` is safe therefore depends on which endpoint you probe:

| Endpoint  | Status codes                                                           | Safe with `curl --fail` / `-f`?                                                                 |
| --------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `/health` | Always `200` (process can answer)                                      | **Yes** — never non-2xx.                                                                        |
| `/info`   | Always `200` (returns Node and renderer versions)                      | **Yes** — never non-2xx.                                                                        |
| `/ready`  | `200` once a bundle is compiled; `503` `waiting_for_bundle` until then | **Only with a warm-up path.** Without one, `-f` turns the cold-start `503` into a failed probe. |

> **Why `curl -fsS .../ready` can break container startup:** during the cold-start window `/ready` returns `503`
> (`{"status":"waiting_for_bundle"}`) until the answering worker compiles its first bundle, and `-f`/`--fail` turns
> that `503` into a non-zero exit. If that command gates startup/readiness and nothing pre-warms the renderer, the
> probe never passes and the container never becomes ready. This is the `503` working as designed, not a bug — see
> [Gating traffic on `/ready`](#gating-traffic-on-ready). For a probe that must always pass once the process is up,
> point `--fail` at `/health` (or `/info`); reserve `--fail` against `/ready` for setups with a warm-up path.

## Enabling the Endpoints

The endpoints are **off by default**. Enable them with the `enableHealthEndpoints` config option or the
`RENDERER_ENABLE_HEALTH_ENDPOINTS` environment variable (`true`, `TRUE`, `yes`, `YES`, or `1`):

The `1` alias is scoped to `RENDERER_ENABLE_HEALTH_ENDPOINTS`; other node-renderer boolean environment variables keep
their existing parsing behavior.

```js
// renderer/node-renderer.js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

reactOnRailsProNodeRenderer({
  enableHealthEndpoints: true,
  // ... your other options
});
```

Or, without changing the launch file:

```bash
RENDERER_ENABLE_HEALTH_ENDPOINTS=true node renderer/node-renderer.js
```

Verify locally (note `--http2-prior-knowledge` — see the next section for why):

```bash
curl -s --http2-prior-knowledge http://localhost:3800/health
# => {"status":"ok"}
curl -s --http2-prior-knowledge http://localhost:3800/ready
# => 503 {"status":"waiting_for_bundle"} until the first bundle upload, then 200 {"status":"ready"}
```

## h2c: Why `httpGet` Probes Do NOT Work

The renderer listens with **cleartext HTTP/2 (h2c)**. Kubernetes `httpGet` probes, ALB target-group health checks,
Control Plane HTTP probes, and other HTTP/1.1-only checkers cannot speak h2c and **cannot reach these endpoints**
directly. Do not configure an `httpGet` probe against the renderer port — it will always fail.

Use these probe shapes instead:

- **`exec` probe** with an h2c-aware client packaged in your image, e.g.
  `curl -sf --http2-prior-knowledge http://localhost:3800/ready`. This is the only shape that checks application-level
  readiness. Verify your image's curl has HTTP/2 support: `curl --version | grep -i http2`.
- **`tcpSocket` probe** as a shallow fallback: it proves the port is bound, not that the renderer can serve.

`exec` probes run inside the container, so the default `localhost` host binding works. `tcpSocket` probes connect to
the pod/workload IP, so they require the renderer `host` set to `0.0.0.0`. See
[Configuring Startup, Readiness, and Liveness Probes](./js-configuration.md#configuring-startup-readiness-and-liveness-probes)
for the full probe-style discussion and timing guidance.

## Kubernetes Probes

A working probe set for a renderer container with `enableHealthEndpoints: true` and curl (with HTTP/2 support) in the
image:

```yaml
containers:
  - name: node-renderer
    image: my-registry/my-app:latest
    command: ['node', 'renderer/node-renderer.js']
    ports:
      - containerPort: 3800
    env:
      - name: RENDERER_HOST
        value: '0.0.0.0' # required by the tcpSocket probes below
      - name: RENDERER_PORT
        value: '3800'
      - name: RENDERER_ENABLE_HEALTH_ENDPOINTS
        value: 'true'
    # Startup: shield liveness while the renderer boots. TCP is enough here
    # because readiness below gates traffic.
    startupProbe:
      tcpSocket:
        port: 3800
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 12 # tune to your cold-start time; 10 + (5 * 12) = 70 s total
      timeoutSeconds: 1
    # Readiness: shallow TCP check. Do NOT gate readiness on /ready unless you
    # also pre-warm the renderer — see "Gating traffic on /ready" below.
    # (httpGet cannot be used in any case: the renderer listener is h2c-only.)
    readinessProbe:
      tcpSocket:
        port: 3800
      periodSeconds: 5
      failureThreshold: 3
      timeoutSeconds: 1
    # Liveness: shallow by default so CPU/GC pauses don't restart the pod.
    livenessProbe:
      tcpSocket:
        port: 3800
      periodSeconds: 10
      failureThreshold: 3
      timeoutSeconds: 1
```

### Gating traffic on `/ready`

`/ready` reports `503` until the answering worker has compiled at least one bundle, and each worker compiles its
first bundle when it serves its first render request. If the readiness probe is the only thing standing between a
fresh pod and its first render — a standalone renderer behind a Service, or a sidecar (pod readiness requires
**all** containers to be ready, so an unready renderer container blocks traffic to the Rails container too) — then
gating readiness on `/ready` deadlocks the rollout: no traffic → no first render → never ready.

Only use `/ready` as the readiness gate when something other than probe-gated traffic delivers the first render,
for example a deployment pipeline step or Rails initializer that POSTs a warm-up render to each new replica
directly (bypassing the Service), or a container `postStart` hook that does the same. That warm-up must reach
every renderer worker that can answer probes; with `workersCount > 1`, one render per replica is not enough
unless you intentionally run a single worker or fan out warm-up renders to each worker. With a warm-up path in
place:

```yaml
readinessProbe:
  exec:
    command:
      - curl
      - -sf
      - --max-time
      - '3'
      - --http2-prior-knowledge
      - http://localhost:3800/ready
  periodSeconds: 5
  failureThreshold: 3
  timeoutSeconds: 5
```

Without a warm-up path, keep the shallow `tcpSocket` readiness probe and use `/ready` for monitoring, dashboards,
and post-deploy verification instead.

For stricter hung-process detection, replace the `tcpSocket` liveness probe with an `exec` probe against `/health`
(same curl command as the `/ready` example above, with the path changed). A fully blocked event loop still accepts TCP connections, so
only the `exec` form catches it. Use the stricter form deliberately — it restarts the container on slow event loops,
not just dead ones.

> **Cold-start note:** Each worker compiles its first bundle when it serves its first render request, so `/ready`
> stays `503` until then — pre-seeding the bundle cache on disk does not by itself flip `/ready`. This is harmless
> wherever the check does not gate the traffic that would deliver that first render or replace the container
> (monitoring, dashboards, post-deploy checks). Wherever it does gate that traffic or container lifetime — a
> Kubernetes Service routing only to ready replicas, a sidecar whose unready state blocks pod readiness, an ECS
> container health check, an ALB target group — see "Gating traffic on `/ready`" above before using it as the gate.
> A `503` from `/ready` during the cold-start window is correct behavior, not a failure.

## ECS Health Check

ECS container health checks run **inside** the container (like a Kubernetes `exec` probe), so they work against the
h2c listener with curl and the default `localhost` binding. Use `/health` by default so a normal cold start cannot
fail the task before the first render compiles a bundle:

```json
{
  "containerDefinitions": [
    {
      "name": "node-renderer",
      "command": ["node", "renderer/node-renderer.js"],
      "portMappings": [{ "containerPort": 3800 }],
      "environment": [{ "name": "RENDERER_ENABLE_HEALTH_ENDPOINTS", "value": "true" }],
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/health || exit 1"
        ],
        "interval": 10,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 30
      }
    }
  ]
}
```

Tune `startPeriod` to match the observed image pull, boot, and first-render latency for your app. Larger bundles or
slower registries may need 60 seconds or more.

If you intentionally warm the renderer before `startPeriod` expires and want ECS to replace a task that cannot serve
compiled bundles, change the path to `/ready`.

> **ALB note:** ALB target-group health checks are HTTP/1.1 and cannot probe the renderer's h2c port. If the renderer
> sits behind a load balancer, prefer the ECS container health check above for renderer health, or use an NLB with the
> TCP health-check protocol for a shallow port check.

## Docker Compose

```yaml
services:
  renderer:
    build: .
    command: node renderer/node-renderer.js
    environment:
      RENDERER_ENABLE_HEALTH_ENDPOINTS: 'true'
    healthcheck:
      test:
        ['CMD', 'curl', '-sf', '--max-time', '3', '--http2-prior-knowledge', 'http://localhost:3800/health']
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s
```

## Control Plane (CPLN)

Control Plane exposes two relevant probe shapes: an **HTTP** probe and a **Command** (exec) probe. The HTTP probe is
HTTP/1.1 and **cannot speak the renderer's h2c listener** (see [h2c](#h2c-why-httpget-probes-do-not-work)), so it
always fails against these endpoints — use a **Command** probe with an h2c-aware curl instead. Command probes run
inside the container, so the default `localhost` binding works and no `0.0.0.0` host is required.

Use `/health` (always `200`) for liveness and readiness by default so a normal cold start cannot fail the workload
before the first render compiles a bundle:

```yaml
# Control Plane workload — readiness / liveness as a Command probe
readiness:
  exec:
    command:
      - curl
      - -sf
      - --max-time
      - '3'
      - --http2-prior-knowledge
      - http://localhost:3800/health
```

Do **not** point a `--fail` Command probe at `/ready` unless something pre-warms the renderer, or the probe will fail
on the cold-start `503` and the workload never becomes ready (the exact failure in
[Status-Code Contract](#status-code-contract)). Only switch the path to `/ready` once a warm-up path delivers the
first render to every worker that answers probes — see [Gating traffic on `/ready`](#gating-traffic-on-ready).

## Semantics and Caveats

- **Per-worker checks.** With `workersCount > 1`, the Node.js cluster module distributes incoming connections across
  worker processes, and each worker has its own VM pool. A probe therefore checks the one worker that answers it.
  Workers load bundles independently (each compiles the bundle on its first render request), so a freshly restarted
  worker can briefly report `503` on `/ready` while its siblings serve traffic. This is the intended per-process
  readiness signal for orchestrators probing one container. During a rollout or cold start, raw probe logs may show a
  short mix of `503` and `200` responses; Kubernetes smooths that with `failureThreshold` / `successThreshold`, so a
  single unloaded-worker `503` should not flap pod readiness.
- **No license check.** License validation happens on the Rails side; `/ready` does not (and cannot) report license
  state.
- **Liveness checks nothing but the event loop.** Do not point `/health` at dependency monitoring; that is what
  readiness and your APM are for.
- **Custom routes still work.** If you need richer checks (warm-up gates, dependency checks, custom payloads), the
  [`configureFastify` health-check recipe](./js-configuration.md#adding-a-health-check-endpoint) still applies and can
  coexist with the built-in endpoints as long as your custom routes use different paths. Remove or rename any existing
  custom `/health` or `/ready` route before enabling `enableHealthEndpoints`; Fastify raises a duplicate-route startup
  error when built-in and custom routes share the same path. If an async Fastify plugin registers the duplicate route
  during `app.register()` boot, you will see Fastify's raw `FST_ERR_DUPLICATED_ROUTE` error instead of the
  `enableHealthEndpoints` migration hint.

## Rails-Side Readiness

To gate a Rails readiness endpoint on the renderer, keep using the TCP-check recipe in
[Container Deployment](./container-deployment.md#same-rails-container-rails-and-renderer-co-located), or upgrade it to
an HTTP/2 client call against `/ready` if your Ruby HTTP client supports h2c.
