import { trace as otelTrace, type Tracer } from '@opentelemetry/api';
import { InMemorySpanExporter, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { init, __resetForTest } from '../../src/integrations/opentelemetry';

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
