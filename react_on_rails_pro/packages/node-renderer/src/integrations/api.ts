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

export { default as log } from '../shared/log';
export { addErrorNotifier, addMessageNotifier, addNotifier, error, message } from '../shared/errorReporter';
export {
  setupTracing,
  TracingContext,
  TracingIntegrationOptions,
  UnitOfWorkOptions,
} from '../shared/tracing';
export { configureFastify, FastifyConfigFunction } from '../worker';
