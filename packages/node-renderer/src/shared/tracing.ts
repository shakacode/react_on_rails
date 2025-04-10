import { message } from './errorReporter';

/* eslint-disable @typescript-eslint/no-empty-object-type -- empty interfaces are used as targets for augmentation */
/**
 * This contains the options necessary to start a unit of work (transaction/span/etc.).
 * Integrations should augment it using their name as the property.
 *
 * For example, in Sentry SDK v7+ the unit of work is a `Span`, and `Sentry.startSpan` takes `StartSpanOptions`,
 * so that integration adds `{ sentry?: StartSpanOptions }`.
 * In v6, the unit of work is a `Transaction`, and `Sentry.startTransaction` takes `TransactionContext`,
 * so that integration adds `{ sentry6?: TransactionContext }`.
 */
export interface UnitOfWorkOptions {}

/**
 * Passed to the callback function executed by {@link trace}.
 * This is only used (and augmented) by integrations that need to associate error reports with units of work manually.
 *
 * For example, Sentry SDK v7+ stores the active span in an {@link AsyncLocalStorage} and
 * it's automatically provided to `Sentry.capture...` methods, so it doesn't use this.
 * But v6 needs to include the active transaction in those methods'
 * {@link import('@sentry/types').CaptureContext} parameter, and so it adds `{ sentry6: CaptureContext }`.
 */
export interface TracingContext {}
/* eslint-enable @typescript-eslint/no-empty-object-type */

let setupRun = false;

type UnitOfWork<T> = (tracingContext?: TracingContext) => Promise<T>;

type Executor = <T>(fn: UnitOfWork<T>, unitOfWorkOptions: UnitOfWorkOptions) => Promise<T>;

let executor: Executor = (fn) => fn();

// TODO: determine what else to pass here. Maybe Ruby could send the component name.
// It will also be augmentable by integrations, to support distributed tracing
// https://github.com/shakacode/react_on_rails_pro/issues/473
/**
 * Data describing an SSR request.
 */
interface SsrRequestData {
  renderingRequest: string;
}

type StartSsrRequestOptions = (request: SsrRequestData) => UnitOfWorkOptions;

let mutableStartSsrRequestOptions: StartSsrRequestOptions = () => ({});

export const startSsrRequestOptions: StartSsrRequestOptions = (request) =>
  mutableStartSsrRequestOptions(request);

// TODO: maybe make UnitOfWorkOptions a generic parameter for this and for setupTracing
//  instead of sharing between all integrations.
/**
 * Options for {@link trace}.
 */
export interface TracingIntegrationOptions {
  executor: Executor;
  startSsrRequestOptions?: StartSsrRequestOptions;
}

// TODO: this supports only one tracing plugin.
//  Replace by a function which extends the executor and transaction context instead of replacing them.
/**
 * Sets up tracing for the given integration.
 * @param options.executor - A function that wraps an async callback in the tracing service's unit of work.
 * @param options.startSsrRequestOptions - Options used to start a new unit of work for an SSR request.
 *   Should be an object with your integration name as the only property.
 *   It will be passed to the executor.
 */
export function setupTracing(options: TracingIntegrationOptions) {
  if (setupRun) {
    message('setupTracing called more than once. Currently only one tracing integration can be enabled.');
    return;
  }

  executor = options.executor;
  if (options.startSsrRequestOptions) {
    mutableStartSsrRequestOptions = options.startSsrRequestOptions;
  }
  setupRun = true;
}

/**
 * Reports a unit of work to the tracing service, if any.
 */
export function trace<T>(fn: UnitOfWork<T>, unitOfWorkOptions: UnitOfWorkOptions): Promise<T> {
  return executor(fn, unitOfWorkOptions);
}
