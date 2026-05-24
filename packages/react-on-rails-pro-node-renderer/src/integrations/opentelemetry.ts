import { trace as otelTrace } from '@opentelemetry/api';
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
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import FastifyOtelInstrumentation from '@fastify/otel';
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

    if (opts.fastify) {
      registerInstrumentations({
        instrumentations: [
          // HTTP first — Fastify instrumentation depends on it.
          new HttpInstrumentation(),
          new FastifyOtelInstrumentation(),
        ],
        tracerProvider,
      });
    }
  } catch (err) {
    message(`[OpenTelemetry] init failed: ${String(err)}`);
  }
}

/** Test-only: shut down the tracer provider and reset module state. */
// eslint-disable-next-line no-underscore-dangle -- test hook, intentionally hidden by name
export async function __resetForTest(): Promise<void> {
  if (tracerProvider) {
    await tracerProvider.shutdown();
    tracerProvider = null;
  }
  // Unregister the global tracer provider so the next init() can register a fresh one.
  // Without this, otelTrace.setGlobalTracerProvider() silently skips setDelegate() because
  // registerGlobal() returns false after the first successful registration.
  otelTrace.disable();
}
