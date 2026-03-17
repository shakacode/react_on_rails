/**
 * This contains the options necessary to start a unit of work (transaction/span/etc.).
 * Integrations should augment it using their name as the property.
 *
 * For example, in Sentry SDK v7+ the unit of work is a `Span`, and `Sentry.startSpan` takes `StartSpanOptions`,
 * so that integration adds `{ sentry?: StartSpanOptions }`.
 * In v6, the unit of work is a `Transaction`, and `Sentry.startTransaction` takes `TransactionContext`,
 * so that integration adds `{ sentry6?: TransactionContext }`.
 */
export interface UnitOfWorkOptions {
}
/**
 * Passed to the callback function executed by {@link trace}.
 * This is only used (and augmented) by integrations that need to associate error reports with units of work manually.
 *
 * For example, Sentry SDK v7+ stores the active span in an {@link AsyncLocalStorage} and
 * it's automatically provided to `Sentry.capture...` methods, so it doesn't use this.
 * But v6 needs to include the active transaction in those methods'
 * {@link import('@sentry/types').CaptureContext} parameter, and so it adds `{ sentry6: CaptureContext }`.
 */
export interface TracingContext {
}
type UnitOfWork<T> = (tracingContext?: TracingContext) => Promise<T>;
type Executor = <T>(fn: UnitOfWork<T>, unitOfWorkOptions: UnitOfWorkOptions) => Promise<T>;
/**
 * Data describing an SSR request.
 */
interface SsrRequestData {
    renderingRequest: string;
}
type StartSsrRequestOptions = (request: SsrRequestData) => UnitOfWorkOptions;
export declare const startSsrRequestOptions: StartSsrRequestOptions;
/**
 * Options for {@link trace}.
 */
export interface TracingIntegrationOptions {
    executor: Executor;
    startSsrRequestOptions?: StartSsrRequestOptions;
}
/**
 * Sets up tracing for the given integration.
 * @param options.executor - A function that wraps an async callback in the tracing service's unit of work.
 * @param options.startSsrRequestOptions - Options used to start a new unit of work for an SSR request.
 *   Should be an object with your integration name as the only property.
 *   It will be passed to the executor.
 */
export declare function setupTracing(options: TracingIntegrationOptions): void;
/**
 * Reports a unit of work to the tracing service, if any.
 */
export declare function trace<T>(fn: UnitOfWork<T>, unitOfWorkOptions: UnitOfWorkOptions): Promise<T>;
export {};
//# sourceMappingURL=tracing.d.ts.map