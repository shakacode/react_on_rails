import { jest } from '@jest/globals';
import {
  context as otelContext,
  diag as otelDiag,
  propagation as otelPropagation,
  trace as otelTrace,
} from '@opentelemetry/api';

const resetOpenTelemetryForTest = async () => {
  const testUtils = await import('../../src/testUtils/opentelemetry');
  await testUtils.resetOpenTelemetryForTest();
};

describe('opentelemetry integration: init() failure path', () => {
  beforeEach(() => {
    jest.resetModules();
    otelTrace.disable();
    otelContext.disable();
    otelPropagation.disable();
    otelDiag.disable();
  });

  afterEach(() => {
    jest.dontMock('@fastify/otel');
    jest.dontMock('@opentelemetry/api');
    jest.dontMock('@opentelemetry/exporter-trace-otlp-http');
    jest.dontMock('@opentelemetry/instrumentation');
    jest.dontMock('@opentelemetry/instrumentation-http');
    jest.dontMock('@opentelemetry/sdk-trace-base');
    jest.dontMock('@opentelemetry/sdk-trace-node');
    jest.dontMock('../../src/integrations/api.js');
    jest.dontMock('../../src/worker/fastifyConfig.js');
    jest.dontMock('fastify');
    jest.restoreAllMocks();
    otelTrace.disable();
    otelContext.disable();
    otelPropagation.disable();
    otelDiag.disable();
  });

  test('init() catches missing-peer-dep import error and returns without throwing', async () => {
    // Mock the SDK import to throw, simulating a missing peer dep at runtime.
    jest.doMock('@opentelemetry/sdk-trace-node', () => {
      throw new Error('Cannot find module @opentelemetry/sdk-trace-node');
    });

    const errorReporter = await import('../../src/shared/errorReporter');
    const messageSpy = jest.spyOn(errorReporter, 'message');

    // Importing the integration itself must not throw even though the SDK throws.
    // The integration defers the require to inside init().
    const otel = await import('../../src/integrations/opentelemetry');
    expect(() => otel.init()).not.toThrow();
    expect(messageSpy).toHaveBeenCalledWith(expect.stringContaining('[OpenTelemetry] init failed'));
  });

  test('the integration module itself can be imported with no @opentelemetry/* packages loaded', async () => {
    // Importing the integration should never trigger require() of any OTel SDK package.
    // This test confirms the type-only imports stay erased at runtime and the integration
    // is safe to import in environments where the OTel peer deps are missing.
    jest.doMock('@opentelemetry/sdk-trace-node', () => {
      throw new Error('should not be required at import time');
    });
    jest.doMock('@opentelemetry/api', () => {
      throw new Error('should not be required at import time');
    });
    jest.doMock('@opentelemetry/sdk-trace-base', () => {
      throw new Error('should not be required at import time');
    });

    // This import should succeed without triggering any of the mocked throws.
    const otel = await import('../../src/integrations/opentelemetry');
    expect(otel).toBeDefined();
    expect(otel).not.toHaveProperty('__resetForTest');
  });

  test('the integration module can be imported without loading Fastify or the worker graph', async () => {
    jest.doMock('fastify', () => {
      throw new Error('fastify should not be loaded by opentelemetry import');
    });

    await expect(import('../../src/integrations/opentelemetry')).resolves.toBeDefined();
  });

  test('init() with a custom spanProcessor does not require the default OTLP exporter', async () => {
    jest.doMock('@opentelemetry/exporter-trace-otlp-http', () => {
      throw new Error('Cannot find module @opentelemetry/exporter-trace-otlp-http');
    });

    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const errorReporter = await import('../../src/shared/errorReporter');
    const messageSpy = jest.spyOn(errorReporter, 'message');
    const otel = await import('../../src/integrations/opentelemetry');

    otel.init({
      spanProcessor: new SimpleSpanProcessor(new InMemorySpanExporter()),
    });

    expect(messageSpy).not.toHaveBeenCalledWith(expect.stringContaining('[OpenTelemetry] init failed'));
    await resetOpenTelemetryForTest();
  });

  test('init({ fastify: true }) auto-registers the Fastify OTel plugin on initialization', async () => {
    const fastifyConfigs: unknown[] = [];

    jest.doMock('@opentelemetry/instrumentation', () => ({
      registerInstrumentations: jest.fn(),
    }));
    jest.doMock('@opentelemetry/instrumentation-http', () => ({
      HttpInstrumentation: jest.fn(function HttpInstrumentation() {}),
    }));
    jest.doMock('@fastify/otel', () => ({
      FastifyOtelInstrumentation: jest.fn(function FastifyOtelInstrumentation(config: unknown) {
        fastifyConfigs.push(config);
      }),
    }));

    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const otel = await import('../../src/integrations/opentelemetry');

    otel.init({
      fastify: true,
      spanProcessor: new SimpleSpanProcessor(new InMemorySpanExporter()),
    });

    expect(fastifyConfigs).toEqual([expect.objectContaining({ registerOnInitialization: true })]);
    await resetOpenTelemetryForTest();
  });

  test('Fastify onClose does not wait forever for provider.shutdown()', async () => {
    jest.useFakeTimers();
    try {
      let configureFastifyCallback: ((app: { addHook: jest.Mock }) => void) | undefined;
      let onClose: (() => Promise<void>) | undefined;
      const shutdown = jest.fn(() => new Promise<void>(() => undefined));

      jest.doMock('../../src/worker/fastifyConfig.js', () => ({
        configureFastify: jest.fn((callback: (app: { addHook: jest.Mock }) => void) => {
          configureFastifyCallback = callback;
        }),
      }));
      jest.doMock('@opentelemetry/sdk-trace-node', () => ({
        NodeTracerProvider: jest.fn(function NodeTracerProvider() {
          return {
            register: jest.fn(),
            shutdown,
          };
        }),
      }));

      const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
      const otel = await import('../../src/integrations/opentelemetry');

      otel.init({
        spanProcessor: new SimpleSpanProcessor(new InMemorySpanExporter()),
        shutdownTimeoutMs: 25,
      });

      configureFastifyCallback!({
        addHook: jest.fn((_name: string, handler: () => Promise<void>) => {
          onClose = handler;
        }),
      });

      const closePromise = onClose!();
      jest.advanceTimersByTime(25);

      await expect(closePromise).resolves.toBeUndefined();
      expect(shutdown).toHaveBeenCalledTimes(1);
    } finally {
      jest.useRealTimers();
    }
  });

  test('init() does not register a Fastify shutdown hook when provider.register() fails', async () => {
    const configureFastify = jest.fn();

    jest.doMock('../../src/worker/fastifyConfig.js', () => ({
      configureFastify,
    }));
    jest.doMock('@opentelemetry/sdk-trace-node', () => ({
      NodeTracerProvider: jest.fn(function NodeTracerProvider() {
        return {
          register: jest.fn(() => {
            throw new Error('register failed');
          }),
          shutdown: jest.fn(async () => undefined),
        };
      }),
    }));

    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const otel = await import('../../src/integrations/opentelemetry');
    const tracing = await import('../../src/shared/tracing');

    expect(() =>
      otel.init({
        tracing: true,
        spanProcessor: new SimpleSpanProcessor(new InMemorySpanExporter()),
      }),
    ).not.toThrow();

    expect(configureFastify).not.toHaveBeenCalled();
    expect(
      tracing.setupTracing({
        executor: (fn) => fn(),
      }),
    ).toBe(true);
    expect(tracing.setupSubSpan((_opts, fn) => fn())).toBe(true);
    tracing.__resetTracingForTest();
    tracing.__resetSubSpanForTest();
  });

  test('Fastify onClose disables the global tracer provider so init() can run again', async () => {
    const configureFastifyCallbacks: Array<(app: { addHook: jest.Mock }) => void> = [];

    jest.doMock('../../src/worker/fastifyConfig.js', () => ({
      configureFastify: jest.fn((callback: (app: { addHook: jest.Mock }) => void) => {
        configureFastifyCallbacks.push(callback);
      }),
    }));

    const { trace } = await import('@opentelemetry/api');
    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const firstExporter = new InMemorySpanExporter();
    const secondExporter = new InMemorySpanExporter();
    const otel = await import('../../src/integrations/opentelemetry');
    const tracing = await import('../../src/shared/tracing');

    const installOnCloseHook = async () => {
      let onClose: (() => Promise<void>) | undefined;
      configureFastifyCallbacks.at(-1)!({
        addHook: jest.fn((_name: string, handler: () => Promise<void>) => {
          onClose = handler;
        }),
      });
      await onClose!();
    };

    const renderWithTracing = (renderingRequest: string, childName: string) =>
      tracing.trace(
        () => tracing.subSpan({ name: childName }, async () => 'ok'),
        tracing.startSsrRequestOptions({ renderingRequest }),
      );

    otel.init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(firstExporter),
    });
    trace.getTracer('test').startActiveSpan('first.manual', (span) => {
      span.end();
    });
    await renderWithTracing('ReactOnRails.first', 'first.child');
    expect(firstExporter.getFinishedSpans().map((span) => span.name)).toEqual([
      'first.manual',
      'first.child',
      'ror.ssr.request',
    ]);

    await installOnCloseHook();

    otel.init({
      tracing: true,
      spanProcessor: new SimpleSpanProcessor(secondExporter),
    });
    trace.getTracer('test').startActiveSpan('second.manual', (span) => {
      span.end();
    });
    await renderWithTracing('ReactOnRails.second', 'second.child');

    expect(secondExporter.getFinishedSpans().map((span) => span.name)).toEqual([
      'second.manual',
      'second.child',
      'ror.ssr.request',
    ]);
    await installOnCloseHook();
  });

  test('OpenTelemetry diagnostics preserve warn and error severity in renderer logs', async () => {
    const log = {
      debug: jest.fn(),
      error: jest.fn(),
      info: jest.fn(),
      warn: jest.fn(),
    };

    jest.doMock('../../src/integrations/api.js', () => ({
      log,
      message: jest.fn(),
    }));

    const { diag } = await import('@opentelemetry/api');
    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const otel = await import('../../src/integrations/opentelemetry');

    otel.init({
      spanProcessor: new SimpleSpanProcessor(new InMemorySpanExporter()),
    });

    diag.error('collector rejected spans', { statusCode: 401 });
    diag.warn('collector slow');
    diag.info('suppressed info');

    expect(log.error).toHaveBeenCalledWith(
      { otel: true, level: 'error', args: [{ statusCode: 401 }] },
      'collector rejected spans',
    );
    expect(log.warn).toHaveBeenCalledWith({ otel: true, level: 'warn', args: [] }, 'collector slow');
    expect(log.debug).not.toHaveBeenCalledWith(expect.anything(), 'suppressed info');
    await resetOpenTelemetryForTest();
  });

  test('init() ignores duplicate calls without replacing the active provider', async () => {
    const errorReporter = await import('../../src/shared/errorReporter');
    const messageSpy = jest.spyOn(errorReporter, 'message');
    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const firstExporter = new InMemorySpanExporter();
    const secondExporter = new InMemorySpanExporter();
    const { trace } = await import('@opentelemetry/api');
    const otel = await import('../../src/integrations/opentelemetry');

    otel.init({
      spanProcessor: new SimpleSpanProcessor(firstExporter),
    });
    otel.init({
      spanProcessor: new SimpleSpanProcessor(secondExporter),
    });

    trace.getTracer('test').startActiveSpan('manual.span', (span) => {
      span.end();
    });

    expect(firstExporter.getFinishedSpans()).toHaveLength(1);
    expect(secondExporter.getFinishedSpans()).toHaveLength(0);
    expect(messageSpy).toHaveBeenCalledWith(
      '[OpenTelemetry] init() called more than once; ignoring duplicate call.',
    );
    await resetOpenTelemetryForTest();
  });

  test('init() does not register a global provider when a later Fastify lazy import fails', async () => {
    jest.doMock('@fastify/otel', () => {
      throw new Error('Cannot find module @fastify/otel');
    });

    const { trace } = await import('@opentelemetry/api');
    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const exporter = new InMemorySpanExporter();
    const otel = await import('../../src/integrations/opentelemetry');

    otel.init({
      fastify: true,
      spanProcessor: new SimpleSpanProcessor(exporter),
    });

    trace.getTracer('test').startActiveSpan('manual.span', (span) => {
      span.end();
    });

    expect(exporter.getFinishedSpans()).toHaveLength(0);
    await resetOpenTelemetryForTest();
  });
});
