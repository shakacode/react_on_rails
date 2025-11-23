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
  TracingContext,
  TracingIntegrationOptions,
  UnitOfWorkOptions,
} from '../shared/tracing.js';
export { configureFastify, FastifyConfigFunction } from '../worker.js';
