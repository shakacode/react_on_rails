import log from './log.js';
import type { TracingContext } from './tracing.js';

export type Notifier<T> = (msg: T, tracingContext?: TracingContext) => void;
export type MessageNotifier = Notifier<string>;
export type ErrorNotifier = Notifier<Error>;

const messageNotifiers: MessageNotifier[] = [];
const errorNotifiers: ErrorNotifier[] = [];

/**
 * Adds a callback to notify a service on string error messages.
 */
export function addMessageNotifier(notifier: MessageNotifier) {
  messageNotifiers.push(notifier);
}

/**
 * Adds a callback to notify an error tracking service on JavaScript {@link Error}s.
 */
export function addErrorNotifier(notifier: ErrorNotifier) {
  errorNotifiers.push(notifier);
}

/**
 * Adds a callback to notify an error tracking service on both string error messages and JavaScript {@link Error}s.
 */
export function addNotifier(notifier: Notifier<string | Error>) {
  messageNotifiers.push(notifier);
  errorNotifiers.push(notifier);
}

function notify<T>(msg: T, tracingContext: TracingContext | undefined, notifiers: Notifier<T>[]) {
  notifiers.forEach((notifier) => {
    try {
      notifier(msg, tracingContext);
    } catch (e) {
      log.error(e, 'An error tracking notifier failed');
    }
  });
}

/**
 * Reports an error message.
 */
export function message(msg: string, tracingContext?: TracingContext) {
  log.error({ msg, label: 'ErrorReporter notification' });
  notify(msg, tracingContext, messageNotifiers);
}

/**
 * Reports an error.
 */
export function error(err: Error, tracingContext?: TracingContext) {
  log.error({ err, label: 'ErrorReporter notification' });
  notify(err, tracingContext, errorNotifiers);
}
