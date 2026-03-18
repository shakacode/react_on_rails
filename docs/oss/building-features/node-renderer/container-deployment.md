# Node Renderer: Container Deployment

> **Pro Feature** — Available with [React on Rails Pro](https://pro.reactonrails.com).
> Free or very low cost for startups and small companies. [Get a license →](mailto:justin@shakacode.com)

This guide covers deploying the Node Renderer in containerized environments (Docker, Kubernetes, ControlPlane, etc.), including architecture options, performance tuning, memory management, error tracking, and troubleshooting.

## Architecture: Sidecar vs. Separate Workload

When running Rails and the Node Renderer in containers, you have two options:

### Option 1: Sidecar Containers (Recommended)

Rails and the Node Renderer run as separate containers within the **same pod/workload**, sharing the same lifecycle.

```
┌─────────────────────────────────┐
│           Pod / Workload        │
│  ┌─────────────┐ ┌───────────┐ │
│  │    Rails     │ │   Node    │ │
│  │  Container   │ │ Renderer  │ │
│  │  (2 CPU,     │ │ (2 CPU,   │ │
│  │   4 GB RAM)  │ │  4 GB RAM)│ │
│  └──────┬───────┘ └─────┬─────┘ │
│         │   localhost    │       │
│         └───────┬────────┘       │
└─────────────────┘────────────────┘
```

**Advantages:**
- **Guaranteed version alignment** — Both containers use the same image, so the React on Rails gem and Node Renderer package are always in sync during rolling deploys.
- **Simpler networking** — Rails connects to the renderer via `localhost`.
- **Atomic deploys** — No risk of old Rails talking to new Node Renderer or vice versa.

**Configuration:**
```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = "http://localhost:3800"
end
```

### Option 2: Separate Workloads

Rails and the Node Renderer run as independent workloads with their own scaling.

**Advantages:**
- **Independent scaling** — Scale the renderer independently of Rails.
- **Isolated resource limits** — OOM in the renderer doesn't affect Rails and vice versa.

**Disadvantages:**
- **Version drift risk** — During rolling deploys, Rails and the Node Renderer may briefly run different versions. While protocol changes are rare, this is a risk to monitor.
- **Network dependency** — Renderer must be reachable via internal service DNS.
- **Independent restarts** — Containers restart on their own schedule, which may cause transient connection errors.

**Configuration:**
```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = ENV.fetch("RENDERER_URL", "http://node-renderer-service:3800")
end
```

> **Recommendation:** Start with sidecar containers. Only move to separate workloads if you have a specific need for independent scaling. For most apps running 2–4 replicas, sidecars are simpler and more reliable.

## Host Binding for Container Environments

By default, the Node Renderer binds to `localhost`, which rejects connections from other containers. In both sidecar and separate-workload configurations, you need to bind to `0.0.0.0`:

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
```
RENDERER_HOST=0.0.0.0
```

> **Security note:** Binding to `0.0.0.0` exposes the renderer on all network interfaces. This is safe behind private networking (e.g., within a Kubernetes pod or behind a firewall). If the renderer is exposed to untrusted networks, enable the `password` authentication option. See [JS Configuration](./js-configuration.md) for details.

## Optimizing Performance per Cost

### Memory: Understanding the Growth Pattern

The Node Renderer's memory grows over time as it handles SSR requests. This is **expected behavior** — V8's garbage collector doesn't always return memory to the OS, even after objects are freed. In containerized environments with cgroup memory limits, this can trigger OOM kills.

Typical memory profile:
- **Startup:** ~500–600 MB for the renderer process with workers
- **After hours of traffic:** 2–3 GB+ depending on component complexity and traffic volume
- **Rails container:** Usually stabilizes at 2–4 GB depending on `WEB_CONCURRENCY` and `RAILS_MAX_THREADS`

### Constraining Node Memory

Use `NODE_OPTIONS` to cap V8's old-generation heap per worker:

```
NODE_OPTIONS="--max-old-space-size=512"
```

This tells V8 to trigger garbage collection more aggressively and limits each worker's heap. Adjust the value based on your component complexity:

| Component Complexity | Recommended `max-old-space-size` |
|---------------------|----------------------------------|
| Simple components | 256–512 MB |
| Medium (Redux, large props) | 512–768 MB |
| Complex (large data, many components) | 768–1024 MB |

> **Note:** This setting applies per worker. Total renderer memory ≈ `max-old-space-size × workersCount + overhead`. If V8 hits the limit, the worker process exits and is automatically restarted by the cluster manager.

### Worker Count Tuning

The default `workersCount` is CPU count minus 1, which may over-allocate in containers. Set it explicitly:

```javascript
const config = {
  workersCount: parseInt(process.env.RENDERER_WORKERS_COUNT || '8', 10),
};
```

**Sizing guideline:** Match worker count to expected concurrent SSR requests.

A rough formula:
```
renderer_workers ≥ (WEB_CONCURRENCY × RAILS_MAX_THREADS × ssr_request_ratio) / 2
```

Where `ssr_request_ratio` is the fraction of requests that need server rendering (often 30–60% for hybrid apps).

Example: With `WEB_CONCURRENCY=4` and `RAILS_MAX_THREADS=8` (32 total Rails threads), and ~50% of requests needing SSR:
```
renderer_workers ≥ (4 × 8 × 0.5) / 2 = 8 workers
```

> **Tip:** Monitor CPU utilization per worker. If average CPU per worker is above 80%, you need more workers. If below 20%, you can reduce.

### Rolling Worker Restarts

To mitigate memory growth, enable periodic worker restarts:

```javascript
const config = {
  allWorkersRestartInterval: 360,                    // Restart all workers every 6 hours
  delayBetweenIndividualWorkerRestarts: 2,           // 2 minutes between each worker restart
  gracefulWorkerRestartTimeout: 30,                  // Kill stuck workers after 30 seconds
};
```

This drains requests from each worker before restarting, so there's no downtime.

### Container Resource Allocation

Recommended starting points for sidecar configuration:

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Rails | 1–2 cores | 2–4 cores | 2 GB | 4 GB |
| Node Renderer | 1–2 cores | 2–4 cores | 2 GB | 4 GB |

> **Important:** Set memory **requests** equal to **limits** for the renderer container. This prevents the container from being evicted under memory pressure (OOM priority). If using `--max-old-space-size`, set the container memory limit to `max-old-space-size × workersCount × 1.5` to account for overhead.

### jemalloc for Rails Memory

Consider using [jemalloc](https://github.com/jemalloc/jemalloc) as Ruby's memory allocator to reduce Rails memory fragmentation:

```dockerfile
RUN apt-get install -y libjemalloc2
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
ENV MALLOC_CONF="dirty_decay_ms:1000,muzzy_decay_ms:1000"
```

This won't help the Node Renderer (which uses V8's allocator), but can significantly reduce Rails container memory.

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
1. **Health check endpoint** — Add a `/health` route (see [JS Configuration: Custom Fastify Configuration](./js-configuration.md#custom-fastify-configuration)) and configure your container orchestrator to wait for it before routing traffic.
2. **Startup probe** — Configure a startup probe with a generous `initialDelaySeconds`:
   ```yaml
   startupProbe:
     httpGet:
       path: /health
       port: 3800
     initialDelaySeconds: 10
     periodSeconds: 5
     failureThreshold: 6
   ```
3. **Liveness probe** — Ensure the renderer is restarted if it becomes unresponsive:
   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 3800
     periodSeconds: 10
     failureThreshold: 3
   ```

### OOM Tracking

Distinguish between Rails and Node Renderer OOM kills by checking container-level exit codes:

- **Exit code 137**: Killed by OOM (SIGKILL from cgroup limit).
- **Exit code 1**: Application crash (check logs for stack trace).

With sidecar containers, your orchestrator should report which container was OOM-killed. Use this to tune resource limits for the specific container rather than increasing the entire pod.

### Error Reporting

See [Error Reporting and Tracing](./error-reporting-and-tracing.md) for setting up Sentry, Honeybadger, or other error tracking with the Node Renderer.

### Logging

Set log levels to capture useful information without noise:

```javascript
const config = {
  logLevel: 'info',       // General renderer logs
  logHttpLevel: 'error',  // Only log HTTP errors (not every request)
};
```

In production, `logLevel: 'warn'` is sufficient unless actively debugging.

## Troubleshooting

### Container restarts frequently (OOM)

1. **Check which container is OOM-killed** — Use your orchestrator's events/logs to identify if it's Rails or the Node Renderer.
2. **If Node Renderer** — Set `NODE_OPTIONS="--max-old-space-size=512"` and enable `allWorkersRestartInterval`.
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
  config.renderer_request_retry_limit = 5  # default
end
```

This handles transient startup ordering issues. For a more robust solution, add a startup dependency or init container that waits for the renderer's health endpoint.

## ControlPlane-Specific Notes

When deploying on [ControlPlane](https://controlplane.com):

- Use `process.env.PORT` for the renderer port if running as a standalone workload.
- For sidecar containers, configure separate CPU and memory limits per container in your workload YAML.
- Autoscaling uses pod-level metrics — see [Autoscaling Considerations](#autoscaling-considerations) above.

## References

- [Node Renderer Basics](./basics.md)
- [JS Configuration](./js-configuration.md)
- [Error Reporting and Tracing](./error-reporting-and-tracing.md)
- [Heroku Deployment](./heroku.md)
- [JS Memory Leaks](../../../pro/js-memory-leaks.md)
- [Profiling Server-Side Rendering Code](../../../pro/profiling-server-side-rendering-code.md)
- [Pro Troubleshooting](../../../pro/troubleshooting.md)
