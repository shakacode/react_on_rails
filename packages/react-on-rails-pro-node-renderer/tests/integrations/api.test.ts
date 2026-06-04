import {
  getOpenTelemetryTracerProvider,
  registerFastifyConfigFunction,
  registerWorkerShutdownHook,
  resetSubSpan,
  resetTracing,
  setOpenTelemetryTracerProvider,
  setupSubSpan,
  setupTracing,
  WORKER_SHUTDOWN_HOOKS_TIMEOUT_MS,
  type SubSpanFn,
} from '../../src/integrations/api';

describe('integrations api', () => {
  afterEach(() => {
    resetSubSpan();
    resetTracing();
    setOpenTelemetryTracerProvider(null);
  });

  test('exports lifecycle hooks needed by integrations', () => {
    const subSpan: SubSpanFn = (opts, fn) => fn({ setAttributes() {} });
    const tracerProvider = {} as Parameters<typeof setOpenTelemetryTracerProvider>[0];

    expect(setupTracing({ executor: async (fn) => fn() })).toBe(true);
    expect(setupSubSpan(subSpan)).toBe(true);
    expect(typeof resetTracing).toBe('function');
    expect(typeof resetSubSpan).toBe('function');
    expect(getOpenTelemetryTracerProvider()).toBeNull();
    expect(typeof setOpenTelemetryTracerProvider).toBe('function');
    setOpenTelemetryTracerProvider(tracerProvider);
    expect(getOpenTelemetryTracerProvider()).toBe(tracerProvider);
    expect(typeof registerFastifyConfigFunction).toBe('function');
    expect(typeof registerWorkerShutdownHook).toBe('function');
    expect(WORKER_SHUTDOWN_HOOKS_TIMEOUT_MS).toBeGreaterThan(0);
  });
});
