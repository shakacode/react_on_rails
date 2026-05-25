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
import { registerFastifyConfigFunction } from '../worker/fastifyConfig.js';
import { registerWorkerShutdownHook } from '../worker/shutdownHooks.js';
import { log, message } from './api.js';

declare module '../shared/tracing.js' {
  interface UnitOfWorkOptions {
    opentelemetry?: { name: string; attributes?: Attributes };
  }
}

export interface OpenTelemetryInitOptions {
  /** Service name reported in traces. Defaults to "react-on-rails-pro-node-renderer".
   *  `OTEL_SERVICE_NAME` env var takes precedence over this value. If neither is
   *  set, `resourceAttributes["service.name"]` or `OTEL_RESOURCE_ATTRIBUTES`
   *  can override the default service name. */
  serviceName?: string;
  /** Register HTTP + Fastify auto-instrumentation. Default: false.
   *  OpenTelemetry module patches are process-global and cannot be rolled back;
   *  if later init steps fail, patched modules remain installed with a no-op tracer. */
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

function resolveConfiguredServiceName(opts: OpenTelemetryInitOptions): string | undefined {
  return process.env.OTEL_SERVICE_NAME ?? opts.serviceName;
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
  otelApi.diag.setLogger(
    {
      error: (diagnosticMessage, ...args) =>
        log.error({ otel: true, level: 'error', args }, diagnosticMessage),
      warn: (diagnosticMessage, ...args) => log.warn({ otel: true, level: 'warn', args }, diagnosticMessage),
      // DiagLogLevel.WARN below suppresses lower-severity diagnostics before
      // these callbacks run. Keep no-op methods to satisfy the OTel logger API.
      info: () => undefined,
      debug: () => undefined,
      verbose: () => undefined,
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
  let timedOut = false;
  const shutdownPromise = provider.shutdown();
  const observedShutdownPromise = shutdownPromise.catch((error: unknown) => {
    if (!timedOut) {
      log.warn({ error }, '[OpenTelemetry] provider.shutdown() failed');
    }
  });

  try {
    await Promise.race([
      observedShutdownPromise,
      new Promise<void>((resolve) => {
        timeoutId = setTimeout(() => {
          timedOut = true;
          void shutdownPromise.catch(() => undefined);
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
  let otelApi: typeof import('@opentelemetry/api') | undefined;
  let registeredProvider: NodeTracerProviderType | undefined;
  let unregisterFastifyConfig: (() => void) | undefined;
  let unregisterWorkerShutdownHook: (() => void) | undefined;
  let ownsOpenTelemetryGlobals = false;

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
    otelApi = require('@opentelemetry/api') as typeof import('@opentelemetry/api');
    const loadedOtelApi = otelApi;

    const resourceAttributes = {
      ...parseResourceAttributes(process.env.OTEL_RESOURCE_ATTRIBUTES),
      ...(opts.resourceAttributes ?? {}),
    };
    const configuredServiceName = resolveConfiguredServiceName(opts);
    const serviceName =
      configuredServiceName ?? resourceAttributes[ATTR_SERVICE_NAME] ?? DEFAULT_SERVICE_NAME;
    const shutdownTimeoutMs = resolveShutdownTimeoutMs(opts);
    const resource = resourceFromAttributes({
      [ATTR_SERVICE_NAME]: serviceName,
      ...resourceAttributes,
      ...(configuredServiceName ? { [ATTR_SERVICE_NAME]: configuredServiceName } : {}),
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
      const tracer = loadedOtelApi.trace.getTracer(serviceName);

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
                code: loadedOtelApi.SpanStatusCode.ERROR,
                message: err instanceof Error ? err.message : String(err),
              });
              throw err;
            } finally {
              span.end();
            }
          });
        },
      });

      if (installedAdapters.tracing) {
        const subSpanImpl: SubSpanFn = (subOpts, fn) =>
          tracer.startActiveSpan(subOpts.name, { attributes: subOpts.attributes }, async (span) => {
            try {
              return await fn();
            } catch (err) {
              span.setStatus({
                code: loadedOtelApi.SpanStatusCode.ERROR,
                message: err instanceof Error ? err.message : String(err),
              });
              throw err;
            } finally {
              span.end();
            }
          });
        installedAdapters.subSpan = setupSubSpan(subSpanImpl);
      } else {
        message(
          '[OpenTelemetry] tracing integration was not installed because another tracing integration is ' +
            'active; skipping OpenTelemetry sub-spans.',
        );
      }
    }

    try {
      provider.register();
      setOpenTelemetryTracerProvider(provider);
      registeredProvider = provider;
      ownsOpenTelemetryGlobals = true;
      configureOpenTelemetryDiagnostics(loadedOtelApi);
    } catch (err) {
      installedAdapters = resetInstalledTracingAdapters(installedAdapters);
      // When opts.fastify is enabled, OpenTelemetry does not expose a public
      // rollback API for module patches applied by registerInstrumentations().
      // With no registered provider, those shims use the no-op tracer.
      message(`[OpenTelemetry] init failed: ${String(err)}`);
      return;
    }

    let shutdownOpenTelemetryPromise: Promise<void> | undefined;
    const shutdownOpenTelemetry = () => {
      shutdownOpenTelemetryPromise ??= (async () => {
        try {
          await shutdownProviderWithTimeout(provider, shutdownTimeoutMs);
          if (getOpenTelemetryTracerProvider() === provider) {
            setOpenTelemetryTracerProvider(null);
            disableOpenTelemetryGlobals(loadedOtelApi);
            ownsOpenTelemetryGlobals = false;
            installedAdapters = resetInstalledTracingAdapters(installedAdapters);
          }
        } finally {
          unregisterFastifyConfig?.();
          unregisterWorkerShutdownHook?.();
        }
      })();

      return shutdownOpenTelemetryPromise;
    };

    // Register these last so failed init paths do not leave partial shutdown hooks
    // behind. The worker hook runs during cluster restarts, while Fastify onClose
    // still handles explicit app.close() calls from tests or custom integrations.
    unregisterWorkerShutdownHook = registerWorkerShutdownHook(shutdownOpenTelemetry);
    unregisterFastifyConfig = registerFastifyConfigFunction((app) => {
      app.addHook('onClose', shutdownOpenTelemetry);
    });

    log.info('[OpenTelemetry] Tracer provider initialized');
  } catch (err) {
    unregisterFastifyConfig?.();
    unregisterWorkerShutdownHook?.();
    if (
      ownsOpenTelemetryGlobals &&
      registeredProvider &&
      otelApi &&
      getOpenTelemetryTracerProvider() === registeredProvider
    ) {
      setOpenTelemetryTracerProvider(null);
      disableOpenTelemetryGlobals(otelApi);
      ownsOpenTelemetryGlobals = false;
    }
    installedAdapters = resetInstalledTracingAdapters(installedAdapters);
    message(`[OpenTelemetry] init failed: ${String(err)}`);
  }
}
