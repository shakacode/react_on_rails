# OpenTelemetry Node Renderer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add OpenTelemetry support to the React on Rails Pro Node Renderer as a new optional integration (matching the Sentry/Honeybadger pattern), with auto-instrumented HTTP + Fastify spans, a manual SSR root span, and rich sub-spans for bundle load, VM execution, result preparation, and incremental stream lifecycle.

**Architecture:** A new `src/integrations/opentelemetry.ts` module exposes `init({ serviceName, fastify, tracing })`. It plugs into the existing pluggable tracing abstraction (`shared/tracing.ts` — `setupTracing` and a new `setupSubSpan`) so that the render-path code in `worker/*` calls `subSpan(...)` without importing OpenTelemetry. Sub-span helpers are no-ops when OTel is not initialized, so the renderer pays zero cost for users who don't enable it.

**Tech Stack:** TypeScript, Fastify 5, Jest, pino logging, `@opentelemetry/api`, `@opentelemetry/sdk-trace-node`, `@opentelemetry/sdk-trace-base`, `@opentelemetry/exporter-trace-otlp-http`, `@opentelemetry/instrumentation`, `@opentelemetry/instrumentation-http`, `@opentelemetry/instrumentation-fastify`, `@opentelemetry/resources`, `@opentelemetry/semantic-conventions`.

**Spec:** `docs/superpowers/specs/2026-05-21-otel-node-renderer-design.md`
**Issue:** [#2156](https://github.com/shakacode/react_on_rails/issues/2156)

---

## File Structure

### Files to create

| Path                                                                                      | Responsibility                                                                                                                                                                |
| ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`             | Public `init()` entry point. Sets up `NodeTracerProvider`, registers HTTP/Fastify instrumentation, wires `setupTracing` + `setupSubSpan`, registers `onClose` shutdown flush. |
| `packages/react-on-rails-pro-node-renderer/tests/shared/subSpan.test.ts`                  | Unit tests for the `subSpan`/`setupSubSpan` helper in `shared/tracing.ts` (no-op default, registered impl is called, errors don't crash callers).                             |
| `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`      | End-to-end span-tree assertions: `init()` paths, fastify-only, tracing-only, full integration via `app.inject()` with `InMemorySpanExporter`.                                 |
| `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry-init.test.ts` | Init failure path: missing peer deps, init returns gracefully, no crash.                                                                                                      |

### Files to modify

| Path                                                                                     | Change                                                                                                                                             |
| ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages/react-on-rails-pro-node-renderer/src/shared/tracing.ts`                        | Add `SubSpanOptions`, `SubSpanFn`, `subSpan()`, `setupSubSpan()`. Augment `UnitOfWorkOptions` later (in opentelemetry.ts via declaration merging). |
| `packages/react-on-rails-pro-node-renderer/src/integrations/api.ts`                      | Re-export `subSpan`, `setupSubSpan`, `SubSpanOptions`, `SubSpanFn` from the public api surface.                                                    |
| `packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts`            | Wrap `buildExecutionContext` (2 call sites), `handleNewBundlesProvided`, and `prepareResult` (with `runInVM` inside it) in `subSpan(...)`.         |
| `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderRequest.ts` | Wrap `incrementalSink.add` in `subSpan('ror.incremental.process_chunk', ...)`.                                                                     |
| `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderStream.ts`  | Wrap the full stream lifecycle in `subSpan('ror.incremental.stream', ...)`.                                                                        |
| `packages/react-on-rails-pro-node-renderer/package.json`                                 | Add `@opentelemetry/*` packages to `peerDependencies` + `peerDependenciesMeta.optional` and to `devDependencies`.                                  |
| `CHANGELOG.md`                                                                           | Add `[Pro]` entry under `[Unreleased]` → `### Added`.                                                                                              |
| `docs/pro/node-renderer.md`                                                              | Add "Observability" section with install + `init()` + env vars table.                                                                              |

---

## Task 1: Add `subSpan` helper to `shared/tracing.ts`

Add a pluggable sub-span mechanism so render-path code can request named spans without importing OpenTelemetry. Default implementation is a pass-through; integrations replace it via `setupSubSpan`.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/src/shared/tracing.ts`
- Modify: `packages/react-on-rails-pro-node-renderer/src/integrations/api.ts`
- Test: `packages/react-on-rails-pro-node-renderer/tests/shared/subSpan.test.ts`

- [ ] **Step 1: Write the failing test**

Create `packages/react-on-rails-pro-node-renderer/tests/shared/subSpan.test.ts`:

```ts
import { jest } from '@jest/globals';
import { subSpan, setupSubSpan, type SubSpanFn } from '../../src/shared/tracing';

describe('subSpan', () => {
  test('default implementation is a pass-through that returns fn() result', async () => {
    const result = await subSpan({ name: 'test.span' }, async () => 42);
    expect(result).toBe(42);
  });

  test('default implementation propagates errors from fn()', async () => {
    await expect(
      subSpan({ name: 'test.span' }, async () => {
        throw new Error('boom');
      }),
    ).rejects.toThrow('boom');
  });

  test('setupSubSpan installs custom implementation that receives name + attributes', async () => {
    const impl = jest.fn<SubSpanFn>(async (_opts, fn) => fn());
    setupSubSpan(impl);
    const result = await subSpan(
      { name: 'test.span', attributes: { 'bundle.timestamp': '123' } },
      async () => 'ok',
    );
    expect(result).toBe('ok');
    expect(impl).toHaveBeenCalledTimes(1);
    expect(impl.mock.calls[0]![0]).toEqual({
      name: 'test.span',
      attributes: { 'bundle.timestamp': '123' },
    });
  });

  test('installed implementation that throws inside the wrapper still surfaces fn() result via fallback', async () => {
    // The contract is: subSpan must never break the caller. If the installed impl
    // throws BEFORE calling fn(), we fall back to running fn() directly.
    setupSubSpan(() => {
      throw new Error('impl crashed');
    });
    const result = await subSpan({ name: 'test.span' }, async () => 'fallback-ok');
    expect(result).toBe('fallback-ok');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/shared/subSpan.test.ts`
Expected: FAIL with "Cannot find module" or "subSpan is not a function".

- [ ] **Step 3: Add `subSpan` + `setupSubSpan` to `shared/tracing.ts`**

At the end of `packages/react-on-rails-pro-node-renderer/src/shared/tracing.ts`, append:

```ts
/**
 * Options passed to a sub-span wrapper.
 *
 * `name` is the span name (use dot.namespaced form, e.g. `ror.bundle.upload`).
 * `attributes` are arbitrary key/value pairs attached to the span.
 */
export interface SubSpanOptions {
  name: string;
  attributes?: Record<string, string | number | boolean>;
}

/**
 * Signature of a sub-span implementation installed via {@link setupSubSpan}.
 * Must invoke `fn()` and return its result. May wrap `fn()` in a tracing span.
 */
export type SubSpanFn = <T>(opts: SubSpanOptions, fn: () => Promise<T>) => Promise<T>;

const defaultSubSpan: SubSpanFn = (_opts, fn) => fn();
let subSpanImpl: SubSpanFn = defaultSubSpan;

/**
 * Install a sub-span implementation. Integrations call this from their `init()`
 * to start receiving sub-span events. If never called, sub-spans are no-ops.
 */
export function setupSubSpan(impl: SubSpanFn): void {
  subSpanImpl = impl;
}

/**
 * Wrap an async function in a named sub-span. Safe to call even when no
 * integration is installed — defaults to passing through to `fn()`.
 *
 * If the installed implementation throws synchronously before invoking `fn()`,
 * the caller is shielded: `fn()` is still executed and its result returned.
 */
export function subSpan<T>(opts: SubSpanOptions, fn: () => Promise<T>): Promise<T> {
  try {
    return subSpanImpl(opts, fn);
  } catch (err) {
    message(`subSpan implementation threw before invoking fn(): ${String(err)}`);
    return fn();
  }
}
```

Note: `message` is already imported at the top of the file (`import { message } from './errorReporter.js';`).

- [ ] **Step 4: Add a `__resetSubSpanForTest` export for test isolation**

After the `subSpan` export, append:

```ts
/**
 * Test-only: reset the installed sub-span implementation back to the default
 * pass-through. Must be called in `beforeEach`/`afterEach` of any test that
 * calls `setupSubSpan`, since the module-level `subSpanImpl` leaks across tests
 * within the same Jest test file (jest's `resetModules` is per-file).
 *
 * Not part of the public api — do not re-export from `integrations/api.ts`.
 */
export function __resetSubSpanForTest(): void {
  subSpanImpl = defaultSubSpan;
}
```

Update the test to call this in `beforeEach`:

```ts
import { subSpan, setupSubSpan, __resetSubSpanForTest, type SubSpanFn } from '../../src/shared/tracing';

beforeEach(() => {
  __resetSubSpanForTest();
});
```

- [ ] **Step 5: Re-export from `integrations/api.ts`**

Edit `packages/react-on-rails-pro-node-renderer/src/integrations/api.ts`. Replace the existing `setupTracing` re-export block with:

```ts
export {
  setupTracing,
  setupSubSpan,
  subSpan,
  TracingContext,
  TracingIntegrationOptions,
  UnitOfWorkOptions,
  SubSpanOptions,
  SubSpanFn,
} from '../shared/tracing.js';
```

(Do **not** re-export `__resetSubSpanForTest` — it's a test-only escape hatch.)

- [ ] **Step 6: Run test to verify it passes**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/shared/subSpan.test.ts`
Expected: PASS, 4 tests passing.

- [ ] **Step 7: Run type-check**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm type-check`
Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/shared/tracing.ts \
        packages/react-on-rails-pro-node-renderer/src/integrations/api.ts \
        packages/react-on-rails-pro-node-renderer/tests/shared/subSpan.test.ts
git commit -m "feat(node-renderer): add pluggable subSpan helper for tracing integrations (#2156)"
```

---

## Task 2: Wrap render-path operations with `subSpan` in `handleRenderRequest.ts`

Add no-op-safe `subSpan` wrappers around the three expensive operations: bundle load (`buildExecutionContext`), new-bundle upload (`handleNewBundlesProvided`), and the SSR execution + result prep (`prepareResult`). When OTel is not initialized, these are pure pass-throughs.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts`
- Test: `packages/react-on-rails-pro-node-renderer/tests/handleRenderRequest.test.ts` (existing — must continue passing)

- [ ] **Step 1: Add the `subSpan` import**

At the top of `packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts`, alongside the existing tracing import (`import type { TracingContext } from '../shared/tracing.js';`), update to:

```ts
import { subSpan, type TracingContext } from '../shared/tracing.js';
```

- [ ] **Step 2: Wrap `prepareResult` body**

Replace the body of the `prepareResult` function (starting at line 37, the `async function prepareResult(...)` definition). Wrap the VM execution call so it becomes its own span. The new body:

```ts
async function prepareResult(
  renderingRequest: string,
  bundleFilePathPerTimestamp: string,
  executionContext: ExecutionContext,
): Promise<ResponseResult> {
  return subSpan({ name: 'ror.result.prepare' }, async () => {
    try {
      const result = await subSpan({ name: 'ror.vm.execute' }, () =>
        executionContext.runInVM(renderingRequest, bundleFilePathPerTimestamp, cluster),
      );

      let exceptionMessage = null;
      if (!result) {
        const error = new Error(
          'INVALID NIL or NULL result for rendering. Ensure renderingRequest is a valid string and returns a value.',
        );
        exceptionMessage = formatExceptionMessage(
          { renderingRequest },
          error,
          'INVALID result for prepareResult',
        );
      } else if (isErrorRenderResult(result)) {
        ({ exceptionMessage } = result);
      }

      if (exceptionMessage) {
        return errorResponseResult(exceptionMessage);
      }

      if (isReadableStream(result)) {
        return {
          headers: { 'Cache-Control': 'public, max-age=31536000' },
          status: 200,
          stream: result,
        };
      }

      return {
        headers: { 'Cache-Control': 'public, max-age=31536000' },
        status: 200,
        data: result,
      };
    } catch (err) {
      const exceptionMessage = formatExceptionMessage(
        { renderingRequest },
        err,
        'Unknown error calling runInVM',
      );
      return errorResponseResult(exceptionMessage);
    }
  });
}
```

- [ ] **Step 3: Wrap `buildExecutionContext` call sites with `cache.hit` attribute**

There are two call sites in `handleRenderRequest`:

1. Around line 238: `await buildExecutionContext(allBundleFilePaths, /* buildVmsIfNeeded */ false)` — cache hit attempt
2. Around line 272: `await buildExecutionContext(allBundleFilePaths, /* buildVmsIfNeeded */ true)` — cache miss path

Replace the first call site (in the inner `try` block of `handleRenderRequest`):

```ts
    try {
      const executionContext = await subSpan(
        {
          name: 'ror.bundle.build_execution_context',
          attributes: {
            'bundle.timestamp': String(bundleTimestamp),
            'bundle.paths.count': allBundleFilePaths.length,
            'cache.hit': true,
          },
        },
        () => buildExecutionContext(allBundleFilePaths, /* buildVmsIfNeeded */ false),
      );
      return {
        response: await prepareResult(renderingRequest, entryBundleFilePath, executionContext),
        executionContext,
      };
    } catch (e) {
```

Replace the second call site (after the `validateBundlesExist` check):

```ts
log.info('Bundle %s exists. Building ExecutionContext for worker %s.', entryBundleFilePath, workerIdLabel());
const executionContext = await subSpan(
  {
    name: 'ror.bundle.build_execution_context',
    attributes: {
      'bundle.timestamp': String(bundleTimestamp),
      'bundle.paths.count': allBundleFilePaths.length,
      'cache.hit': false,
    },
  },
  () => buildExecutionContext(allBundleFilePaths, /* buildVmsIfNeeded */ true),
);
return {
  response: await prepareResult(renderingRequest, entryBundleFilePath, executionContext),
  executionContext,
};
```

- [ ] **Step 4: Wrap `handleNewBundlesProvided` call site**

Around line 253 — the bundle-upload branch inside `handleRenderRequest`. Replace:

```ts
// If gem has posted updated bundle:
if (providedNewBundles && providedNewBundles.length > 0) {
  const result = await subSpan(
    {
      name: 'ror.bundle.upload',
      attributes: {
        'bundle.count': providedNewBundles.length,
        'assets.count': assetsToCopy?.length ?? 0,
      },
    },
    () => handleNewBundlesProvided({ renderingRequest }, providedNewBundles, assetsToCopy),
  );
  if (result) {
    return { response: result };
  }
}
```

- [ ] **Step 5: Wrap the exported `handleNewBundlesProvided` call from the `/upload-assets` route**

The exported `handleNewBundlesProvided` (around line 169) is also called from `src/worker.ts` for the `/upload-assets` endpoint. Wrap that call site too. In `packages/react-on-rails-pro-node-renderer/src/worker.ts`, around line 550 (`const result = await handleNewBundlesProvided(...)`), add the `subSpan` wrapper. First add the import at the top:

```ts
import { subSpan, startSsrRequestOptions, trace } from './shared/tracing.js';
```

Then change the call:

```ts
const result = await subSpan(
  {
    name: 'ror.bundle.upload',
    attributes: {
      'bundle.count': providedNewBundles.length,
      'assets.count': assetsToCopy.length,
    },
  },
  () =>
    handleNewBundlesProvided(
      { label: 'Request:', content: taskDescription },
      providedNewBundles,
      assetsToCopy,
    ),
);
```

- [ ] **Step 6: Run existing handleRenderRequest tests to verify no behavior change**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/handleRenderRequest.test.ts`
Expected: all existing tests PASS (the no-op `subSpan` default is a pure pass-through, so no behavior changes).

- [ ] **Step 7: Run type-check**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm type-check`
Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts \
        packages/react-on-rails-pro-node-renderer/src/worker.ts
git commit -m "feat(node-renderer): wrap render-path operations in subSpan calls (#2156)"
```

---

## Task 3: Wrap incremental-render operations with `subSpan`

Add the `ror.incremental.stream` and `ror.incremental.process_chunk` sub-spans.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderStream.ts`
- Modify: `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderRequest.ts`
- Test: `packages/react-on-rails-pro-node-renderer/tests/handleIncrementalRenderStream.test.ts` and `tests/incrementalRender.test.ts` (existing — must continue passing)

- [ ] **Step 1: Inspect the current handleIncrementalRenderStream signature**

Run: `cd packages/react-on-rails-pro-node-renderer && head -80 src/worker/handleIncrementalRenderStream.ts`
Note the exported function signature. Identify the outermost async entrypoint — this is what we wrap.

- [ ] **Step 2: Add `subSpan` import to handleIncrementalRenderStream.ts**

Add the import at the top of `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderStream.ts`:

```ts
import { subSpan } from '../shared/tracing.js';
```

- [ ] **Step 3: Wrap the stream lifecycle**

Find the exported `handleIncrementalRenderStream` function. Wrap its entire body in `subSpan({ name: 'ror.incremental.stream' }, async () => { /* existing body */ })`. The span will close when the streaming completes or errors, giving consumers a duration metric for the full incremental request.

Concretely, change:

```ts
export async function handleIncrementalRenderStream(
  options: HandleIncrementalRenderStreamOptions,
): Promise<void> {
  // … existing body …
}
```

to:

```ts
export async function handleIncrementalRenderStream(
  options: HandleIncrementalRenderStreamOptions,
): Promise<void> {
  return subSpan({ name: 'ror.incremental.stream' }, async () => {
    // … existing body unchanged …
  });
}
```

(Read the actual file contents before editing — preserve the exact existing body and any local helper closures.)

- [ ] **Step 4: Wrap `incrementalSink.add` in handleIncrementalRenderRequest.ts**

Open `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderRequest.ts`. Find the `add(chunk)` method of the returned `IncrementalRenderSink`. Wrap the implementation in `subSpan` with name `ror.incremental.process_chunk`.

Add the import:

```ts
import { subSpan } from '../shared/tracing.js';
```

Locate the `add: async (chunk) => { … }` (or `add(chunk) { … }`) function in the returned sink and wrap its body:

```ts
add: async (chunk) => {
  await subSpan(
    { name: 'ror.incremental.process_chunk' },
    async () => {
      // … existing body of add(chunk) here, unchanged …
    },
  );
},
```

(Read the actual file contents to see the exact shape of the existing `add` implementation, including whether it returns a value, takes other parameters, etc. Wrap correctly without changing semantics.)

- [ ] **Step 5: Run existing incremental tests to verify no behavior change**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/handleIncrementalRenderStream.test.ts tests/incrementalRender.test.ts tests/incrementalHtmlStreaming.test.ts`
Expected: all PASS.

- [ ] **Step 6: Run type-check**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm type-check`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderStream.ts \
        packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderRequest.ts
git commit -m "feat(node-renderer): wrap incremental render in subSpan calls (#2156)"
```

---

## Task 4: Add OpenTelemetry packages as optional peer dependencies

Add the OTel packages to `package.json` so they are recognized as optional peer deps (matching the existing Sentry/Honeybadger pattern). Also add them to `devDependencies` so tests can exercise the integration.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/package.json`
- Modify: `pnpm-lock.yaml` (regenerated by `pnpm install`)

- [ ] **Step 1: Edit `package.json`**

Open `packages/react-on-rails-pro-node-renderer/package.json`. In `peerDependencies`, add the OTel packages (matching the version ranges from issue #2156, with Express swapped for Fastify):

```jsonc
  "peerDependencies": {
    "@honeybadger-io/js": ">=4.0.0",
    "@sentry/node": ">=5.0.0 <11.0.0",
    "@sentry/tracing": ">=5.0.0",
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
```

In `peerDependenciesMeta`, mark every new entry as optional:

```jsonc
  "peerDependenciesMeta": {
    "@honeybadger-io/js": { "optional": true },
    "@sentry/node": { "optional": true },
    "@sentry/tracing": { "optional": true },
    "@opentelemetry/api": { "optional": true },
    "@opentelemetry/sdk-trace-node": { "optional": true },
    "@opentelemetry/sdk-trace-base": { "optional": true },
    "@opentelemetry/resources": { "optional": true },
    "@opentelemetry/semantic-conventions": { "optional": true },
    "@opentelemetry/exporter-trace-otlp-http": { "optional": true },
    "@opentelemetry/instrumentation": { "optional": true },
    "@opentelemetry/instrumentation-http": { "optional": true },
    "@opentelemetry/instrumentation-fastify": { "optional": true }
  },
```

In `devDependencies`, add the same packages (so tests can `import` them; use the latest matching version satisfying the peer-dep range):

```jsonc
    "@opentelemetry/api": "^1.9.0",
    "@opentelemetry/sdk-trace-node": "^2.0.1",
    "@opentelemetry/sdk-trace-base": "^2.0.1",
    "@opentelemetry/resources": "^2.0.1",
    "@opentelemetry/semantic-conventions": "^1.36.0",
    "@opentelemetry/exporter-trace-otlp-http": "^0.203.0",
    "@opentelemetry/instrumentation": "^0.203.0",
    "@opentelemetry/instrumentation-http": "^0.203.0",
    "@opentelemetry/instrumentation-fastify": "^0.52.0",
```

Insert them alphabetically (after existing `@honeybadger-io/js` and `@sentry/node` entries).

- [ ] **Step 2: Install dependencies**

Run from the repo root:

```bash
pnpm install
```

Expected: pnpm installs the new packages, updates `pnpm-lock.yaml`, no errors.

- [ ] **Step 3: Run type-check to confirm nothing broke**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm type-check`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/package.json pnpm-lock.yaml
git commit -m "chore(node-renderer): add OpenTelemetry as optional peer deps (#2156)"
```

---

## Task 5: Create OpenTelemetry integration skeleton

Create `src/integrations/opentelemetry.ts` with the `init()` function. This task implements only the resource setup + tracer provider — no auto-instrumentation, no `setupTracing` wiring yet (those come in Tasks 6 and 7).

**Files:**

- Create: `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`
- Create: `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`

- [ ] **Step 1: Write the failing test**

Create `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`:

```ts
import { trace as otelTrace, type Tracer } from '@opentelemetry/api';
import { InMemorySpanExporter, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { init } from '../../src/integrations/opentelemetry';

describe('opentelemetry integration: init()', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(() => {
    exporter = new InMemorySpanExporter();
  });

  test('init() registers a tracer provider with the configured service name', () => {
    init({
      serviceName: 'test-renderer',
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const tracer: Tracer = otelTrace.getTracer('test');
    tracer.startActiveSpan('manual.span', (span) => {
      span.end();
    });

    const spans = exporter.getFinishedSpans();
    expect(spans).toHaveLength(1);
    expect(spans[0]!.name).toBe('manual.span');
    expect(spans[0]!.resource.attributes['service.name']).toBe('test-renderer');
  });

  test('init() defaults serviceName to "react-on-rails-pro-node-renderer"', () => {
    init({
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const tracer = otelTrace.getTracer('test');
    tracer.startActiveSpan('manual.span', (span) => {
      span.end();
    });

    expect(exporter.getFinishedSpans()[0]!.resource.attributes['service.name']).toBe(
      'react-on-rails-pro-node-renderer',
    );
  });

  test('init() merges resourceAttributes with defaults', () => {
    init({
      serviceName: 'test-renderer',
      resourceAttributes: { 'deployment.environment': 'staging' },
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const tracer = otelTrace.getTracer('test');
    tracer.startActiveSpan('manual.span', (span) => {
      span.end();
    });

    const attrs = exporter.getFinishedSpans()[0]!.resource.attributes;
    expect(attrs['service.name']).toBe('test-renderer');
    expect(attrs['deployment.environment']).toBe('staging');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts`
Expected: FAIL with "Cannot find module '../../src/integrations/opentelemetry'".

- [ ] **Step 3: Implement `init()` skeleton**

Create `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`:

```ts
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import {
  BatchSpanProcessor,
  SimpleSpanProcessor,
  type SpanExporter,
  type SpanProcessor,
} from '@opentelemetry/sdk-trace-base';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';
import { log, message } from './api.js';

export interface OpenTelemetryInitOptions {
  /** Service name reported in traces. Defaults to "react-on-rails-pro-node-renderer".
   *  `OTEL_SERVICE_NAME` env var takes precedence over this value. */
  serviceName?: string;
  /** Register HTTP + Fastify auto-instrumentation. Default: false. */
  fastify?: boolean;
  /** Wrap SSR work in spans via setupTracing + setupSubSpan. Default: false. */
  tracing?: boolean;
  /** Override the default OTLP HTTP exporter. */
  exporter?: SpanExporter;
  /** Override the default span processor.
   *  Default: BatchSpanProcessor in production, SimpleSpanProcessor otherwise. */
  spanProcessor?: SpanProcessor;
  /** Additional resource attributes merged into the default resource. */
  resourceAttributes?: Record<string, string>;
}

const DEFAULT_SERVICE_NAME = 'react-on-rails-pro-node-renderer';

let tracerProvider: NodeTracerProvider | null = null;

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production' || process.env.RAILS_ENV === 'production';
}

function buildSpanProcessor(opts: OpenTelemetryInitOptions): SpanProcessor {
  if (opts.spanProcessor) return opts.spanProcessor;
  const exporter = opts.exporter ?? new OTLPTraceExporter();
  return isProduction() ? new BatchSpanProcessor(exporter) : new SimpleSpanProcessor(exporter);
}

export function init(opts: OpenTelemetryInitOptions = {}): void {
  try {
    const resource = resourceFromAttributes({
      [ATTR_SERVICE_NAME]: opts.serviceName ?? DEFAULT_SERVICE_NAME,
      ...(opts.resourceAttributes ?? {}),
    });

    tracerProvider = new NodeTracerProvider({
      resource,
      spanProcessors: [buildSpanProcessor(opts)],
    });

    tracerProvider.register();
    log.info('[OpenTelemetry] Tracer provider initialized');
  } catch (err) {
    message(`[OpenTelemetry] init failed: ${String(err)}`);
  }
}

/** Test-only: shut down the tracer provider and reset module state. */
export async function __resetForTest(): Promise<void> {
  if (tracerProvider) {
    await tracerProvider.shutdown();
    tracerProvider = null;
  }
}
```

- [ ] **Step 4: Add `__resetForTest` calls to the test file**

Update the test file's `beforeEach` to also reset the integration:

```ts
import { init, __resetForTest } from '../../src/integrations/opentelemetry';

beforeEach(async () => {
  exporter = new InMemorySpanExporter();
  await __resetForTest();
});

afterAll(async () => {
  await __resetForTest();
});
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts`
Expected: PASS, 3 tests passing.

- [ ] **Step 6: Run type-check**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm type-check`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts \
        packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts
git commit -m "feat(node-renderer): add OpenTelemetry init skeleton (#2156)"
```

---

## Task 6: Add fastify + http auto-instrumentation to `init()`

Extend `init()` to accept `fastify: true` and register HTTP + Fastify instrumentation.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`
- Modify: `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`

- [ ] **Step 1: Add failing test for fastify auto-instrumentation**

Append to `tests/integrations/opentelemetry.test.ts`:

```ts
import fastify from 'fastify';
import { init, __resetForTest } from '../../src/integrations/opentelemetry';

describe('opentelemetry integration: fastify auto-instrumentation', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    await __resetForTest();
  });

  afterAll(async () => {
    await __resetForTest();
  });

  test('init({ fastify: true }) produces an HTTP span on incoming requests', async () => {
    init({
      fastify: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const app = fastify({ http2: false });
    app.get('/ping', async () => ({ pong: true }));
    await app.ready();

    const res = await app.inject({ method: 'GET', url: '/ping' });
    expect(res.statusCode).toBe(200);
    await app.close();

    const spans = exporter.getFinishedSpans();
    // Expect at least one HTTP server span; Fastify instrumentation may add more.
    const httpSpans = spans.filter((s) => s.name.startsWith('GET') || s.name.includes('HTTP'));
    expect(httpSpans.length).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts -t "fastify auto-instrumentation"`
Expected: FAIL — no HTTP spans because instrumentation is not registered.

- [ ] **Step 3: Implement fastify instrumentation in `init()`**

Edit `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`. Add imports at the top:

```ts
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import { FastifyInstrumentation } from '@opentelemetry/instrumentation-fastify';
```

In the `init()` function, after `tracerProvider.register();`, add:

```ts
if (opts.fastify) {
  registerInstrumentations({
    instrumentations: [
      // HTTP first — Fastify instrumentation depends on it.
      new HttpInstrumentation(),
      new FastifyInstrumentation(),
    ],
    tracerProvider,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts -t "fastify auto-instrumentation"`
Expected: PASS.

- [ ] **Step 5: Run full integration test file**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts`
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts \
        packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts
git commit -m "feat(node-renderer): register HTTP + Fastify OTel instrumentation (#2156)"
```

---

## Task 7: Wire `setupTracing` + `setupSubSpan` for SSR root span and sub-spans

Extend `init()` to accept `tracing: true` and produce the `ror.ssr.request` root span via `setupTracing`, plus `ror.*` sub-spans via `setupSubSpan`.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`
- Modify: `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`

- [ ] **Step 1: Add failing test for SSR span tree**

Append to `tests/integrations/opentelemetry.test.ts`:

```ts
import { trace, subSpan, __resetSubSpanForTest } from '../../src/shared/tracing';
import { startSsrRequestOptions } from '../../src/shared/tracing';

describe('opentelemetry integration: tracing wiring', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    __resetSubSpanForTest();
    await __resetForTest();
  });

  afterAll(async () => {
    __resetSubSpanForTest();
    await __resetForTest();
  });

  test('init({ tracing: true }) produces a ror.ssr.request span via trace()', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    await trace(async () => 'result', startSsrRequestOptions({ renderingRequest: 'irrelevant' }));

    const spans = exporter.getFinishedSpans();
    const ssrSpan = spans.find((s) => s.name === 'ror.ssr.request');
    expect(ssrSpan).toBeDefined();
  });

  test('init({ tracing: true }) registers a sub-span impl so subSpan() produces spans', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    await trace(
      async () => {
        await subSpan(
          { name: 'ror.bundle.build_execution_context', attributes: { 'bundle.timestamp': 'abc' } },
          async () => undefined,
        );
      },
      startSsrRequestOptions({ renderingRequest: 'irrelevant' }),
    );

    const spans = exporter.getFinishedSpans();
    const ssrSpan = spans.find((s) => s.name === 'ror.ssr.request');
    const bundleSpan = spans.find((s) => s.name === 'ror.bundle.build_execution_context');
    expect(ssrSpan).toBeDefined();
    expect(bundleSpan).toBeDefined();
    expect(bundleSpan!.attributes['bundle.timestamp']).toBe('abc');
    // Parent-child relationship: bundleSpan's parent is ssrSpan
    expect(bundleSpan!.parentSpanContext?.spanId).toBe(ssrSpan!.spanContext().spanId);
  });

  test('subSpan does not include renderingRequest payload in attributes (sensitive data audit)', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const secretPayload = 'SECRET-CONTENT-DO-NOT-LEAK';
    await trace(
      async () => {
        await subSpan({ name: 'ror.vm.execute' }, async () => undefined);
      },
      startSsrRequestOptions({ renderingRequest: secretPayload }),
    );

    const spans = exporter.getFinishedSpans();
    for (const span of spans) {
      for (const value of Object.values(span.attributes)) {
        expect(String(value)).not.toContain(secretPayload);
      }
    }
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts -t "tracing wiring"`
Expected: FAIL — no `ror.ssr.request` span because `setupTracing` is not wired.

- [ ] **Step 3: Wire `setupTracing` and `setupSubSpan` in `init()`**

Edit `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`. Add imports at the top:

```ts
import { trace as otelTrace, SpanStatusCode, type Attributes } from '@opentelemetry/api';
import { setupTracing, setupSubSpan, type SubSpanFn } from '../shared/tracing.js';
```

Augment `UnitOfWorkOptions` (declaration merging) just below the imports:

```ts
declare module '../shared/tracing.js' {
  interface UnitOfWorkOptions {
    opentelemetry?: { name: string; attributes?: Attributes };
  }
}
```

In `init()`, after the fastify block, add:

```ts
if (opts.tracing) {
  const tracer = otelTrace.getTracer(opts.serviceName ?? DEFAULT_SERVICE_NAME);

  setupTracing({
    startSsrRequestOptions: () => ({
      opentelemetry: { name: 'ror.ssr.request' },
    }),
    executor: async (fn, unitOfWorkOptions) => {
      const otelOpts = unitOfWorkOptions.opentelemetry ?? { name: 'ror.ssr.request' };
      return tracer.startActiveSpan(otelOpts.name, { attributes: otelOpts.attributes }, async (span) => {
        try {
          return await fn();
        } catch (err) {
          span.setStatus({
            code: SpanStatusCode.ERROR,
            message: err instanceof Error ? err.message : String(err),
          });
          throw err;
        } finally {
          span.end();
        }
      });
    },
  });

  const subSpanImpl: SubSpanFn = (subOpts, fn) =>
    tracer.startActiveSpan(subOpts.name, { attributes: subOpts.attributes }, async (span) => {
      try {
        return await fn();
      } catch (err) {
        span.setStatus({
          code: SpanStatusCode.ERROR,
          message: err instanceof Error ? err.message : String(err),
        });
        throw err;
      } finally {
        span.end();
      }
    });
  setupSubSpan(subSpanImpl);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts -t "tracing wiring"`
Expected: PASS.

- [ ] **Step 5: Run the full opentelemetry test file**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts`
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts \
        packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts
git commit -m "feat(node-renderer): wire OTel into setupTracing + setupSubSpan for SSR spans (#2156)"
```

---

## Task 8: Add graceful shutdown flush via Fastify `onClose` hook

Ensure batched spans are flushed to the exporter before the worker terminates.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`
- Modify: `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`

- [ ] **Step 1: Add failing test for shutdown flush**

Append to `tests/integrations/opentelemetry.test.ts`:

```ts
import { configureFastify } from '../../src/integrations/api';

describe('opentelemetry integration: graceful shutdown', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    await __resetForTest();
  });

  afterAll(async () => {
    await __resetForTest();
  });

  test('Fastify onClose calls tracerProvider.shutdown which flushes pending spans', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const app = fastify({ http2: false });
    // The integration must have registered an onClose hook via configureFastify.
    // Replay configureFastify outputs on this fresh app:
    // (the integration's own hook is invoked when registered fastify apps close —
    // here we wire it manually using configureFastify which the integration uses.)
    await app.ready();

    const tracer = otelTrace.getTracer('test');
    tracer.startActiveSpan('manual.span', (span) => span.end());

    await app.close();

    // After close, spans should have been exported.
    expect(exporter.getFinishedSpans().some((s) => s.name === 'manual.span')).toBe(true);
  });
});
```

Note: this test checks the behavior contract. The implementation is the `onClose` hook registered via `configureFastify` from `init()`.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts -t "graceful shutdown"`
Expected: this may PASS coincidentally with `SimpleSpanProcessor` (it exports synchronously). Switch the test to use `BatchSpanProcessor` to make the shutdown contract observable:

Replace the test's `spanProcessor` with `new BatchSpanProcessor(exporter, { scheduledDelayMillis: 30000 })`. Without explicit shutdown, the test would fail because the batch processor only flushes on its schedule. With proper shutdown wiring, `app.close()` triggers `tracerProvider.shutdown()` which forces a flush.

- [ ] **Step 3: Implement `onClose` shutdown via `configureFastify`**

Edit `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`. Add import at top:

```ts
import { configureFastify } from '../worker.js';
```

In `init()`, after the fastify block (and after the tracing block), add:

```ts
// Flush pending spans on graceful shutdown. Fastify fires onClose during
// worker.destroy() / app.close(), giving the batch processor a chance to
// export queued spans before the process exits.
configureFastify((app) => {
  app.addHook('onClose', async () => {
    if (tracerProvider) {
      await tracerProvider.shutdown();
    }
  });
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts -t "graceful shutdown"`
Expected: PASS.

- [ ] **Step 5: Run the full opentelemetry test file**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts`
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts \
        packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts
git commit -m "feat(node-renderer): flush OTel spans on Fastify onClose (#2156)"
```

---

## Task 9: Test init failure path (missing peer deps)

Verify that if a required `@opentelemetry/*` package fails to load at runtime, `init()` logs an error and returns gracefully without crashing the renderer.

**Files:**

- Create: `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry-init.test.ts`

- [ ] **Step 1: Write the failing test**

Create `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry-init.test.ts`:

```ts
import { jest } from '@jest/globals';

describe('opentelemetry integration: init() failure path', () => {
  beforeEach(() => {
    jest.resetModules();
  });

  test('init() catches missing-peer-dep import error and returns without throwing', async () => {
    // Mock the SDK import to throw, simulating a missing peer dep.
    jest.doMock('@opentelemetry/sdk-trace-node', () => {
      throw new Error('Cannot find module @opentelemetry/sdk-trace-node');
    });

    const errorReporter = await import('../../src/shared/errorReporter');
    const messageSpy = jest.spyOn(errorReporter, 'message');

    // Importing the integration itself must not throw even though the SDK is missing.
    // The integration must defer the require/import to inside init().
    const otel = await import('../../src/integrations/opentelemetry');
    expect(() => otel.init()).not.toThrow();
    expect(messageSpy).toHaveBeenCalledWith(expect.stringContaining('[OpenTelemetry] init failed'));
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry-init.test.ts`
Expected: FAIL — the top-level static `import` of `@opentelemetry/sdk-trace-node` throws at module-load time, before `init()` can catch it.

- [ ] **Step 3: Refactor imports to be lazy inside `init()`**

Edit `packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts`. Remove the top-level static imports of the OTel SDK packages and re-import them lazily inside the `try` block in `init()`:

```ts
import { log, message, configureFastify, setupTracing, setupSubSpan, type SubSpanFn } from './api.js';

// Type-only imports — these don't trigger runtime require()
import type { NodeTracerProvider as NodeTracerProviderType } from '@opentelemetry/sdk-trace-node';
import type { SpanExporter, SpanProcessor } from '@opentelemetry/sdk-trace-base';
import type { Attributes } from '@opentelemetry/api';

// (UnitOfWorkOptions augmentation stays the same — it's type-only.)
declare module '../shared/tracing.js' {
  interface UnitOfWorkOptions {
    opentelemetry?: { name: string; attributes?: Attributes };
  }
}

export interface OpenTelemetryInitOptions {
  serviceName?: string;
  fastify?: boolean;
  tracing?: boolean;
  exporter?: SpanExporter;
  spanProcessor?: SpanProcessor;
  resourceAttributes?: Record<string, string>;
}

const DEFAULT_SERVICE_NAME = 'react-on-rails-pro-node-renderer';
let tracerProvider: NodeTracerProviderType | null = null;

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production' || process.env.RAILS_ENV === 'production';
}

export function init(opts: OpenTelemetryInitOptions = {}): void {
  try {
    /* eslint-disable @typescript-eslint/no-require-imports, global-require --
     * Lazy require so that init() can gracefully no-op when peer deps are missing. */
    const { NodeTracerProvider } =
      require('@opentelemetry/sdk-trace-node') as typeof import('@opentelemetry/sdk-trace-node');
    const { BatchSpanProcessor, SimpleSpanProcessor } =
      require('@opentelemetry/sdk-trace-base') as typeof import('@opentelemetry/sdk-trace-base');
    const { OTLPTraceExporter } =
      require('@opentelemetry/exporter-trace-otlp-http') as typeof import('@opentelemetry/exporter-trace-otlp-http');
    const { resourceFromAttributes } =
      require('@opentelemetry/resources') as typeof import('@opentelemetry/resources');
    const { ATTR_SERVICE_NAME } =
      require('@opentelemetry/semantic-conventions') as typeof import('@opentelemetry/semantic-conventions');
    const otelApi = require('@opentelemetry/api') as typeof import('@opentelemetry/api');
    /* eslint-enable @typescript-eslint/no-require-imports, global-require */

    const resource = resourceFromAttributes({
      [ATTR_SERVICE_NAME]: opts.serviceName ?? DEFAULT_SERVICE_NAME,
      ...(opts.resourceAttributes ?? {}),
    });

    const spanProcessor =
      opts.spanProcessor ??
      (isProduction()
        ? new BatchSpanProcessor(opts.exporter ?? new OTLPTraceExporter())
        : new SimpleSpanProcessor(opts.exporter ?? new OTLPTraceExporter()));

    tracerProvider = new NodeTracerProvider({
      resource,
      spanProcessors: [spanProcessor],
    });
    tracerProvider.register();
    log.info('[OpenTelemetry] Tracer provider initialized');

    if (opts.fastify) {
      /* eslint-disable @typescript-eslint/no-require-imports, global-require */
      const { registerInstrumentations } =
        require('@opentelemetry/instrumentation') as typeof import('@opentelemetry/instrumentation');
      const { HttpInstrumentation } =
        require('@opentelemetry/instrumentation-http') as typeof import('@opentelemetry/instrumentation-http');
      const { FastifyInstrumentation } =
        require('@opentelemetry/instrumentation-fastify') as typeof import('@opentelemetry/instrumentation-fastify');
      /* eslint-enable @typescript-eslint/no-require-imports, global-require */
      registerInstrumentations({
        instrumentations: [new HttpInstrumentation(), new FastifyInstrumentation()],
        tracerProvider,
      });
    }

    if (opts.tracing) {
      const tracer = otelApi.trace.getTracer(opts.serviceName ?? DEFAULT_SERVICE_NAME);

      setupTracing({
        startSsrRequestOptions: () => ({ opentelemetry: { name: 'ror.ssr.request' } }),
        executor: async (fn, unitOfWorkOptions) => {
          const otelOpts = unitOfWorkOptions.opentelemetry ?? { name: 'ror.ssr.request' };
          return tracer.startActiveSpan(otelOpts.name, { attributes: otelOpts.attributes }, async (span) => {
            try {
              return await fn();
            } catch (err) {
              span.setStatus({
                code: otelApi.SpanStatusCode.ERROR,
                message: err instanceof Error ? err.message : String(err),
              });
              throw err;
            } finally {
              span.end();
            }
          });
        },
      });

      const subSpanImpl: SubSpanFn = (subOpts, fn) =>
        tracer.startActiveSpan(subOpts.name, { attributes: subOpts.attributes }, async (span) => {
          try {
            return await fn();
          } catch (err) {
            span.setStatus({
              code: otelApi.SpanStatusCode.ERROR,
              message: err instanceof Error ? err.message : String(err),
            });
            throw err;
          } finally {
            span.end();
          }
        });
      setupSubSpan(subSpanImpl);
    }

    configureFastify((app) => {
      app.addHook('onClose', async () => {
        if (tracerProvider) {
          await tracerProvider.shutdown();
        }
      });
    });
  } catch (err) {
    message(`[OpenTelemetry] init failed: ${String(err)}`);
  }
}

export async function __resetForTest(): Promise<void> {
  if (tracerProvider) {
    await tracerProvider.shutdown();
    tracerProvider = null;
  }
}
```

- [ ] **Step 4: Run failure-path test to verify it passes**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry-init.test.ts`
Expected: PASS.

- [ ] **Step 5: Run all opentelemetry-related tests**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/`
Expected: all PASS.

- [ ] **Step 6: Run type-check**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm type-check`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/src/integrations/opentelemetry.ts \
        packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry-init.test.ts
git commit -m "feat(node-renderer): defer OTel imports until init() so missing peer deps don't crash module load (#2156)"
```

---

## Task 10: End-to-end test — render request produces expected span tree

Wire an actual worker instance with OTel enabled, fire a render request, and assert the resulting span tree includes the SSR root span and all expected sub-spans.

**Files:**

- Modify: `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`

- [ ] **Step 1: Inspect how `worker.test.ts` boots the worker**

Run: `cd packages/react-on-rails-pro-node-renderer && head -100 tests/worker.test.ts`
Note the pattern for invoking `worker.default(config)` and `app.inject(...)`. Pay attention to how `disableHttp2()` is called and any helper imports from `./helper`.

- [ ] **Step 2: Add end-to-end test**

Append to `packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts`:

```ts
import { disableHttp2 } from '../../src/worker';
import workerRun from '../../src/worker';
import {
  createUploadedBundle,
  uploadedBundlePath,
  BUNDLE_TIMESTAMP,
  resetForTest,
  vmBundlePath,
  mkdirAsync,
} from '../helper';
import path from 'path';
import FormData from 'form-data';

describe('opentelemetry integration: end-to-end render request', () => {
  const testName = 'otelEndToEnd';
  let exporter: InMemorySpanExporter;

  beforeAll(() => {
    disableHttp2();
  });

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    __resetSubSpanForTest();
    await __resetForTest();
    await resetForTest(testName);
    await mkdirAsync(path.dirname(vmBundlePath(testName)), { recursive: true });
  });

  afterAll(async () => {
    __resetSubSpanForTest();
    await __resetForTest();
    await resetForTest(testName);
  });

  test('SSR render produces ror.ssr.request and ror.bundle.* + ror.vm.execute spans', async () => {
    init({
      fastify: true,
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const app = workerRun({});
    await app.ready();

    await createUploadedBundle(testName);

    // Build multipart body with the bundle
    const form = new FormData();
    form.append('renderingRequest', 'ReactOnRails.dummy');
    form.append('bundle', '<bundle bytes>', { filename: 'bundle.js' });

    const res = await app.inject({
      method: 'POST',
      url: `/bundles/${BUNDLE_TIMESTAMP}/render/digest`,
      headers: form.getHeaders(),
      payload: form.getBuffer(),
    });

    expect(res.statusCode).toBe(200);
    await app.close();

    const spanNames = exporter.getFinishedSpans().map((s) => s.name);
    expect(spanNames).toEqual(
      expect.arrayContaining([
        'ror.ssr.request',
        'ror.bundle.build_execution_context',
        'ror.vm.execute',
        'ror.result.prepare',
      ]),
    );
  });
});
```

Note: this test mirrors the existing patterns in `tests/handleRenderRequest.test.ts` and `tests/worker.test.ts`. Adjust imports based on what actually exists in `tests/helper.ts` — read it first if any symbol is missing.

- [ ] **Step 3: Run the end-to-end test**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/opentelemetry.test.ts -t "end-to-end render request"`
Expected: PASS, with all four spans present.

- [ ] **Step 4: Run the full opentelemetry test suite**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test tests/integrations/`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/react-on-rails-pro-node-renderer/tests/integrations/opentelemetry.test.ts
git commit -m "test(node-renderer): end-to-end OTel span tree assertion (#2156)"
```

---

## Task 11: Add CHANGELOG entry and documentation

**Files:**

- Modify: `CHANGELOG.md`
- Modify: `docs/pro/node-renderer.md`

- [ ] **Step 1: Add CHANGELOG entry under `[Unreleased]` → `### Added`**

Edit `CHANGELOG.md`. Under `### [Unreleased]`, add a new `#### Added` block (or append to it if it already exists):

```markdown
### [Unreleased]

#### Added

- **[Pro]** **OpenTelemetry integration for the Node Renderer**: New optional integration at `react-on-rails-pro-node-renderer/integrations/opentelemetry` that adds distributed tracing via standard OpenTelemetry. Users enable it by installing the `@opentelemetry/*` packages (optional peer deps) and calling `init({ fastify: true, tracing: true })` from their renderer entrypoint, before `reactOnRailsProNodeRenderer()`. Provides auto-instrumented HTTP and Fastify spans, an SSR root span (`ror.ssr.request`), and render-path sub-spans (`ror.bundle.build_execution_context`, `ror.bundle.upload`, `ror.vm.execute`, `ror.result.prepare`, `ror.incremental.stream`, `ror.incremental.process_chunk`). Configuration follows standard OpenTelemetry env-var conventions (`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES`, etc.); defaults to `BatchSpanProcessor` in production and `SimpleSpanProcessor` otherwise. The integration is fully optional — users who do not enable it pay zero runtime cost, and the renderer has no direct dependency on OpenTelemetry. Closes [#2156](https://github.com/shakacode/react_on_rails/issues/2156).
```

- [ ] **Step 2: Add Observability section to `docs/pro/node-renderer.md`**

Read `docs/pro/node-renderer.md` and find an appropriate insertion point (typically after the configuration section, before troubleshooting). Insert:

````markdown
## Observability with OpenTelemetry

The Node Renderer ships an optional OpenTelemetry integration for distributed tracing.

### Install the OpenTelemetry packages (peer dependencies)

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
````

### Enable from your renderer entrypoint

OpenTelemetry must be initialized **before** any HTTP or Fastify code is loaded so that the auto-instrumentation can patch the modules at require-time. Call `init()` first in your entrypoint:

```js
import { init as initOpenTelemetry } from 'react-on-rails-pro-node-renderer/integrations/opentelemetry';

initOpenTelemetry({
  serviceName: 'my-app-node-renderer', // optional; defaults to "react-on-rails-pro-node-renderer"
  fastify: true, // register HTTP + Fastify auto-instrumentation
  tracing: true, // wrap SSR rendering in spans
});

// Now start the renderer:
import { reactOnRailsProNodeRenderer } from 'react-on-rails-pro-node-renderer';
reactOnRailsProNodeRenderer().catch((e) => {
  throw e;
});
```

### Configuration via standard OpenTelemetry environment variables

| Env var                                          | Purpose                                                    | Default                            |
| ------------------------------------------------ | ---------------------------------------------------------- | ---------------------------------- |
| `OTEL_EXPORTER_OTLP_ENDPOINT`                    | OTLP collector endpoint                                    | `http://localhost:4318`            |
| `OTEL_EXPORTER_OTLP_HEADERS`                     | Auth headers (e.g. `api-key=xxx`)                          | none                               |
| `OTEL_SERVICE_NAME`                              | Service name in traces (overrides `init({ serviceName })`) | `react-on-rails-pro-node-renderer` |
| `OTEL_RESOURCE_ATTRIBUTES`                       | Additional resource attributes (csv)                       | none                               |
| `OTEL_TRACES_SAMPLER`, `OTEL_TRACES_SAMPLER_ARG` | Trace sampling                                             | parent-based, always-on            |

### Span taxonomy

| Span                                 | Where                                                             | Attributes                                            |
| ------------------------------------ | ----------------------------------------------------------------- | ----------------------------------------------------- |
| `ror.ssr.request`                    | Root span for each SSR render request                             | n/a                                                   |
| `ror.bundle.build_execution_context` | Loading a bundle into the VM                                      | `bundle.timestamp`, `bundle.paths.count`, `cache.hit` |
| `ror.bundle.upload`                  | When new bundles are uploaded mid-request or via `/upload-assets` | `bundle.count`, `assets.count`                        |
| `ror.vm.execute`                     | The actual SSR JS execution                                       | (none)                                                |
| `ror.result.prepare`                 | Building the response payload                                     | (none)                                                |
| `ror.incremental.stream`             | Wraps the incremental NDJSON request lifecycle                    | (none)                                                |
| `ror.incremental.process_chunk`      | Processing each NDJSON update chunk                               | (none)                                                |

Outbound HTTP calls inside your bundle are automatically captured by `HttpInstrumentation`.

### Production defaults

- **Span processor**: `BatchSpanProcessor` in production (`NODE_ENV=production` or `RAILS_ENV=production`), `SimpleSpanProcessor` otherwise. Override with `init({ spanProcessor })`.
- **Exporter**: OTLP HTTP. Override with `init({ exporter })`.
- **Graceful shutdown**: Pending batched spans are flushed when Fastify's `onClose` hook fires (during worker shutdown).

### Privacy note

The `renderingRequest` payload is **never** included in span attributes. Only bundle hashes, counts, and sizes are recorded. This matches the existing logging policy.

````

- [ ] **Step 3: Verify the doc renders correctly**

Run: `cd packages/react-on-rails-pro-node-renderer && head -20 ../../docs/pro/node-renderer.md`
Expected: file is intact, no broken markdown above the new section.

- [ ] **Step 4: Run repo-wide markdown link check**

Run from repo root: `pnpm prettier --check docs/pro/node-renderer.md CHANGELOG.md`
Expected: PASS (prettier may auto-format; if it does, save the formatted version).

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md docs/pro/node-renderer.md
git commit -m "docs(node-renderer): document OpenTelemetry integration (#2156)"
````

---

## Task 12: Final QA — full test suite, type-check, lint, push, PR

**Files:**

- (none — runs the existing tooling)

- [ ] **Step 1: Run the full Node Renderer test suite**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm test`
Expected: all tests PASS. If any unrelated tests fail, investigate before continuing.

- [ ] **Step 2: Run type-check**

Run: `cd packages/react-on-rails-pro-node-renderer && pnpm type-check`
Expected: no errors.

- [ ] **Step 3: Run the repo-wide lint check**

Run from repo root: `pnpm eslint packages/react-on-rails-pro-node-renderer/src packages/react-on-rails-pro-node-renderer/tests`
Expected: no errors.

- [ ] **Step 4: Run the repo-wide RuboCop check (defensive — should be a no-op)**

Run from repo root: `bundle exec rubocop --no-fail-level info`
Expected: no errors. (No Ruby was changed, but the project's CLAUDE.md requires this before pushing.)

- [ ] **Step 5: Push the branch**

```bash
git pull --rebase origin main
git push -u origin jg-conductor/lisbon-v2
```

Expected: clean push, no conflicts.

- [ ] **Step 6: Open the PR**

```bash
gh pr create --base main --title "feat(node-renderer): add OpenTelemetry integration" --body "$(cat <<'EOF'
## Summary

- Adds optional OpenTelemetry integration to the React on Rails Pro Node Renderer
- New `src/integrations/opentelemetry.ts` matching the Sentry/Honeybadger pattern (peer dep + explicit `init()`)
- Wires into existing `setupTracing` + new `setupSubSpan` so render-path code stays free of direct OTel imports
- Emits `ror.ssr.request`, `ror.bundle.build_execution_context`, `ror.bundle.upload`, `ror.vm.execute`, `ror.result.prepare`, `ror.incremental.stream`, `ror.incremental.process_chunk` spans
- Auto-instruments HTTP + Fastify (not Express — the renderer uses Fastify)
- Configuration via standard OTel env vars; `BatchSpanProcessor` default in production
- Graceful shutdown flush via Fastify `onClose` hook
- No runtime cost for users who don't enable it

Closes #2156

Spec: `docs/superpowers/specs/2026-05-21-otel-node-renderer-design.md`
Plan: `docs/superpowers/plans/2026-05-21-otel-node-renderer.md`

## Test plan

- [x] Unit tests for `subSpan` / `setupSubSpan` helper
- [x] Unit tests for `init()` paths (skeleton, fastify, tracing, shutdown)
- [x] Init failure-path test (missing peer deps no-ops cleanly)
- [x] End-to-end test: SSR render produces expected span tree via `InMemorySpanExporter`
- [x] Sensitive-data audit: `renderingRequest` payload never appears in span attributes
- [x] Existing `handleRenderRequest` / incremental render tests still pass
- [x] Type-check + lint pass

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 7: Watch CI**

```bash
gh pr view --json statusCheckRollup --jq '.statusCheckRollup'
```

If any check fails, read the full failure output and fix at the root cause (per project CLAUDE.md — never make empty commits to retrigger CI).

---

## Self-Review

**Spec coverage:**

- §"User-facing API → Installing" → Task 4 (package.json peer deps)
- §"User-facing API → Enabling" → Task 5–8 (init, fastify, tracing, shutdown), Task 11 (docs)
- §"User-facing API → Configuring" → Task 5 (env vars handled by OTLPTraceExporter and tracer.getTracer reading OTEL_SERVICE_NAME; defaults set in code), Task 11 (env var docs)
- §"Span processor default" → Task 5 (production vs. non-production logic), Task 11 (docs)
- §"Components 1 (opentelemetry.ts)" → Tasks 5–9
- §"Components 2 (no functional change)" → Task 1
- §"Components 3 (sub-span helpers)" → Task 1
- §"Components 4 (handleRenderRequest.ts)" → Task 2
- §"Components 5 (incremental)" → Task 3
- §"Components 6 (worker.ts SSR root span)" → already done by existing `trace(...)` call; Task 7 supplies the executor
- §"Components 7 (graceful shutdown)" → Task 8 (Fastify `onClose` hook, not the `addShutdownTask` API suggested in the spec — onClose is simpler and uses existing `configureFastify` plumbing)
- §"Components 8 (package.json)" → Task 4
- §"Data flow" → covered end-to-end by Task 10 test
- §"Error handling 1 (init failure)" → Task 9
- §"Error handling 2 (exporter failure)" → handled by OTel SDK internals; no test needed
- §"Error handling 3 (attribute serialization)" → handled by `subSpan`'s try/catch around the impl call (Task 1)
- §"Error handling 4 (shutdown timeout)" → relies on existing worker kill timer + OTel SDK timeout; no test needed
- §"Error handling 5 (sensitive data)" → covered by sensitive-data audit test in Task 7
- §"Testing → Unit tests" → Tasks 1, 5, 6, 7, 8, 9
- §"Testing → Integration test" → Task 10
- §"Migration / rollout" → Task 11 (CHANGELOG + docs)

**Placeholder scan:** No "TBD", "TODO", "implement later", or "add appropriate X". Every step shows full code.

**Type consistency:**

- `SubSpanOptions.name` is `string`, `attributes` is `Record<string, string | number | boolean>` — used consistently in Tasks 1, 2, 3, 5, 7.
- `SubSpanFn = <T>(opts: SubSpanOptions, fn: () => Promise<T>) => Promise<T>` — used consistently as the impl signature.
- `subSpan({ name: 'ror.X.Y' }, async () => …)` — same `ror.*` prefix and dot-namespacing across all wrapping tasks.
- `OpenTelemetryInitOptions` — fields used identically in Tasks 5, 6, 7, 8, 9 (the final form of `init()` in Task 9 supersedes the skeletons in 5, 6, 7, 8 — each earlier task is an additive refactor; Task 9's full implementation is the merged result).
- `tracerProvider: NodeTracerProvider | null` — set in `init()`, read in `__resetForTest` and `configureFastify` `onClose`. Naming consistent.
- `Attributes` (from `@opentelemetry/api`) — used in the declaration-merging augmentation, consistent with `tracer.startActiveSpan({ attributes })` call sites.

**Scope:** Single integration with clean boundaries: 1 new file, 4 small modifications to render-path files, 1 helper module update, 1 package.json edit, 1 changelog/docs commit. Each task is independently committable and reviewable. Fits a single PR.

**No spec gaps found.** The plan covers every requirement in the spec.
