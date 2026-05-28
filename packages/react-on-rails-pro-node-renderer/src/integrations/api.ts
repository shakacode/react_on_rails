/**
 * Public API for integrations with error reporting and tracing services.
 *
 * @example
 * ```ts
 * import Bugsnag from '@bugsnag/js';
 * import { addNotifier, setupTracing } from 'react-on-rails-pro-node-renderer/integrations/api';
 * Bugsnag.start({ ... });
 *
 * addNotifier((msg) => { Bugsnag.notify(msg); });
 * setupTracing({
 *   executor: async (fn) => {
 *     Bugsnag.startSession();
 *     try {
 *       return await fn();
 *     } finally {
 *       Bugsnag.pauseSession();
 *     }
 *   },
 * });
 * ```
 *
 * @module
 */

export { default as log } from '../shared/log.js';
export {
  addErrorNotifier,
  addMessageNotifier,
  addNotifier,
  error,
  message,
  Notifier,
  ErrorNotifier,
  MessageNotifier,
} from '../shared/errorReporter.js';
export {
  setupTracing,
  setupSubSpan,
  subSpan,
  TracingContext,
  TracingIntegrationOptions,
  UnitOfWorkOptions,
  SubSpanOptions,
  SubSpanFn,
  SubSpanController,
} from '../shared/tracing.js';
/**
 * Lifecycle teardown helpers for integrations that own the active tracing state.
 * Do not call these while another integration owns tracing or while SSR requests
 * are in flight.
 */
export { resetTracing, resetSubSpan } from '../shared/tracing.js';
export { getOpenTelemetryTracerProvider } from '../shared/opentelemetryState.js';
/**
 * Updates the OpenTelemetry lifecycle owner. Callers must pair provider
 * ownership with cleanup and must not call this during another init/shutdown
 * cycle.
 *
 * Note: getOpenTelemetryTracerProvider above is read-only and has no such
 * restriction.
 */
export { setOpenTelemetryTracerProvider } from '../shared/opentelemetryState.js';
export {
  configureFastify,
  registerFastifyConfigFunction,
  FastifyConfigFunction,
} from '../worker/fastifyConfig.js';
export {
  registerWorkerShutdownHook,
  WORKER_SHUTDOWN_HOOKS_TIMEOUT_MS,
  WorkerShutdownHook,
} from '../worker/shutdownHooks.js';
