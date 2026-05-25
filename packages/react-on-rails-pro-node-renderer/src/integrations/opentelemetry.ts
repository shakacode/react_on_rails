// Type-only imports — these are erased at runtime and do not trigger require().
// Runtime imports of the OTel SDK happen lazily inside init() so that users who
// haven't installed the optional OTel peer dependencies can still import this
// module without crashing — init() will simply log an error and no-op.
import type { Attributes } from '@opentelemetry/api';
import type { NodeTracerProvider as NodeTracerProviderType } from '@opentelemetry/sdk-trace-node';
import type { SpanExporter, SpanProcessor } from '@opentelemetry/sdk-trace-base';
import { resetSubSpan, resetTracing, setupTracing, setupSubSpan, type SubSpanFn } from '../shared/tracing.js';
import {
  getOpenTelemetryTracerProvider,
  setOpenTelemetryTracerProvider,
} from '../shared/opentelemetryState.js';
import { configureFastify } from '../worker/fastifyConfig.js';
import { log, message } from './api.js';

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
  /** Maximum time to wait for provider.shutdown() during Fastify onClose. Default: 5000ms. */
  shutdownTimeoutMs?: number;
}

const DEFAULT_SERVICE_NAME = 'react-on-rails-pro-node-renderer';
const DEFAULT_SHUTDOWN_TIMEOUT_MS = 5_000;

interface InstalledTracingAdapters {
  tracing: boolean;
  subSpan: boolean;
}

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production' || process.env.RAILS_ENV === 'production';
}

function resolveServiceName(opts: OpenTelemetryInitOptions): string {
  return process.env.OTEL_SERVICE_NAME ?? opts.serviceName ?? DEFAULT_SERVICE_NAME;
}

function resolveShutdownTimeoutMs(opts: OpenTelemetryInitOptions): number {
  const timeoutMs = opts.shutdownTimeoutMs ?? DEFAULT_SHUTDOWN_TIMEOUT_MS;
  return Number.isFinite(timeoutMs) && timeoutMs > 0 ? timeoutMs : DEFAULT_SHUTDOWN_TIMEOUT_MS;
}

function parseResourceAttributes(value: string | undefined): Record<string, string> {
  if (!value) return {};

  // OTel resource attributes are comma-separated. Literal commas in values must
  // be percent-encoded by callers; unencoded commas split the value.
  const attributes: Record<string, string> = {};
  for (const pair of value.split(',')) {
    const [rawKey, ...rawValueParts] = pair.split('=');
    const key = rawKey?.trim();

    if (key && rawValueParts.length > 0) {
      const rawValue = rawValueParts.join('=').trim().replace(/^"|"$/g, '');
      try {
        attributes[key] = decodeURIComponent(rawValue);
      } catch {
        // Keep init resilient when callers provide malformed percent-encoding.
        attributes[key] = rawValue;
      }
    }
  }

  return attributes;
}

function configureOpenTelemetryDiagnostics(otelApi: typeof import('@opentelemetry/api')): void {
  const logDiagnostic = (level: string, diagnosticMessage: string, ...args: unknown[]) => {
    if (level === 'error') {
      log.error({ otel: true, level, args }, diagnosticMessage);
    } else if (level === 'warn') {
      log.warn({ otel: true, level, args }, diagnosticMessage);
    } else {
      log.debug({ otel: true, level, args }, diagnosticMessage);
    }
  };

  otelApi.diag.setLogger(
    {
      error: (diagnosticMessage, ...args) => logDiagnostic('error', diagnosticMessage, ...args),
      warn: (diagnosticMessage, ...args) => logDiagnostic('warn', diagnosticMessage, ...args),
      info: (diagnosticMessage, ...args) => logDiagnostic('info', diagnosticMessage, ...args),
      debug: (diagnosticMessage, ...args) => logDiagnostic('debug', diagnosticMessage, ...args),
      verbose: (diagnosticMessage, ...args) => logDiagnostic('verbose', diagnosticMessage, ...args),
    },
    otelApi.DiagLogLevel.WARN,
  );
}

function disableOpenTelemetryGlobals(otelApi: typeof import('@opentelemetry/api')): void {
  otelApi.trace.disable();
  otelApi.context.disable();
  otelApi.propagation.disable();
  otelApi.diag.disable();
}

function resetInstalledTracingAdapters(
  installedAdapters: InstalledTracingAdapters,
): InstalledTracingAdapters {
  if (installedAdapters.subSpan) {
    resetSubSpan();
  }
  if (installedAdapters.tracing) {
    resetTracing();
  }

  return { tracing: false, subSpan: false };
}

async function shutdownProviderWithTimeout(
  provider: NodeTracerProviderType,
  shutdownTimeoutMs: number,
): Promise<void> {
  let timeoutId: ReturnType<typeof setTimeout> | undefined;
  const shutdownPromise = provider.shutdown().catch((error: unknown) => {
    log.warn({ msg: '[OpenTelemetry] provider.shutdown() failed', error });
  });

  try {
    await Promise.race([
      shutdownPromise,
      new Promise<void>((resolve) => {
        timeoutId = setTimeout(() => {
          log.warn(
            '[OpenTelemetry] provider.shutdown() timed out after %dms; continuing worker shutdown',
            shutdownTimeoutMs,
          );
          resolve();
        }, shutdownTimeoutMs);
      }),
    ]);
  } finally {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
  }
}

export function init(opts: OpenTelemetryInitOptions = {}): void {
  if (getOpenTelemetryTracerProvider()) {
    message('[OpenTelemetry] init() called more than once; ignoring duplicate call.');
    return;
  }

  let installedAdapters: InstalledTracingAdapters = { tracing: false, subSpan: false };

  try {
    /* eslint-disable @typescript-eslint/no-require-imports, global-require --
     * Lazy require so init() can no-op when peer deps are missing instead of
     * crashing at module load time. */
    const { NodeTracerProvider } =
      require('@opentelemetry/sdk-trace-node') as typeof import('@opentelemetry/sdk-trace-node');
    const { BatchSpanProcessor, SimpleSpanProcessor } =
      require('@opentelemetry/sdk-trace-base') as typeof import('@opentelemetry/sdk-trace-base');
    const { resourceFromAttributes } =
      require('@opentelemetry/resources') as typeof import('@opentelemetry/resources');
    const { ATTR_SERVICE_NAME } =
      require('@opentelemetry/semantic-conventions') as typeof import('@opentelemetry/semantic-conventions');
    const otelApi = require('@opentelemetry/api') as typeof import('@opentelemetry/api');

    const serviceName = resolveServiceName(opts);
    const shutdownTimeoutMs = resolveShutdownTimeoutMs(opts);
    const resource = resourceFromAttributes({
      ...parseResourceAttributes(process.env.OTEL_RESOURCE_ATTRIBUTES),
      ...(opts.resourceAttributes ?? {}),
      [ATTR_SERVICE_NAME]: serviceName,
    });

    const defaultExporter = () => {
      const { OTLPTraceExporter } =
        require('@opentelemetry/exporter-trace-otlp-http') as typeof import('@opentelemetry/exporter-trace-otlp-http');
      return new OTLPTraceExporter();
    };
    /* eslint-enable @typescript-eslint/no-require-imports, global-require */

    const spanProcessor =
      opts.spanProcessor ??
      (() => {
        const exporter = opts.exporter ?? defaultExporter();
        return isProduction() ? new BatchSpanProcessor(exporter) : new SimpleSpanProcessor(exporter);
      })();

    const provider = new NodeTracerProvider({
      resource,
      spanProcessors: [spanProcessor],
    });

    configureOpenTelemetryDiagnostics(otelApi);

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
          new FastifyOtelInstrumentation({ registerOnInitialization: true }),
        ],
        tracerProvider: provider,
      });
    }

    if (opts.tracing) {
      const tracer = otelApi.trace.getTracer(serviceName);

      installedAdapters.tracing = setupTracing({
        startSsrRequestOptions: () => ({
          // Keep the root span free of request payload data. Future safe
          // attributes should be derived from structured metadata supplied by
          // Ruby, not parsed out of the executable renderingRequest string.
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
      installedAdapters.subSpan = setupSubSpan(subSpanImpl);
    }

    setOpenTelemetryTracerProvider(provider);
    try {
      provider.register();
    } catch (err) {
      if (getOpenTelemetryTracerProvider() === provider) {
        setOpenTelemetryTracerProvider(null);
      }
      installedAdapters = resetInstalledTracingAdapters(installedAdapters);
      throw err;
    }

    // Register this last so failed init paths do not leave a partial Fastify hook
    // behind. Fastify fires onClose during app.close(), giving the span processor
    // a chance to export queued spans before the process exits.
    configureFastify((app) => {
      app.addHook('onClose', async () => {
        await shutdownProviderWithTimeout(provider, shutdownTimeoutMs);
        if (getOpenTelemetryTracerProvider() === provider) {
          setOpenTelemetryTracerProvider(null);
          disableOpenTelemetryGlobals(otelApi);
          installedAdapters = resetInstalledTracingAdapters(installedAdapters);
        }
      });
    });

    log.info('[OpenTelemetry] Tracer provider initialized');
  } catch (err) {
    installedAdapters = resetInstalledTracingAdapters(installedAdapters);
    message(`[OpenTelemetry] init failed: ${String(err)}`);
  }
}
