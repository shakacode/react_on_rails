import { trace as otelTrace, type Tracer } from '@opentelemetry/api';
import { InMemorySpanExporter, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { init, __resetForTest } from '../../src/integrations/opentelemetry';
import {
  trace,
  subSpan,
  startSsrRequestOptions,
  __resetSubSpanForTest,
  __resetTracingForTest,
} from '../../src/shared/tracing';

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

describe('opentelemetry integration: fastify auto-instrumentation', () => {
  let exporter: InMemorySpanExporter;

  beforeEach(async () => {
    exporter = new InMemorySpanExporter();
    await __resetForTest();
  });

  afterAll(async () => {
    await __resetForTest();
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
