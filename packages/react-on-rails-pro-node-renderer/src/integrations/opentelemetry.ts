// Type-only imports — these are erased at runtime and do not trigger require().
// Runtime imports of the OTel SDK happen lazily inside init() so that users who
// haven't installed the optional OTel peer dependencies can still import this
// module without crashing — init() will simply log an error and no-op.
import type { Attributes } from '@opentelemetry/api';
import type { NodeTracerProvider as NodeTracerProviderType } from '@opentelemetry/sdk-trace-node';
import type { SpanExporter, SpanProcessor } from '@opentelemetry/sdk-trace-base';
import { setupTracing, setupSubSpan, type SubSpanFn } from '../shared/tracing.js';
import { configureFastify, log, message } from './api.js';

declare module '../shared/tracing.js' {
  interface UnitOfWorkOptions {
    opentelemetry?: { name: string; attributes?: Attributes };
  }
}

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

let tracerProvider: NodeTracerProviderType | null = null;

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production' || process.env.RAILS_ENV === 'production';
}

export function init(opts: OpenTelemetryInitOptions = {}): void {
  try {
    /* eslint-disable @typescript-eslint/no-require-imports, global-require --
     * Lazy require so init() can no-op when peer deps are missing instead of
     * crashing at module load time. */
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
      // @fastify/otel uses `export = exported` so the require() returns the namespace
      // object; the constructor lives on `.FastifyOtelInstrumentation` (also as `.default`).
      const { FastifyOtelInstrumentation } = require('@fastify/otel') as typeof import('@fastify/otel');
      /* eslint-enable @typescript-eslint/no-require-imports, global-require */
      registerInstrumentations({
        instrumentations: [
          // HTTP first — Fastify instrumentation depends on it.
          new HttpInstrumentation(),
          new FastifyOtelInstrumentation(),
        ],
        tracerProvider,
      });
    }

    if (opts.tracing) {
      const tracer = otelApi.trace.getTracer(opts.serviceName ?? DEFAULT_SERVICE_NAME);

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

    // Flush pending spans on graceful shutdown. Fastify fires onClose during
    // worker.destroy() / app.close(), giving the BatchSpanProcessor a chance to
    // export queued spans before the process exits.
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
  /* eslint-disable @typescript-eslint/no-require-imports, global-require */
  try {
    const otelApi = require('@opentelemetry/api') as typeof import('@opentelemetry/api');
    otelApi.trace.disable();
  } catch {
    // OTel API not installed — nothing to disable.
  }
  /* eslint-enable @typescript-eslint/no-require-imports, global-require */
}
