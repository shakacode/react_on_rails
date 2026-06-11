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

## Enabling the Endpoints

The endpoints are **off by default**. Enable them with the `enableHealthEndpoints` config option or the
`RENDERER_ENABLE_HEALTH_ENDPOINTS` environment variable:

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
      failureThreshold: 6
      timeoutSeconds: 1
    # Readiness: gate traffic on the built-in /ready endpoint (worker online
    # AND at least one bundle compiled). httpGet cannot be used: the renderer
    # listener is h2c-only.
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
    # Liveness: shallow by default so CPU/GC pauses don't restart the pod.
    livenessProbe:
      tcpSocket:
        port: 3800
      periodSeconds: 10
      failureThreshold: 3
      timeoutSeconds: 1
```

For stricter hung-process detection, replace the `tcpSocket` liveness probe with an `exec` probe against `/health`
(same curl command as readiness, with the path changed). A fully blocked event loop still accepts TCP connections, so
only the `exec` form catches it. Use the stricter form deliberately — it restarts the container on slow event loops,
not just dead ones.

> **Cold-start note:** Each worker compiles its first bundle when it serves its first render request, so `/ready`
> stays `503` until then — pre-seeding the bundle cache on disk does not by itself flip `/ready`. In the recommended
> co-located and sidecar topologies this is harmless: Rails reaches the renderer over `localhost`, so the first render
> arrives regardless of probe state and `/ready` flips immediately afterward. In a separate-workload topology where a
> Service or load balancer routes traffic only to ready replicas, a fresh replica cannot receive the first render that
> would make it ready — there, keep the shallow `tcpSocket` readiness probe (or use `/ready` as a monitoring signal
> rather than a traffic gate). A `503` from `/ready` during the cold-start window is correct behavior, not a failure.

## ECS Health Check

ECS container health checks run **inside** the container (like a Kubernetes `exec` probe), so they work against the
h2c listener with curl and the default `localhost` binding:

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
          "curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/ready || exit 1"
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
      RENDERER_HOST: '0.0.0.0'
      RENDERER_ENABLE_HEALTH_ENDPOINTS: 'true'
    healthcheck:
      test:
        ['CMD', 'curl', '-sf', '--max-time', '2', '--http2-prior-knowledge', 'http://localhost:3800/ready']
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s
```

## Semantics and Caveats

- **Per-worker checks.** With `workersCount > 1`, the Node.js cluster module distributes incoming connections across
  worker processes, and each worker has its own VM pool. A probe therefore checks the one worker that answers it.
  Workers load bundles independently (each compiles the bundle on its first render request), so a freshly restarted
  worker can briefly report `503` on `/ready` while its siblings serve traffic. This is the intended per-process
  readiness signal for orchestrators probing one container.
- **No license check.** License validation happens on the Rails side; `/ready` does not (and cannot) report license
  state.
- **Liveness checks nothing but the event loop.** Do not point `/health` at dependency monitoring; that is what
  readiness and your APM are for.
- **Custom routes still work.** If you need richer checks (warm-up gates, dependency checks, custom payloads), the
  [`configureFastify` health-check recipe](./js-configuration.md#adding-a-health-check-endpoint) still applies and can
  coexist with the built-in endpoints as long as your custom routes use different paths.

## Rails-Side Readiness

To gate a Rails readiness endpoint on the renderer, keep using the TCP-check recipe in
[Container Deployment](./container-deployment.md#same-rails-container-rails-and-renderer-co-located), or upgrade it to
an HTTP/2 client call against `/ready` if your Ruby HTTP client supports h2c.
