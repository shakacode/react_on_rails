import {
  getOpenTelemetryTracerProvider,
  setOpenTelemetryTracerProvider,
} from '../shared/opentelemetryState.js';
import { resetSubSpan, resetTracing } from '../shared/tracing.js';
import * as fastifyConfig from '../worker/fastifyConfig.js';
import * as shutdownHooks from '../worker/shutdownHooks.js';

export async function resetOpenTelemetryForTest(): Promise<void> {
  const tracerProvider = getOpenTelemetryTracerProvider();
  if (tracerProvider) {
    await tracerProvider.shutdown();
    setOpenTelemetryTracerProvider(null);
  }

  resetSubSpan();
  resetTracing();

  // eslint-disable-next-line no-underscore-dangle
  fastifyConfig.__resetFastifyConfigFunctionsForTest();
  // eslint-disable-next-line no-underscore-dangle
  shutdownHooks.__resetWorkerShutdownHooksForTest();

  /* eslint-disable @typescript-eslint/no-require-imports, global-require */
  try {
    const otelApi = require('@opentelemetry/api') as typeof import('@opentelemetry/api');
    otelApi.trace.disable();
    otelApi.context.disable();
    otelApi.propagation.disable();
    otelApi.diag.disable();
  } catch {
    // OTel API not installed - nothing to disable.
  }
  /* eslint-enable @typescript-eslint/no-require-imports, global-require */
}
