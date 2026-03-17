import type { TracingContext } from './tracing.js';
export type Notifier<T> = (msg: T, tracingContext?: TracingContext) => void;
export type MessageNotifier = Notifier<string>;
export type ErrorNotifier = Notifier<Error>;
/**
 * Adds a callback to notify a service on string error messages.
 */
export declare function addMessageNotifier(notifier: MessageNotifier): void;
/**
 * Adds a callback to notify an error tracking service on JavaScript {@link Error}s.
 */
export declare function addErrorNotifier(notifier: ErrorNotifier): void;
/**
 * Adds a callback to notify an error tracking service on both string error messages and JavaScript {@link Error}s.
 */
export declare function addNotifier(notifier: Notifier<string | Error>): void;
/**
 * Reports an error message.
 */
export declare function message(msg: string, tracingContext?: TracingContext): void;
/**
 * Reports an error.
 */
export declare function error(err: Error, tracingContext?: TracingContext): void;
//# sourceMappingURL=errorReporter.d.ts.map