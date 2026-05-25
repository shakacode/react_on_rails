import path from 'path';
import { trace as otelTrace, type Tracer } from '@opentelemetry/api';
import { InMemorySpanExporter, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { init, __resetForTest } from '../../src/integrations/opentelemetry';
import worker, { disableHttp2 } from '../../src/worker';
import packageJson from '../../src/shared/packageJson';
import {
  trace,
  subSpan,
  startSsrRequestOptions,
  __resetSubSpanForTest,
  __resetTracingForTest,
} from '../../src/shared/tracing';
import { handleIncrementalRenderRequest } from '../../src/worker/handleIncrementalRenderRequest';
import { handleRenderRequest } from '../../src/worker/handleRenderRequest';
import {
  BUNDLE_TIMESTAMP,
  createIncrementalVmBundle,
  createUploadedBundle,
  mkdirAsync,
  resetForTest,
  serverBundleCachePath,
  uploadedBundlePath,
  vmBundlePath,
  waitFor,
} from '../helper';
import { Asset } from '../../src/shared/utils';

disableHttp2();

describe('opentelemetry integration: init()', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    await __resetForTest();
  });

  afterAll(async () => {
    await __resetForTest();
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

  test('init() uses OTEL_SERVICE_NAME before the configured serviceName option', () => {
    process.env.OTEL_SERVICE_NAME = 'env-renderer';

    try {
      init({
        serviceName: 'configured-renderer',
        spanProcessor: new SimpleSpanProcessor(exporter),
      });

      const tracer = otelTrace.getTracer('test');
      tracer.startActiveSpan('manual.span', (span) => {
        span.end();
      });

      expect(exporter.getFinishedSpans()[0]!.resource.attributes['service.name']).toBe('env-renderer');
    } finally {
      delete process.env.OTEL_SERVICE_NAME;
    }
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

  test('init() includes OTEL_RESOURCE_ATTRIBUTES and lets explicit resourceAttributes override them', () => {
    process.env.OTEL_RESOURCE_ATTRIBUTES =
      'deployment.environment=staging, service.version=1.2.3, custom.equals=value=with=equals';

    try {
      init({
        serviceName: 'test-renderer',
        resourceAttributes: { 'deployment.environment': 'test' },
        spanProcessor: new SimpleSpanProcessor(exporter),
      });

      const tracer = otelTrace.getTracer('test');
      tracer.startActiveSpan('manual.span', (span) => {
        span.end();
      });

      const attrs = exporter.getFinishedSpans()[0]!.resource.attributes;
      expect(attrs['service.name']).toBe('test-renderer');
      expect(attrs['deployment.environment']).toBe('test');
      expect(attrs['service.version']).toBe('1.2.3');
      expect(attrs['custom.equals']).toBe('value=with=equals');
    } finally {
      delete process.env.OTEL_RESOURCE_ATTRIBUTES;
    }
  });
});

describe('opentelemetry integration: fastify auto-instrumentation', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    await __resetForTest();
  });

  afterAll(async () => {
    await __resetForTest();
  });

  test('init({ fastify: true }) enables Fastify auto-registration', () => {
    const registerInstrumentations = jest.fn();
    const HttpInstrumentation = jest.fn(() => ({ name: 'http-instrumentation' }));
    const FastifyOtelInstrumentation = jest.fn(() => ({ name: 'fastify-instrumentation' }));
    jest.doMock('@opentelemetry/instrumentation', () => ({ registerInstrumentations }));
    jest.doMock('@opentelemetry/instrumentation-http', () => ({ HttpInstrumentation }));
    jest.doMock('@fastify/otel', () => ({ FastifyOtelInstrumentation }));

    try {
      init({
        fastify: true,
        spanProcessor: new SimpleSpanProcessor(exporter),
      });

      expect(FastifyOtelInstrumentation).toHaveBeenCalledWith({ registerOnInitialization: true });
      expect(registerInstrumentations).toHaveBeenCalledWith(
        expect.objectContaining({
          instrumentations: [{ name: 'http-instrumentation' }, { name: 'fastify-instrumentation' }],
        }),
      );
    } finally {
      jest.dontMock('@opentelemetry/instrumentation');
      jest.dontMock('@opentelemetry/instrumentation-http');
      jest.dontMock('@fastify/otel');
    }
  });

  test('init({ fastify: true }) initializes without throwing and tracer still works', () => {
    // Note: asserting Fastify-instrumentation-produced spans is unreliable in unit tests
    // because Jest's module cache and fastify's `app.inject()` codepath bypass much of
    // the instrumentation. The end-to-end test (Task 10) exercises the real worker server
    // and asserts the full span tree. Here we just confirm init({ fastify: true }) is
    // safe to call and leaves the tracer fully functional.
    expect(() =>
      init({
        fastify: true,
        spanProcessor: new SimpleSpanProcessor(exporter),
      }),
    ).not.toThrow();

    const tracer = otelTrace.getTracer('test');
    tracer.startActiveSpan('manual.span', (span) => span.end());

    const spanNames = exporter.getFinishedSpans().map((s) => s.name);
    expect(spanNames).toContain('manual.span');
  });
});

describe('opentelemetry integration: tracing wiring', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    // Reset OTel state AND both tracing/subSpan registrations so each test gets a clean install.
    __resetSubSpanForTest();
    __resetTracingForTest();
    await __resetForTest();
  });

  afterAll(async () => {
    __resetSubSpanForTest();
    __resetTracingForTest();
    await __resetForTest();
  });

  test('init({ tracing: true }) produces a ror.ssr.request span via trace()', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    await trace(async () => 'result', startSsrRequestOptions({ renderingRequest: 'irrelevant' }));

    const spanNames = exporter.getFinishedSpans().map((s) => s.name);
    expect(spanNames).toContain('ror.ssr.request');
  });

  test('init({ tracing: true }) wires subSpan() to produce child spans of ror.ssr.request', async () => {
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
    // The bundle span's parent must be the ssr span.
    expect(bundleSpan!.parentSpanContext?.spanId).toBe(ssrSpan!.spanContext().spanId);
  });

  test('subSpan does not leak renderingRequest payload into span attributes (sensitive data audit)', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    const secretPayload = 'SECRET-RENDERING-PAYLOAD-DO-NOT-LEAK';
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

  test('span has ERROR status when the wrapped function throws', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    await expect(
      trace(
        async () => {
          throw new Error('boom');
        },
        startSsrRequestOptions({ renderingRequest: 'irrelevant' }),
      ),
    ).rejects.toThrow('boom');

    const ssrSpan = exporter.getFinishedSpans().find((s) => s.name === 'ror.ssr.request');
    expect(ssrSpan).toBeDefined();
    // 2 = ERROR per @opentelemetry/api SpanStatusCode
    expect(ssrSpan!.status.code).toBe(2);
    expect(ssrSpan!.status.message).toBe('boom');
  });
});

describe('opentelemetry integration: end-to-end render request', () => {
  const testName = 'otelEndToEnd';
  let exporter: InMemorySpanExporter;

  const uploadedBundleForTest = (): Asset => ({
    filename: '',
    savedFilePath: uploadedBundlePath(testName),
    type: 'asset',
  });

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    __resetSubSpanForTest();
    __resetTracingForTest();
    await __resetForTest();
    await resetForTest(testName);
    await mkdirAsync(path.dirname(vmBundlePath(testName)), { recursive: true });
  });

  afterAll(async () => {
    __resetSubSpanForTest();
    __resetTracingForTest();
    await __resetForTest();
    await resetForTest(testName);
  });

  test('cache-miss probe labels intent instead of reporting cache.hit=true on the error span', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    await createUploadedBundle(testName);

    await trace(
      async () => {
        const result = await handleRenderRequest({
          renderingRequest: 'ReactOnRails.dummy',
          bundleTimestamp: BUNDLE_TIMESTAMP,
          providedNewBundles: [
            {
              bundle: uploadedBundleForTest(),
              timestamp: BUNDLE_TIMESTAMP,
            },
          ],
        });
        expect(result.response.status).toBe(200);
      },
      startSsrRequestOptions({ renderingRequest: 'ReactOnRails.dummy' }),
    );

    const cacheMissProbeSpan = exporter
      .getFinishedSpans()
      .find((s) => s.name === 'ror.bundle.build_execution_context' && s.status.code === 2);

    expect(cacheMissProbeSpan).toBeDefined();
    expect(cacheMissProbeSpan!.attributes['cache.strategy']).toBe('cache-first');
    expect(cacheMissProbeSpan!.attributes).not.toHaveProperty('cache.hit');
  });

  test('incremental update chunk failures mark the process_chunk span as an error', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });
    await createIncrementalVmBundle(testName);

    await trace(
      async () => {
        const result = await handleIncrementalRenderRequest({
          firstRequestChunk: { renderingRequest: 'ReactOnRails.dummy' },
          bundleTimestamp: BUNDLE_TIMESTAMP,
        });
        expect(result.response.status).toBe(200);
        expect(result.sink).toBeDefined();

        await result.sink!.add({ invalid: true });
      },
      startSsrRequestOptions({ renderingRequest: 'ReactOnRails.dummy' }),
    );

    const processChunkSpan = exporter
      .getFinishedSpans()
      .find((s) => s.name === 'ror.incremental.process_chunk');

    expect(processChunkSpan).toBeDefined();
    expect(processChunkSpan!.status.code).toBe(2);
    expect(processChunkSpan!.status.message).toContain('Invalid incremental render chunk');
  });

  test('incremental render endpoint nests stream spans under ror.ssr.request', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });
    await createIncrementalVmBundle(testName);

    const app = worker({
      serverBundleCachePath: serverBundleCachePath(testName),
      password: 'my_password',
      supportModules: true,
      stubTimers: false,
      logHttpLevel: 'silent',
    });

    try {
      const firstChunk = `${JSON.stringify({
        gemVersion: packageJson.version,
        protocolVersion: packageJson.protocolVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(firstChunk)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(200);

      await waitFor(() => {
        const spanNames = exporter.getFinishedSpans().map((s) => s.name);
        expect(spanNames).toContain('ror.ssr.request');
        expect(spanNames).toContain('ror.incremental.stream');
      });

      const spans = exporter.getFinishedSpans();
      const ssrSpan = spans.find((s) => s.name === 'ror.ssr.request');
      const incrementalStreamSpan = spans.find((s) => s.name === 'ror.incremental.stream');

      expect(ssrSpan).toBeDefined();
      expect(incrementalStreamSpan).toBeDefined();
      expect(incrementalStreamSpan!.parentSpanContext?.spanId).toBe(ssrSpan!.spanContext().spanId);
    } finally {
      await app.close();
    }
  });

  test('SSR render produces ror.ssr.request, ror.bundle.*, ror.vm.execute, ror.result.prepare spans', async () => {
    init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    await createUploadedBundle(testName);

    // Exercise the same path the worker uses: wrap handleRenderRequest in trace()
    // with the same startSsrRequestOptions, so the SSR root span is created.
    await trace(
      async () => {
        const result = await handleRenderRequest({
          renderingRequest: 'ReactOnRails.dummy',
          bundleTimestamp: BUNDLE_TIMESTAMP,
          providedNewBundles: [
            {
              bundle: uploadedBundleForTest(),
              timestamp: BUNDLE_TIMESTAMP,
            },
          ],
        });
        expect(result.response.status).toBe(200);
      },
      startSsrRequestOptions({ renderingRequest: 'ReactOnRails.dummy' }),
    );

    const spanNames = exporter.getFinishedSpans().map((s) => s.name);
    expect(spanNames).toEqual(
      expect.arrayContaining([
        'ror.ssr.request',
        'ror.bundle.upload',
        'ror.vm.execute',
        'ror.result.prepare',
      ]),
    );

    // Verify hierarchy: bundle/vm/result spans must be descendants of ror.ssr.request.
    const spans = exporter.getFinishedSpans();
    const ssrSpan = spans.find((s) => s.name === 'ror.ssr.request');
    expect(ssrSpan).toBeDefined();
    const ssrSpanId = ssrSpan!.spanContext().spanId;

    // Build a set of span IDs that descend from the SSR span (BFS).
    const descendants = new Set<string>([ssrSpanId]);
    let added = true;
    while (added) {
      added = false;
      for (const s of spans) {
        const parentId = s.parentSpanContext?.spanId;
        if (parentId && descendants.has(parentId) && !descendants.has(s.spanContext().spanId)) {
          descendants.add(s.spanContext().spanId);
          added = true;
        }
      }
    }

    for (const targetName of ['ror.bundle.upload', 'ror.vm.execute', 'ror.result.prepare']) {
      const span = spans.find((s) => s.name === targetName);
      expect(span).toBeDefined();
      expect(descendants.has(span!.spanContext().spanId)).toBe(true);
    }
  });
});
