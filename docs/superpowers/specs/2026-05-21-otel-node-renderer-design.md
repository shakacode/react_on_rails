# OpenTelemetry Support for React on Rails Pro Node Renderer

- **Issue:** [#2156](https://github.com/shakacode/react_on_rails/issues/2156)
- **Date:** 2026-05-21
- **Status:** Design — awaiting user review

## Summary

Add OpenTelemetry instrumentation to the React on Rails Pro Node Renderer as a new
optional integration, following the same opt-in pattern as the existing Sentry and
Honeybadger integrations. The integration auto-instruments HTTP and Fastify, wires
into the existing `setupTracing` abstraction so SSR rendering becomes a first-class
span, and emits rich sub-spans for the critical render-path operations (bundle load,
VM execution, result preparation, incremental streams).

Configuration follows standard OpenTelemetry conventions (env vars like
`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES`), so
the integration is exporter-agnostic and works with any OTLP-compatible backend
(Jaeger, Honeycomb, Datadog, Grafana Tempo, New Relic, etc.).

## Goals

1. Distributed tracing for the Node Renderer that integrates with the standard
   OpenTelemetry ecosystem.
2. Zero impact on users who do not enable OpenTelemetry — no new direct dependencies,
   no runtime overhead, no required code changes.
3. Unified spans: incoming HTTP request, Fastify routing, SSR rendering, and
   outbound HTTP calls all linked in a single trace.
4. Rich sub-spans for the render path so users can debug latency at the level of
   "is the bundle load slow?" vs "is the VM execution slow?".
5. Production-safe defaults (batched export, graceful shutdown, no PII leakage).

## Non-Goals

- Auto-detection / auto-init of OpenTelemetry when `OTEL_*` env vars are set without
  user code change. (We require an explicit `init()` call to stay consistent with
  Sentry and Honeybadger integrations.)
- Metrics or logs export. This spec covers traces only. Metrics/logs can be added
  later in a follow-up.
- Replacing the Sentry or Honeybadger integrations. OpenTelemetry coexists with them.
- Custom exporter implementations. Users get the standard OTLP HTTP exporter by
  default and can pass any OTel-compatible exporter via `init({ exporter })`.

## Background: existing architecture

The Node Renderer already has the integration plumbing this work needs:

- **`packages/react-on-rails-pro-node-renderer/src/integrations/`** — Each integration
  (`sentry.ts`, `sentry6.ts`, `honeybadger.ts`) exports an `init()` function that
  users call from their entrypoint. Optional peer dependencies in `package.json` mark
  the underlying SDKs as not-required.
- **`src/integrations/api.ts`** — Public surface that integrations import from:
  `setupTracing`, `configureFastify`, `addErrorNotifier`, `addMessageNotifier`,
  `log`, etc.
- **`src/shared/tracing.ts`** — Generic pluggable tracing abstraction. Augments
  `UnitOfWorkOptions` per integration. Exposes `setupTracing({ executor,
startSsrRequestOptions })` so integrations can wrap each `trace(fn, opts)` call in
  their own span. The SSR request path in `src/worker.ts` already calls
  `trace(async (context) => handleRenderRequest({...}), startSsrRequestOptions({...}))`.
- **`src/worker.ts` `configureFastify(fn)`** — Lets integrations register Fastify
  hooks (used by Sentry for `setupFastifyErrorHandler`).

The OpenTelemetry integration plugs into this existing machinery — it does not
require changes to the abstraction itself, only narrow additions inside the worker
render-path functions to create sub-spans.

**Framework note:** the renderer uses **Fastify**, not Express. Issue #2156's example
references `@opentelemetry/instrumentation-express`, which would be inert here.
We use `@opentelemetry/instrumentation-fastify` instead.

## User-facing API

### Installing

Users install OTel packages themselves (peer deps):

```bash
npm install \
  @opentelemetry/api \
  @opentelemetry/sdk-trace-node \
  @opentelemetry/sdk-trace-base \
  @opentelemetry/resources \
  @opentelemetry/semantic-conventions \
  @opentelemetry/exporter-trace-otlp-http \
  @opentelemetry/instrumentation \
  @opentelemetry/instrumentation-http \
  @opentelemetry/instrumentation-fastify
```

### Enabling

In the user's entrypoint (replacing `default-node-renderer.ts` or similar):

```ts
// Must run before any Fastify or HTTP code is loaded so auto-instrumentation
// can patch the modules at require-time.
import { init as initOpenTelemetry } from 'react-on-rails-pro-node-renderer/integrations/opentelemetry';

initOpenTelemetry({
  serviceName: 'react-on-rails-pro-node-renderer', // optional; defaults to this
  fastify: true, // register Fastify instrumentation
  tracing: true, // wrap SSR work in spans
});

// After init, start the renderer:
import { reactOnRailsProNodeRenderer } from 'react-on-rails-pro-node-renderer';
reactOnRailsProNodeRenderer().catch(/* … */);
```

### Configuring

All configuration goes through standard OTel env vars:

| Env var                                          | Purpose                                    | Default                               |
| ------------------------------------------------ | ------------------------------------------ | ------------------------------------- |
| `OTEL_EXPORTER_OTLP_ENDPOINT`                    | OTLP collector endpoint                    | `http://localhost:4318`               |
| `OTEL_EXPORTER_OTLP_HEADERS`                     | Optional auth headers (e.g. `api-key=xxx`) | none                                  |
| `OTEL_SERVICE_NAME`                              | Service name in traces                     | falls back to `init({ serviceName })` |
| `OTEL_RESOURCE_ATTRIBUTES`                       | Additional resource attrs (csv)            | none                                  |
| `OTEL_TRACES_SAMPLER`, `OTEL_TRACES_SAMPLER_ARG` | Sampling                                   | parent-based, always-on               |

`init()` options for non-env cases:

```ts
init({
  serviceName?: string;       // default: 'react-on-rails-pro-node-renderer'
  fastify?: boolean;          // default: false — register Fastify instr
  tracing?: boolean;          // default: false — wrap SSR in spans
  exporter?: SpanExporter;    // default: OTLPTraceExporter from env
  spanProcessor?: SpanProcessor; // default: see below
  resourceAttributes?: Record<string, string>; // merged with defaults
})
```

### Span processor default

- **Production** (`NODE_ENV === 'production'` || `RAILS_ENV === 'production'`):
  `BatchSpanProcessor` — production performance, batches and exports asynchronously.
- **Otherwise:** `SimpleSpanProcessor` — synchronous, useful for local debugging.
- Always overridable via `init({ spanProcessor })`.

## Components

### 1. `src/integrations/opentelemetry.ts` _(new file)_

Public entrypoint. Responsibilities:

- Validate that required OTel packages are installed; if missing, log a helpful
  error message via `message()` and return without initializing.
- Build the `Resource` from defaults + env vars + user overrides.
- Construct `NodeTracerProvider` with the chosen span processor.
- Register `HttpInstrumentation` and (if `fastify`) `FastifyInstrumentation`.
- If `tracing`, call `setupTracing({ executor, startSsrRequestOptions })` where the
  executor wraps `fn` in `tracer.startActiveSpan('ror.ssr.request', …)`.
- Register a graceful-shutdown hook so spans flush before process exit. Coordinates
  with the existing `handleGracefulShutdown` mechanism — calling
  `tracerProvider.shutdown()` before workers exit.
- Augment `UnitOfWorkOptions` with `opentelemetry?: { name?: string; attributes?: …; }`.

### 2. `src/shared/tracing.ts` _(no functional change)_

Already pluggable. The OTel integration uses the existing
`setupTracing({ executor, startSsrRequestOptions })` exactly the same way
`sentry.ts` does. The module augmentation in `opentelemetry.ts` adds
the `opentelemetry?` property to `UnitOfWorkOptions`.

### 3. Sub-span helpers _(new — small)_

To keep the render-path code legible and to avoid hard-coding OTel API calls in
files that should not import OTel, add a tiny helper in `src/shared/tracing.ts`:

```ts
export type SubSpanOptions = { name: string; attributes?: Record<string, string | number | boolean> };
export function subSpan<T>(opts: SubSpanOptions, fn: () => Promise<T>): Promise<T>;
```

Default implementation: pass-through (just calls `fn()`). Integrations can install
their own implementation via a setter that mirrors `setupTracing`:

```ts
export function setupSubSpan(impl: SubSpanFn): void;
```

This keeps `handleRenderRequest.ts` free of any direct OTel imports — it just calls
`subSpan({ name: 'ror.bundle.build_execution_context', attributes: { … } }, () => buildExecutionContext(…))`.

### 4. `src/worker/handleRenderRequest.ts` _(small additions)_

Wrap the critical calls with `subSpan`:

| Span name                            | Wraps                                              | Attributes                                                                         |
| ------------------------------------ | -------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `ror.bundle.build_execution_context` | `buildExecutionContext(...)`                       | `bundle.timestamp`, `bundle.paths.count`, `cache.hit` (true if no VM build needed) |
| `ror.bundle.upload`                  | `handleNewBundlesProvided(...)`                    | `bundle.count`, `assets.count`, `bytes.total`                                      |
| `ror.vm.execute`                     | The actual SSR JS execution inside `prepareResult` | `bundle.timestamp`                                                                 |
| `ror.result.prepare`                 | The rest of `prepareResult`                        | `response.bytes`                                                                   |

No semantic logic changes — only sub-span wrapping.

### 5. `src/worker/handleIncrementalRenderRequest.ts` and `handleIncrementalRenderStream.ts`

Wrap the incremental stream lifecycle:

| Span name                       | Wraps                                | Attributes                                  |
| ------------------------------- | ------------------------------------ | ------------------------------------------- |
| `ror.incremental.stream`        | Full stream lifecycle                | `chunks.count`, `duration_to_first_byte_ms` |
| `ror.incremental.process_chunk` | `incrementalSink.add(obj)` per chunk | `chunk.bytes`, `chunk.index`                |

### 6. `src/worker.ts` _(no change for SSR root span)_

The existing `trace(async (context) => handleRenderRequest({...}), startSsrRequestOptions({...}))`
already creates the root SSR span via the integration's executor. No code change
needed — the OTel integration's executor produces the `ror.ssr.request` span.

### 7. Graceful shutdown

`src/worker/handleGracefulShutdown.ts` already runs cleanup before worker exit. We
add a hook that calls `tracerProvider.shutdown()` to flush pending batched spans
when OTel is initialized. The OTel integration registers this hook through a small
addition to the existing graceful-shutdown plumbing (a new
`addShutdownTask(fn)` export from the worker module, if one doesn't already exist).

### 8. `package.json` _(deps)_

Add as **optional peer dependencies** (matching the existing pattern):

```jsonc
"peerDependencies": {
  // … existing …
  "@opentelemetry/api": ">=1.9.0",
  "@opentelemetry/sdk-trace-node": ">=2.0.0",
  "@opentelemetry/sdk-trace-base": ">=2.0.0",
  "@opentelemetry/resources": ">=2.0.0",
  "@opentelemetry/semantic-conventions": ">=1.36.0",
  "@opentelemetry/exporter-trace-otlp-http": ">=0.203.0",
  "@opentelemetry/instrumentation": ">=0.203.0",
  "@opentelemetry/instrumentation-http": ">=0.203.0",
  "@opentelemetry/instrumentation-fastify": ">=0.52.0"
},
"peerDependenciesMeta": {
  // … existing …
  "@opentelemetry/api": { "optional": true },
  // … repeat for every @opentelemetry/* peer
}
```

Add OTel packages to `devDependencies` so the renderer's own tests can exercise the
integration.

## Data flow (end-to-end SSR request)

```
1. HTTP request arrives at Fastify worker
2. HttpInstrumentation → root span "POST /bundles/.../render/..."
3. FastifyInstrumentation → child "request handler" span
4. Worker calls `trace(fn, startSsrRequestOptions(…))`
5. OTel executor → child span "ror.ssr.request" (with attributes:
   bundle.timestamp, dependency_count, request.bytes)
6. handleRenderRequest runs:
   - subSpan "ror.bundle.build_execution_context"  (with cache.hit)
   - (if bundles posted) subSpan "ror.bundle.upload"
   - subSpan "ror.vm.execute"
   - subSpan "ror.result.prepare"
7. Outbound HTTP calls inside the bundle → automatic child spans
   via HttpInstrumentation
8. Response sent → spans closed → BatchSpanProcessor exports to OTLP
```

For incremental rendering, replace step 5 with the existing incremental wrapper
plus a `ror.incremental.stream` span that encloses `ror.incremental.process_chunk`
sub-spans for each NDJSON chunk.

## Error handling

1. **Init failure** — Required `@opentelemetry/*` packages missing or fail to
   import. Caught in `init()`, logged via `errorReporter.message()`, and the
   integration silently no-ops. The renderer keeps running.
2. **Exporter failure** — OTLP endpoint unreachable. OTel SDK already swallows
   exporter errors. We add a `diag` hook that pipes OTel internal logs into the
   renderer's pino logger at `debug` level so they don't pollute logs at higher
   levels.
3. **Span attribute serialization failure** — Caller passes a non-serializable
   value. Wrap attribute setters in try/catch in `subSpan` so a bad attribute
   never breaks a render.
4. **Shutdown timeout** — `tracerProvider.shutdown()` has its own internal timeout.
   The renderer's graceful shutdown also has a hard kill timer (existing behavior),
   so a hung exporter cannot block worker exit indefinitely.
5. **Sensitive data** — The `renderingRequest` string can contain user input. We
   **must not** put it (or a digest derived from it) into span attributes. Only
   the bundle timestamp, sizes, and counts are recorded.

## Testing

### Unit tests

Use `@opentelemetry/sdk-trace-base`'s `InMemorySpanExporter` + a
`SimpleSpanProcessor` to assert span structure without network I/O.

1. **`init()` with missing peer deps** — temporarily mask `@opentelemetry/api` and
   assert `init()` logs the expected message and returns without throwing.
2. **`init({ fastify: false, tracing: false })`** — no auto-instrumentation, no
   `setupTracing` call, but tracer provider still registered.
3. **`init({ fastify: true, tracing: true })`** — full setup. Issue a render
   request via `app.inject()` (existing test helper) and assert the resulting
   span tree:
   - 1× `ror.ssr.request` root span with expected attributes
   - 1× `ror.bundle.build_execution_context` child
   - 1× `ror.vm.execute` child
   - 1× `ror.result.prepare` child
   - parent/child relationships correct, no orphans
4. **Bundle upload path** — Issue a render with a new bundle, assert
   `ror.bundle.upload` span appears with expected attrs.
5. **Incremental render** — Stream an NDJSON incremental render, assert
   `ror.incremental.stream` encloses `ror.incremental.process_chunk` spans.
6. **Error path** — Force a `VMContextNotFoundError`, assert the SSR root span
   has `status.code = ERROR` and `status.message` set, but the worker did not
   crash.
7. **Graceful shutdown** — Invoke the shutdown task, assert
   `tracerProvider.shutdown()` was called and pending spans were flushed.
8. **Sensitive data audit** — Assert no span attribute contains the literal
   `renderingRequest` payload.

### Integration test

A small integration test that runs an actual worker with OTel enabled against an
in-process OTLP HTTP collector mock (a Fastify server bound to `127.0.0.1:0`),
issues a render, and asserts the collector received spans with the expected
service name and attributes.

## Migration / rollout

- This is purely additive — no existing user code or config changes.
- Document in `docs/pro/node-renderer.md` under a new "Observability" subsection
  with the install + `init()` snippet and a table of env vars.
- Add a CHANGELOG entry under "Added" in the Pro changelog.

## Open questions

None for this iteration. Defer the following to follow-ups:

- Metrics export (request rate, render duration histogram, VM pool size, etc.)
- Logs correlation (pino + OTel log bridge)
- Auto-init via env var only (skip the explicit `init()` call) — punt unless
  users request it.

## Spec self-review

- **Placeholders:** None. All sections complete.
- **Internal consistency:** Sub-span helper is introduced in §3 and consumed in
  §4 and §5. Peer dep list in §8 matches packages referenced in §1 and Issue
  #2156's dependency list (with Express swapped for Fastify).
- **Scope:** Single integration with a clear surface and bounded changes
  (1 new file, small additions to ~4 existing files, no abstraction changes).
  Fits a single implementation plan.
- **Ambiguity:** Span processor default explicitly tied to
  `NODE_ENV`/`RAILS_ENV` per existing license-validator convention; service-name
  precedence (env var → `init` option → default) is explicit; sensitive-data
  rule is explicit (no `renderingRequest` in attributes).
