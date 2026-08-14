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

## Choosing h2c or HTTP/1.1

The renderer uses **cleartext HTTP/2 (h2c)** by default, and the Rails client forces h2c for an `http://` renderer URL.
This remains the recommended transport when async props must cross an intermediary. Kubernetes `httpGet` probes, ALB
target-group health checks, Control Plane HTTP probes, and other HTTP/1.1-only checkers cannot reach a default h2c
listener directly.

You can instead run the entire Rails-to-renderer connection over HTTP/1.1. Configure both sides so the listener and
client agree:

```js
// renderer/node-renderer.js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

reactOnRailsProNodeRenderer({
  host: '0.0.0.0',
  enableHealthEndpoints: true,
  fastifyServerOptions: { http2: false },
  password: process.env.RENDERER_PASSWORD,
});
```

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.renderer_password = ENV.fetch("RENDERER_PASSWORD")
  config.renderer_http_force_http2 = false
end
```

Keep the renderer on private networking. For an ALB, use an internal load balancer with private targets and restrict
the renderer security group to the ALB and Rails callers. The renderer executes application bundles, so review
[Node Renderer network security](./basics.md#network-security) before exposing it beyond a trusted network. Health
routes intentionally remain unauthenticated, and `/info` also remains unauthenticated and discloses the Node and
renderer versions. Keep all three routes private; render requests still require `RENDERER_PASSWORD`.

With this paired configuration, ordinary HTTP/1.1 probes and ALB target-group health checks can reach `/health` and
`/ready` on the renderer port. Regular renderer requests and response streaming continue to work. A direct HTTP/1.1
connection can also stream the request and response concurrently, but an intermediary may buffer the request body or
operate half-duplex. That can delay the render response until Rails finishes sending async props, and pull-mode async
props can stall. Async props through an ALB or another unverified HTTP/1.1 intermediary are therefore outside the
supported transport contract. Keep a direct h2c path when async props must traverse such a hop.

On Falcon or another long-lived `Fiber.scheduler`, one HTTP/1.1 connection handles one request at a time. In that
environment, `renderer_http_pool_size` is a hard concurrency cap for renderer requests sharing the client, with a
default of `10`. Requests beyond that cap wait for a connection without a pool-acquisition timeout; `ssr_timeout` starts
applying only after a socket is acquired. Size the pool at or above peak concurrent renderer requests per scheduler,
then confirm that the renderer `workersCount` can sustain that load. Standard Puma uses an ephemeral client for
streaming renders and a persistent per-thread client for non-streaming renders, so neither path creates a process-wide
shared-client cap.

`renderer_http_force_http2` affects only cleartext `http://` URLs. For `https://`, async-http negotiates the protocol
with ALPN, so the TLS listener or proxy controls whether the connection uses HTTP/1.1 or HTTP/2.

Change the listener and Rails client atomically. For independently rolled workloads, bring up a parallel HTTP/1.1
renderer endpoint, verify it, switch Rails to that endpoint with `renderer_http_force_http2 = false`, and then drain
the h2c endpoint. Rolling one side in place first creates a temporary protocol mismatch.

When keeping the default h2c transport, use these probe shapes instead:

- **`exec` probe** with an h2c-aware client packaged in your image, e.g.
  `curl -sf --http2-prior-knowledge http://localhost:3800/ready`. This is the only shape that checks application-level
  readiness. Verify your image's curl has HTTP/2 support: `curl --version | grep -i http2`.
- **`tcpSocket` probe** as a shallow fallback: it proves the port is bound, not that the renderer can serve.

`exec` probes run inside the container, so the default `localhost` host binding works. `tcpSocket` probes connect to
the pod/workload IP, so they require the renderer `host` set to `0.0.0.0`. See
[Configuring Startup, Readiness, and Liveness Probes](./js-configuration.md#configuring-startup-readiness-and-liveness-probes)
for the full probe-style discussion and timing guidance.

## Kubernetes Probes

A working probe set for a renderer container using the default h2c transport with `enableHealthEndpoints: true` and
curl (with HTTP/2 support) in the image:

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
    # Readiness: use /ready after configuring the revision-scoped current
    # generation manifest; shallow TCP remains the compatibility fallback.
    # (httpGet cannot be used with the default h2c listener. It is available
    # when both Rails and the renderer are configured for HTTP/1.1.)
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

When `RENDERER_CURRENT_GENERATION_MANIFEST` points to the immutable declaration emitted by pre-seeding, every
worker validates and compiles its complete server plus optional RSC set before listening. `/ready` then means the
answering worker completed that declaration. No unauthenticated warmup endpoint or probe-generated render is
needed:

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

Without a configured declaration, compatibility behavior remains: `/ready` reports `503` until the answering
worker compiles any bundle from a render request. In that mode, keep the shallow `tcpSocket` readiness probe or
provide your own authenticated application smoke path; otherwise probe-gated traffic can deadlock startup.

For stricter hung-process detection, replace the `tcpSocket` liveness probe with an `exec` probe against `/health`
(same curl command as the `/ready` example above, with the path changed). A fully blocked event loop still accepts TCP connections, so
only the `exec` form catches it. Use the stricter form deliberately — it restarts the container on slow event loops,
not just dead ones.

> **Compatibility-mode cold-start note:** Without `RENDERER_CURRENT_GENERATION_MANIFEST`, each worker compiles its
> first bundle when it serves its first render request, so `/ready` stays `503` until then. This is harmless
> wherever the check does not gate the traffic that would deliver that first render or replace the container
> (monitoring, dashboards, post-deploy checks). Wherever it does gate that traffic or container lifetime — a
> Kubernetes Service routing only to ready replicas, a sidecar whose unready state blocks pod readiness, an ECS
> container health check, an ALB target group — see "Gating traffic on `/ready`" above before using it as the gate.
> A `503` from `/ready` during the cold-start window is correct behavior, not a failure.

## ECS Health Check

ECS container health checks run **inside** the container (like a Kubernetes `exec` probe), so they work against the
h2c listener with curl and the default `localhost` binding. Use `/ready` when the revision-scoped current declaration
is configured; use `/health` in compatibility mode so request-driven compilation cannot fail the task:

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

Tune `startPeriod` to match the observed image pull, boot, and prewarm latency for your app. Larger bundles or
slower registries may need 60 seconds or more.

With a configured declaration, change the path to `/ready` when ECS should replace a task that cannot compile its
declared current bundle set.

### ALB target group

ALB target-group health checks use HTTP/1.1. Use an internal ALB and private targets, restrict the renderer target
security group to the ALB and Rails callers, and keep renderer password authentication enabled for render requests.
The `/health`, `/ready`, and `/info` routes remain unauthenticated. `/info` discloses the Node and renderer versions, so
keep the renderer on a private network and never attach it to an internet-facing listener.

Unlike the ECS container check above, which probes over loopback, an ALB connects to the task IP. Set the renderer
`host` to `0.0.0.0` so the ALB can reach it.

Configure the target group with:

- Protocol: `HTTP`
- Protocol version: `HTTP1`
- Traffic port: the renderer port, normally `3800`
- Health check path: `/health`
- Success matcher: `200`

Use `/ready` instead only when `RENDERER_CURRENT_GENERATION_MANIFEST` prewarms every worker; otherwise its expected
cold-start `503` can block the traffic needed to upload the first bundle. Pair this target group with the Node and Rails
HTTP/1.1 settings above. If async props must cross the load-balancer hop, keep renderer traffic on a direct h2c path and
use the ECS container health check above or an NLB TCP health check instead.

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

Control Plane exposes two relevant probe shapes: an **HTTP** probe and a **Command** (exec) probe. With the default h2c
transport, use a **Command** probe with an h2c-aware curl because the HTTP probe speaks HTTP/1.1. With the paired
[HTTP/1.1 configuration](#choosing-h2c-or-http11), the ordinary HTTP probe can reach the renderer endpoints directly.
Command probes run inside the container, so the default `localhost` binding works and no `0.0.0.0` host is required.

Use `/ready` for readiness when the revision-scoped declaration is configured; use `/health` for liveness. In
compatibility mode, keep `/health` for readiness so request-driven compilation cannot deadlock the workload. Control
Plane uses the Kubernetes-style `readinessProbe` / `livenessProbe`
fields on the workload container (the same shape as the [Kubernetes example above](#kubernetes-probes) and the
existing [Control Plane deployment docs](../../deployment/docker-deployment.md#deploying-with-control-plane)), with a Command
probe expressed as `exec.command`:

```yaml
kind: workload
spec:
  containers:
    - name: node-renderer
      # ... image, ports, env (RENDERER_ENABLE_HEALTH_ENDPOINTS: 'true') ...
      # Command probe — h2c-aware curl against /health (always 200).
      readinessProbe:
        exec:
          command:
            - curl
            - -sf
            - --max-time
            - '3'
            - --http2-prior-knowledge
            - http://localhost:3800/health
        periodSeconds: 5
        failureThreshold: 3
        timeoutSeconds: 5 # exceed curl --max-time 3 so the probe, not the orchestrator, owns the timeout
      livenessProbe:
        exec:
          command:
            - curl
            - -sf
            - --max-time
            - '3'
            - --http2-prior-knowledge
            - http://localhost:3800/health
        periodSeconds: 10
        failureThreshold: 3
        timeoutSeconds: 5 # exceed curl --max-time 3 so the probe, not the orchestrator, owns the timeout
```

Do **not** point a `--fail` Command probe at `/ready` in compatibility mode without another authenticated warmup
path. Prefer configuring the revision-scoped declaration so startup itself compiles every worker before listen.

## Semantics and Caveats

- **Per-worker checks.** With `workersCount > 1`, the Node.js cluster module distributes incoming connections across
  worker processes, and each worker has its own VM pool. With a current-generation declaration, each worker compiles
  the complete declared set before listening, so any worker that answers `/ready` has crossed its own barrier. In
  compatibility mode, a probe still checks only the answering worker and readiness means only that worker has some VM.
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
[Container Deployment](./container-deployment.md#same-rails-container-rails-and-renderer-co-located), use an HTTP/2
client call against `/ready` for the default h2c transport, or use an ordinary HTTP client when both sides are
configured for HTTP/1.1.
