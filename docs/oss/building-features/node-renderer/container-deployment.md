# Node Renderer: Container Deployment

> **Pro Feature** — Available with [React on Rails Pro](https://pro.reactonrails.com).
> Free or very low cost for startups and small companies. [Get a license →](mailto:justin@shakacode.com)

This guide covers deploying the Node Renderer in containerized environments (Docker, Kubernetes, ControlPlane, etc.), including architecture options, performance tuning, memory management, error tracking, and troubleshooting.

## Prerequisites

- **React on Rails Pro** v16.4.0 or later
- **Node.js** 22+ (LTS recommended)
- **Ruby** 3.1+ with Bundler
- The `react-on-rails-pro-node-renderer` npm package installed in your project

## Architecture Options

When running Rails and the Node Renderer in containers, you have three options, listed from simplest to most complex:

|                            | Single Container       | Sidecar Containers          | Separate Workloads                              |
| -------------------------- | ---------------------- | --------------------------- | ----------------------------------------------- |
| **Complexity**             | Lowest                 | Medium                      | Highest                                         |
| **Scaling**                | Together               | Together                    | Independent                                     |
| **Version alignment**      | Guaranteed             | Guaranteed                  | Risk of drift                                   |
| **Networking**             | `localhost`            | `localhost`                 | Service DNS                                     |
| **Per-process visibility** | No                     | Yes                         | Yes                                             |
| **When to use**            | Default starting point | Need to diagnose OOM source | Need independent scaling at high replica counts |

### Option 1: Single Container (Default)

Rails and the Node Renderer run together in a **single container**. This is the simplest setup and the recommended starting point.

```text
┌──────────────────────────┐
│        Container         │
│  ┌────────┐ ┌──────────┐ │
│  │ Rails  │ │  Node    │ │
│  │ process│ │ Renderer │ │
│  └────────┘ └──────────┘ │
│   shared OS resources    │
└──────────────────────────┘
```

Both processes share the container's CPU and memory limits (cgroup resources); they do not communicate via shared-memory IPC.

**Advantages:**

- **Simplest setup** — One container, one image, one deploy.
- **No networking config** — Rails connects to the renderer via `localhost` out of the box.
- **Guaranteed version alignment** — Both processes always run from the same image.
- **Lower overhead** — Shared OS layer saves ~200–300 MB vs. separate containers.

**When to move on:** If you're experiencing OOM restarts and need to determine whether Rails or the Node Renderer is the culprit, move to sidecar containers for visibility.

**Configuration:**

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = "http://localhost:3800"
end
```

### Option 2: Sidecar Containers

Rails and the Node Renderer run as separate containers within the **same pod/workload**, sharing the same lifecycle. Use this when you need to isolate and diagnose memory/CPU usage per process.

```text
┌─────────────────────────────────┐
│           Pod / Workload        │
│  ┌─────────────┐ ┌───────────┐  │
│  │    Rails    │ │   Node    │  │
│  │  Container  │ │ Renderer  │  │
│  │  (2 CPU,    │ │ (2 CPU,   │  │
│  │   4 GB RAM) │ │  4 GB RAM)│  │
│  └──────┬──────┘ └─────┬─────┘  │
│         │   localhost  │        │
│         └───────┬──────┘        │
└─────────────────┴───────────────┘
```

**Advantages:**

- **Per-process visibility** — See exactly which process is consuming memory and causing OOM kills.
- **Independent resource limits** — Set separate CPU/memory limits for Rails and the Node Renderer.
- **Guaranteed version alignment** — Both containers use the same image on deploy.
- **Simpler networking** — Rails still connects via `localhost`.

**Tradeoffs:**

- Slightly more complex deployment config than a single container.
- Autoscaling logic may need adjustment (see [Autoscaling Considerations](#autoscaling-considerations)).

**Configuration:**

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = "http://localhost:3800"
end
```

### Option 3: Separate Workloads

Rails and the Node Renderer run as independent workloads with their own scaling. This is the most complex option and is rarely needed.

**Advantages:**

- **Independent scaling** — Scale the renderer independently of Rails.
- **Isolated resource limits** — OOM in the renderer doesn't affect Rails and vice versa.

**Disadvantages:**

- **Version drift risk** — During rolling deploys, Rails and the Node Renderer may briefly run different versions. While protocol changes are rare, this is a risk to monitor.
- **Race conditions** — Pods restart independently, which can cause transient connection errors.
- **Network dependency** — Renderer must be reachable via internal service DNS.
- **Overkill for most setups** — If you're running 2–4 replicas, independent scaling adds complexity without real benefit.

**Configuration:**

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = ENV.fetch("RENDERER_URL", "http://node-renderer-service:3800")
end
```

> **Recommendation:** Start with a single container. Move to sidecar containers if you need per-process memory/CPU visibility (e.g., to diagnose OOM restarts). Separate workloads are rarely justified unless you have a specific need for independent scaling at high replica counts.

## Dockerfile Example

A minimal Dockerfile that bundles Rails and the Node Renderer in a single image:

```dockerfile
FROM node:22-slim AS node
FROM ruby:3.3

# Copy Node.js from the official image (avoids curl-pipe-bash)
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# jemalloc for Rails memory (adjust path for arm64: aarch64-linux-gnu)
RUN apt-get update && apt-get install -y libjemalloc2 && rm -rf /var/lib/apt/lists/*
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
ENV MALLOC_CONF="dirty_decay_ms:1000,muzzy_decay_ms:1000"

WORKDIR /app

# Install Ruby and Node dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile

# Expose Rails and Node Renderer ports
EXPOSE 3000 3800

# Start both processes with a process manager (overmind, foreman, etc.)
# See the Procfile example below
CMD ["overmind", "start", "-f", "Procfile"]
```

For the single-container pattern, use a process manager like [overmind](https://github.com/DarthSim/overmind) or [foreman](https://github.com/ddollar/foreman) with a `Procfile`:

```text
# Procfile
rails: bundle exec rails server -b 0.0.0.0 -p 3000
renderer: node client/node-renderer.js
```

> **Tip:** For sidecar containers, use the same image but override the `CMD` — one container runs `bundle exec rails server`, the other runs `node client/node-renderer.js` (or your Node Renderer entry point).

## Docker Compose Example

For local development with sidecar-like containers:

```yaml
services:
  rails:
    build: .
    command: bundle exec rails server -b 0.0.0.0 -p 3000
    ports:
      - '3000:3000'
    environment:
      RENDERER_URL: 'http://renderer:3800'
    depends_on:
      renderer:
        condition: service_healthy

  renderer:
    build: .
    command: node client/node-renderer.js
    ports:
      - '3800:3800'
    environment:
      RENDERER_HOST: '0.0.0.0'
      NODE_OPTIONS: '--max-old-space-size=512'
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:3800/info']
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s
```

> **Note:** In Docker Compose, the containers do not share a network namespace (unlike Kubernetes sidecars), so the renderer must bind to `0.0.0.0` and Rails must connect via the service name (`renderer`).

## Host Binding for Container Environments

By default, the Node Renderer binds to `localhost`. For **sidecar containers** in the same Kubernetes pod, that works because the containers share a network namespace. For **separate workloads** or Docker Compose setups without shared networking, bind to `0.0.0.0`:

```javascript
// node-renderer.js
import { reactOnRailsProNodeRenderer } from 'react-on-rails-pro-node-renderer';

const config = {
  host: '0.0.0.0',
  // ... other config
};

reactOnRailsProNodeRenderer(config);
```

Or via environment variable:

```bash
RENDERER_HOST=0.0.0.0
```

> **Security note:** Binding to `0.0.0.0` exposes the renderer on all network interfaces. Use it only when the renderer needs to be reachable across a network namespace. If the renderer is exposed to untrusted networks, enable the `password` authentication option. See [JS Configuration](./js-configuration.md) for details.

## Optimizing Performance per Cost

### Memory: Understanding the Growth Pattern

The Node Renderer's memory grows over time as it handles SSR requests. This is **expected behavior** — V8's garbage collector doesn't always return memory to the OS, even after objects are freed. In containerized environments with cgroup memory limits, this can trigger OOM kills.

Typical memory profile:

- **Startup:** ~500–600 MB for the renderer process with workers
- **After hours of traffic:** 2–3 GB+ depending on component complexity and traffic volume
- **Rails container:** Usually stabilizes at 2–4 GB depending on `WEB_CONCURRENCY` and `RAILS_MAX_THREADS`

### Constraining Node Memory

Use `NODE_OPTIONS` to cap V8's old-generation heap per worker:

```bash
NODE_OPTIONS="--max-old-space-size=512"
```

This tells V8 to trigger garbage collection more aggressively and limits each worker's heap. Adjust the value based on your component complexity:

| Component Complexity                  | Recommended `max-old-space-size` |
| ------------------------------------- | -------------------------------- |
| Simple components                     | 256–512 MB                       |
| Medium (Redux, large props)           | 512–768 MB                       |
| Complex (large data, many components) | 768–1024 MB                      |

> **Note:** This setting applies per worker. Total renderer memory ≈ `max-old-space-size × workersCount + overhead`. If V8 hits the limit, the worker process exits and is automatically restarted by the cluster manager.

### Worker Count Tuning

The default `workersCount` is CPU count minus 1, which may over-allocate in containers. Set it explicitly:

```javascript
const config = {
  workersCount: parseInt(process.env.RENDERER_WORKERS_COUNT, 10), // Required — derive from the sizing formula below
};
```

**Sizing guideline:** Match worker count to expected concurrent SSR requests.

A rough formula (assuming each SSR render takes roughly half a full Rails request cycle, so one renderer worker can serve ~2 concurrent threads — adjust the divisor based on your measured render times):

```text
renderer_workers ≥ (WEB_CONCURRENCY × RAILS_MAX_THREADS × ssr_request_ratio) / 2
```

Where `ssr_request_ratio` is the fraction of requests that need server rendering (often 30–60% for hybrid apps).

Example: With `WEB_CONCURRENCY=4` and `RAILS_MAX_THREADS=8` (32 total Rails threads), and ~50% of requests needing SSR:

```text
renderer_workers ≥ (4 × 8 × 0.5) / 2 = 8 workers
```

> **Tip:** Monitor CPU utilization per worker. If average CPU per worker is above 80%, you need more workers. If below 20%, you can reduce.

### Rolling Worker Restarts

To mitigate memory growth, enable periodic worker restarts:

```javascript
const config = {
  allWorkersRestartInterval: 360, // Restart all workers every 6 hours
  delayBetweenIndividualWorkerRestarts: 2, // 2 minutes between each worker restart
  gracefulWorkerRestartTimeout: 30, // Kill stuck workers after 30 seconds
};
```

This drains requests from each worker before restarting, so there's no downtime.

### Container Resource Allocation

Recommended starting points for sidecar configuration:

| Container     | CPU Request | CPU Limit | Memory Request | Memory Limit |
| ------------- | ----------- | --------- | -------------- | ------------ |
| Rails         | 1–2 cores   | 2–4 cores | 4 GB           | 4 GB         |
| Node Renderer | 1–2 cores   | 2–4 cores | 4 GB           | 4 GB         |

> **Important:** Set memory **requests** equal to **limits** for the renderer container so its memory budget is explicit. Kubernetes QoS is determined at the pod level, so you only get `Guaranteed` QoS when **every** container in the pod has matching requests and limits. If using `--max-old-space-size`, set the container memory limit to `max-old-space-size × workersCount × 1.5` to account for overhead.

### jemalloc for Rails Memory

Consider using [jemalloc](https://github.com/jemalloc/jemalloc) as Ruby's memory allocator to reduce Rails memory fragmentation:

```dockerfile
RUN apt-get install -y libjemalloc2
## Adjust the preload path for your image architecture:
##   amd64: /usr/lib/x86_64-linux-gnu/libjemalloc.so.2
##   arm64: /usr/lib/aarch64-linux-gnu/libjemalloc.so.2
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
ENV MALLOC_CONF="dirty_decay_ms:1000,muzzy_decay_ms:1000"
```

This won't help the Node Renderer (which uses V8's allocator), but can significantly reduce Rails container memory.

## Graceful Shutdown

During rolling deploys and scale-down events, containers receive `SIGTERM` before being killed. Both Rails and the Node Renderer need to handle this gracefully to avoid dropping in-flight requests.

### Node Renderer

The Node Renderer's cluster manager handles `SIGTERM` automatically — it stops accepting new connections and waits for in-flight requests to complete before exiting. No additional configuration is needed.

Set `terminationGracePeriodSeconds` in your pod spec to give workers enough time to drain:

```yaml
spec:
  terminationGracePeriodSeconds: 60 # default is 30; increase if SSR requests are slow
```

### Rails

Rails handles `SIGTERM` via Puma's built-in graceful shutdown. Ensure `terminationGracePeriodSeconds` exceeds your longest expected request duration.

> **Tip:** If either process doesn't shut down within `terminationGracePeriodSeconds`, Kubernetes sends `SIGKILL`. Monitor for exit code 137 in your logs, which may indicate the grace period is too short rather than an OOM kill.

## Autoscaling Considerations

When using sidecar containers, autoscaling becomes more nuanced because CPU and memory metrics are aggregated across both containers.

### CPU-Based Autoscaling

If you previously scaled on CPU at 75%, you may need to adjust:

- **Rails-heavy traffic** (mostly API/JSON responses): Rails CPU spikes, but the renderer is idle. The pod-level CPU average may underreport Rails load.
- **SSR-heavy traffic**: Both containers are active. Pod-level CPU is more representative.

**Recommendation:** If your orchestrator supports per-container metrics (e.g., Kubernetes custom metrics), scale based on the Rails container's CPU. Otherwise, lower the threshold (e.g., to 60%) to account for the averaging effect.

### Scaling with Separate Workloads

With separate workloads, scale each independently:

- **Rails**: Scale on CPU utilization or request queue depth.
- **Node Renderer**: Scale on CPU utilization per worker.

## Tracking and Responding to Errors

### Startup Errors: `ERR_STREAM_PREMATURE_CLOSE`

During container startup, you may see `ERR_STREAM_PREMATURE_CLOSE` errors from Fastify. This occurs when Rails sends render requests before all Node Renderer workers are ready.

**Mitigation:**

1. **Health check endpoint** — The Node Renderer exposes a built-in `/info` endpoint that returns the node version and renderer version. The server accepts both HTTP/1.1 and HTTP/2 connections, so standard Kubernetes `httpGet` probes work out of the box. For a custom `/health` route with more granular checks, use the `configureFastify()` option (see [JS Configuration: Custom Fastify Configuration](./js-configuration.md#custom-fastify-configuration)). Configure your container orchestrator to wait for it before routing traffic.
2. **Startup probe** — Configure a startup probe with a generous `initialDelaySeconds`:
   ```yaml
   startupProbe:
     httpGet:
       path: /info
       port: 3800
     initialDelaySeconds: 10
     periodSeconds: 5
     failureThreshold: 6
   ```
3. **Readiness probe** — Ensure traffic is only routed to the renderer when it's ready to accept requests. The built-in `/info` endpoint confirms the process is up; for worker-level readiness, use a custom `/health` route via `configureFastify()`:
   ```yaml
   readinessProbe:
     httpGet:
       path: /info # or /health for worker-readiness semantics
       port: 3800
     periodSeconds: 5
     failureThreshold: 3
   ```
4. **Liveness probe** — Ensure the renderer is restarted if it becomes unresponsive:
   ```yaml
   livenessProbe:
     httpGet:
       path: /info
       port: 3800
     periodSeconds: 10
     failureThreshold: 3
   ```

### OOM Tracking

Distinguish between Rails and Node Renderer OOM kills by checking container-level exit codes:

- **Exit code 137**: Process received SIGKILL — commonly OOM from cgroup limit, but can also be forced termination (grace-period expiry, liveness probe failure). Check `kubectl describe pod` for `Reason: OOMKilled` to confirm OOM.
- **Exit code 1**: Application crash (check logs for stack trace).

With sidecar containers, your orchestrator should report which container was OOM-killed. Use this to tune resource limits for the specific container rather than increasing the entire pod.

### Error Reporting

See [Error Reporting and Tracing](./error-reporting-and-tracing.md) for setting up Sentry, Honeybadger, or other error tracking with the Node Renderer.

### Logging

Set log levels to capture useful information without noise:

```javascript
const config = {
  logLevel: 'info', // General renderer logs
  logHttpLevel: 'error', // Only log HTTP errors (not every request)
};
```

In production, `logLevel: 'warn'` is sufficient unless actively debugging.

## Kubernetes Sidecar Manifest

A complete pod spec for the sidecar pattern:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rails-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: rails-app
  template:
    metadata:
      labels:
        app: rails-app
    spec:
      terminationGracePeriodSeconds: 60
      containers:
        - name: rails
          image: your-app:latest
          command: ['bundle', 'exec', 'rails', 'server', '-b', '0.0.0.0']
          ports:
            - containerPort: 3000
          env:
            - name: RENDERER_URL
              value: 'http://localhost:3800'
            - name: LD_PRELOAD
              value: '/usr/lib/x86_64-linux-gnu/libjemalloc.so.2'
            - name: MALLOC_CONF
              value: 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
          resources:
            requests:
              cpu: '1'
              memory: '4Gi'
            limits:
              cpu: '2'
              memory: '4Gi'

        - name: node-renderer
          image: your-app:latest # Same image as Rails
          command: ['node', 'client/node-renderer.js']
          ports:
            - containerPort: 3800
          env:
            - name: RENDERER_HOST
              value: '0.0.0.0' # Required for Kubernetes HTTP probes
            - name: NODE_OPTIONS
              value: '--max-old-space-size=512'
            - name: RENDERER_WORKERS_COUNT
              value: '4'
          resources:
            requests:
              cpu: '1'
              memory: '4Gi'
            limits:
              cpu: '2'
              memory: '4Gi'
          startupProbe:
            httpGet:
              path: /info
              port: 3800
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 6
          readinessProbe:
            httpGet:
              path: /info # or /health for worker-readiness semantics (see configureFastify)
              port: 3800
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /info
              port: 3800
            periodSeconds: 10
            failureThreshold: 3
```

> **Note:** Both containers use the same Docker image, ensuring the React on Rails gem and Node Renderer package versions are always aligned.

## Troubleshooting

### Container restarts frequently (OOM)

1. **Check which container is OOM-killed** — Use your orchestrator's events/logs to identify if it's Rails or the Node Renderer.
2. **If Node Renderer** — Set `NODE_OPTIONS="--max-old-space-size=512"` and enable rolling restarts with both `allWorkersRestartInterval` and `delayBetweenIndividualWorkerRestarts`.
3. **If Rails** — Consider jemalloc and review `WEB_CONCURRENCY` / `RAILS_MAX_THREADS` settings.
4. **Monitor over time** — Memory growth is gradual. Monitor for 8+ hours to see the steady-state memory usage.

### Renderer connection refused after deploy

- Verify the renderer container is running and healthy.
- For sidecars: Check that the renderer binds to `localhost` (default) or `0.0.0.0`.
- For separate workloads: Verify DNS resolution and that `config.renderer_url` matches the renderer's service endpoint.
- Check for readiness probe failures that may have removed the renderer from the service.

### Different versions after deploy (separate workloads)

The React on Rails gem and Node Renderer package have a protocol version. If they mismatch, render requests return an error. To avoid this:

- **Sidecars**: Both containers use the same image, so versions are always aligned.
- **Separate workloads**: Deploy both workloads simultaneously. If your orchestrator doesn't support atomic multi-workload deploys, consider switching to sidecars.

### High latency on SSR requests

1. **Check worker count** — If all workers are busy, requests queue up. Increase `workersCount` or scale replicas.
2. **Check `max-old-space-size`** — If set too low, frequent GC pauses increase latency. Increase the limit.
3. **Profile components** — Use `node --inspect` to profile server-rendering code. See [Profiling Server-Side Rendering Code](../../../pro/profiling-server-side-rendering-code.md).

### Startup race condition between Rails and Node Renderer

In sidecar configurations, Rails may start before the Node Renderer is ready. Configure `renderer_request_retry_limit` in Rails to retry failed connections:

```ruby
ReactOnRailsPro.configure do |config|
  config.renderer_request_retry_limit = 5  # default: 5
end
```

This handles transient startup ordering issues. For a more robust solution, add a startup dependency or init container that waits for the renderer's `/info` endpoint.

## ControlPlane-Specific Notes

When deploying on [ControlPlane](https://controlplane.com):

- **Port configuration:** Use `process.env.PORT` for the renderer port if running as a standalone workload. ControlPlane injects the `PORT` environment variable for the primary container.
- **Sidecar setup:** Configure separate CPU and memory limits per container in your workload definition. In ControlPlane, sidecar containers are defined alongside the main container in the same workload spec.
- **Autoscaling:** ControlPlane uses workload-level metrics for autoscaling — see [Autoscaling Considerations](#autoscaling-considerations) above. If you need per-container scaling, use separate workloads instead of sidecars.
- **Health checks:** ControlPlane supports readiness and liveness probes in the same format as Kubernetes. Configure them as shown in the [Kubernetes Sidecar Manifest](#kubernetes-sidecar-manifest) section.

## References

- [Node Renderer Basics](./basics.md)
- [JS Configuration](./js-configuration.md)
- [Error Reporting and Tracing](./error-reporting-and-tracing.md)
- [Heroku Deployment](./heroku.md)
- [JS Memory Leaks](../../../pro/js-memory-leaks.md)
- [Profiling Server-Side Rendering Code](../../../pro/profiling-server-side-rendering-code.md)
- [Pro Troubleshooting](../../../pro/troubleshooting.md)
