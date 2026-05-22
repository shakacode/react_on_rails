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
