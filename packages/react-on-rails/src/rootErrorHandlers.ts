import type { RootErrorContext, RootErrorHandler, RootErrorHandlers } from './types/index.ts';
import type { ReactHydrateOptions } from './reactApis.cts';
import { supportsRootApi, supportsReact19RootErrorCallbacks } from './reactApis.cts';
import { getRailsContext } from './context.ts';
import { isThenable } from './isThenable.ts';

/**
 * Guide linked from the development-mode hydration-mismatch message.
 * TODO(#3894): swap to the stable error-reference URL once error codes and reference pages land.
 * @internal
 */
export const HYDRATION_MISMATCH_GUIDE_URL =
  'https://reactonrails.com/docs/building-features/debugging-hydration-mismatches';

type RootErrorHandlerKey = keyof RootErrorHandlers;

const HANDLER_KEYS = [
  'onRecoverableError',
  'onCaughtError',
  'onUncaughtError',
] as const satisfies readonly (keyof Required<RootErrorHandlers>)[];
const REACT_19_ONLY_HANDLER_KEYS = [
  'onCaughtError',
  'onUncaughtError',
] as const satisfies readonly RootErrorHandlerKey[];

// Registered through `ReactOnRails.setOptions({ rootErrorHandlers })`; module-level so both the
// core ClientRenderer and the Pro ClientSideRenderer (which imports this module from the same
// `react-on-rails` package instance) read the same registration.
let registeredHandlers: RootErrorHandlers = {};
let warnedMissingRootApi = false;
let warnedMissingReact19Callbacks = false;

/**
 * Validates and stores the user's root error callbacks. Called by `ReactOnRails.setOptions`.
 *
 * Updates MERGE per key (matching how the other `setOptions` keys update independently): passing
 * only `onCaughtError` keeps a previously registered `onRecoverableError`/`onUncaughtError`.
 * Passing an explicit `undefined` for a key clears that key; `resetRootErrorHandlers` (via
 * `ReactOnRails.resetOptions`) clears all of them. Combined with the capture-at-root-creation
 * semantics in `buildRootErrorCallbackOptions`, changes only affect roots created afterwards.
 *
 * On React runtimes without root error callback support this still stores the handlers (so a
 * later React upgrade picks them up) but warns that they will never be called.
 */
export function setRootErrorHandlers(handlers: RootErrorHandlers): void {
  const unknownKeys = Object.keys(handlers).filter(
    (key) => !HANDLER_KEYS.includes(key as RootErrorHandlerKey),
  );
  if (unknownKeys.length > 0) {
    throw new Error(
      `Invalid ReactOnRails rootErrorHandlers option: unknown key(s) ${unknownKeys.join(', ')}. ` +
        `Valid keys are: ${HANDLER_KEYS.join(', ')}.`,
    );
  }

  HANDLER_KEYS.forEach((key) => {
    const value = handlers[key];
    if (typeof value !== 'undefined' && typeof value !== 'function') {
      throw new Error(
        `Invalid ReactOnRails rootErrorHandlers option: ${key} must be a function, got ${typeof value}.`,
      );
    }
  });

  const providedKeys = HANDLER_KEYS.filter((key) => typeof handlers[key] === 'function');
  if (providedKeys.length > 0 && !supportsRootApi) {
    if (!warnedMissingRootApi) {
      console.warn(
        `[ReactOnRails] rootErrorHandlers (${providedKeys.join(', ')}) require the React 18+ root APIs ` +
          '(hydrateRoot/createRoot). The registered callbacks will never be called with the current React version.',
      );
      warnedMissingRootApi = true;
    }
  } else if (!supportsReact19RootErrorCallbacks) {
    const react19OnlyKeys = providedKeys.filter((key) =>
      (REACT_19_ONLY_HANDLER_KEYS as readonly string[]).includes(key),
    );
    if (react19OnlyKeys.length > 0 && !warnedMissingReact19Callbacks) {
      console.warn(
        `[ReactOnRails] rootErrorHandlers (${react19OnlyKeys.join(', ')}) require React 19. ` +
          'Only onRecoverableError is supported on React 18; React 19-only callbacks ' +
          `(${REACT_19_ONLY_HANDLER_KEYS.join(', ')}) will never be called with the current React version.`,
      );
      warnedMissingReact19Callbacks = true;
    }
  }

  // Per-key merge: keys absent from `handlers` keep their previous registration; keys explicitly
  // set to `undefined` are cleared.
  const merged: RootErrorHandlers = {};
  HANDLER_KEYS.forEach((key) => {
    const next = Object.prototype.hasOwnProperty.call(handlers, key)
      ? handlers[key]
      : registeredHandlers[key];
    if (typeof next === 'function') {
      merged[key] = next;
    }
  });
  registeredHandlers = merged;
}

/** Clears the registered root error callbacks. Called by `ReactOnRails.resetOptions`. */
export function resetRootErrorHandlers(): void {
  registeredHandlers = {};
  warnedMissingRootApi = false;
  warnedMissingReact19Callbacks = false;
}

/**
 * Returns a snapshot copy of the currently registered root error callbacks. A copy is returned so
 * callers cannot mutate the internal registration and bypass `setRootErrorHandlers` validation.
 */
export function getRootErrorHandlers(): RootErrorHandlers {
  return { ...registeredHandlers };
}

// A failing user callback must not break React's own error recovery, so failures are logged
// rather than propagated. Handlers are typed to return void, but an `async` handler (or one
// returning a rejecting thenable) is still assignable to that type, so adopt any returned
// thenable and swallow its rejection too — otherwise a root error could surface as an unhandled
// promise rejection from the very callback meant to report it.
function safeInvoke(
  handler: RootErrorHandler,
  key: RootErrorHandlerKey,
  error: unknown,
  errorInfo: unknown,
  context: RootErrorContext,
): void {
  const logHandlerFailure = (handlerError: unknown) => {
    console.error(
      `[ReactOnRails] The registered rootErrorHandlers.${key} callback threw while handling a root error:`,
      handlerError,
      'Original root error:',
      error,
    );
  };
  // Re-type the void-returning handler so an async handler's returned promise can be inspected.
  const invoke = handler as (e: unknown, i: unknown, c: RootErrorContext) => unknown;
  try {
    const result = invoke(error, errorInfo, context);
    if (isThenable(result)) {
      // `Promise.resolve(...)` adopts non-native thenables that may lack `.catch`.
      Promise.resolve(result).catch(logHandlerFailure);
    }
  } catch (handlerError) {
    logHandlerFailure(handlerError);
  }
}

function inDevelopmentEnv(): boolean {
  // Called from client render paths after #js-react-on-rails-context is in the DOM; keep this
  // development-only so test suites opt into reporter assertions instead of getting noisy logs.
  if (typeof document === 'undefined') {
    return false;
  }
  return getRailsContext()?.railsEnv === 'development';
}

/**
 * Mirrors React's own default `onRecoverableError` (`reportError` where available, else
 * `console.error`). Attaching a root callback replaces React's default reporting, so the
 * dev-mode logger must re-emit it itself — otherwise window-'error'-based tooling (dev overlays,
 * error trackers) goes silent in development.
 */
export function defaultReportRecoverableError(error: unknown): void {
  if (typeof globalThis.reportError === 'function') {
    globalThis.reportError(error);
  } else {
    console.error(error);
  }
}

function extractComponentStack(errorInfo: unknown): string | undefined {
  const componentStack = (errorInfo as { componentStack?: unknown } | null | undefined)?.componentStack;
  return typeof componentStack === 'string' && componentStack.length > 0 ? componentStack : undefined;
}

/**
 * Branded, supplemental development-mode line: component name, dom id, component stack (when
 * React provides one), and the debugging-guide link. Deliberately does NOT dump the error object
 * itself — the error is default-reported exactly once elsewhere (by `defaultReportRecoverableError`
 * on core paths, or by Pro's internal recoverable-error handler on chained paths).
 */
function logDevHydrationError(context: RootErrorContext, errorInfo: unknown): void {
  const componentName = context.componentName ?? 'unknown';
  const domNodeId = context.domNodeId ?? 'unknown';
  const componentStack = extractComponentStack(errorInfo);
  const componentStackSuffix = componentStack ? `\nComponent stack:${componentStack}` : '';
  console.error(
    `[ReactOnRails] Recoverable hydration error in component "${componentName}" (dom id: "${domNodeId}"). The server-rendered HTML did not match what React rendered on the client, so React threw away the server HTML and re-rendered on the client. Common Rails-specific causes and fixes: ${HYDRATION_MISMATCH_GUIDE_URL}${componentStackSuffix}`,
  );
}

type RootErrorCallbackOptions = Pick<
  ReactHydrateOptions,
  'onRecoverableError' | 'onCaughtError' | 'onUncaughtError'
>;

export interface BuildRootErrorCallbackOptionsExtras {
  /**
   * Set by Pro callers that chain their own default reporting around the returned
   * `onRecoverableError` via `chainRecoverableErrorHandlers` (see
   * `handleRecoverableError.client.ts`). When true, the dev-mode logger emits only its branded
   * supplemental line and skips `defaultReportRecoverableError`, so each recoverable error is
   * default-reported exactly once.
   *
   * New Pro hydrate paths that call `chainRecoverableErrorHandlers` should use
   * `buildRootErrorCallbackOptionsWithInternalRecoverableErrorReporting` instead of setting this
   * low-level flag directly; omitting it causes double-reporting in development.
   */
  defaultReportingHandledInternally?: boolean;
}

/**
 * Builds the `hydrateRoot`/`createRoot` error callback options for one React root, wrapping the
 * user's registered handlers so they also receive `context` (component name and dom id).
 *
 * The handlers registered at root-creation time are CAPTURED into the returned wrappers (not
 * re-read on every error): attaching a root callback permanently replaces React's default
 * reporting for that callback on that root, so a wrapper that later re-read cleared handlers
 * would silently swallow errors. Roots therefore keep the handlers they were created with;
 * re-registering affects only roots created afterwards.
 *
 * When hydrating in Rails development mode, a React on Rails-branded hydration-mismatch line
 * (component name, dom id, component stack, guide link) is attached in addition to (and before)
 * any user `onRecoverableError`. React's default reporting is preserved: the error itself is
 * still default-reported once — via `defaultReportRecoverableError` here, or by the caller's own
 * reporting when `defaultReportingHandledInternally` is set.
 *
 * Returns `{}` when nothing needs to be attached so React's default error reporting stays
 * untouched, and on React <18 (the legacy `hydrate`/`render` APIs have no such options).
 */
export function buildRootErrorCallbackOptions(
  context: RootErrorContext,
  hydrating: boolean,
  { defaultReportingHandledInternally = false }: BuildRootErrorCallbackOptionsExtras = {},
): RootErrorCallbackOptions {
  if (!supportsRootApi) {
    return {};
  }

  const options: RootErrorCallbackOptions = {};
  const { onRecoverableError, onCaughtError, onUncaughtError } = registeredHandlers;

  // Capture once at root creation; the callback does not re-check the Rails env per error.
  const logDevDefault = hydrating && inDevelopmentEnv();
  if (logDevDefault || onRecoverableError) {
    options.onRecoverableError = (error, errorInfo) => {
      if (logDevDefault) {
        if (!defaultReportingHandledInternally) {
          defaultReportRecoverableError(error);
        }
        logDevHydrationError(context, errorInfo);
      }
      if (onRecoverableError) {
        safeInvoke(onRecoverableError, 'onRecoverableError', error, errorInfo, context);
      }
    };
  }

  if (supportsReact19RootErrorCallbacks) {
    if (onCaughtError) {
      options.onCaughtError = (error, errorInfo) =>
        safeInvoke(onCaughtError, 'onCaughtError', error, errorInfo, context);
    }
    if (onUncaughtError) {
      options.onUncaughtError = (error, errorInfo) =>
        safeInvoke(onUncaughtError, 'onUncaughtError', error, errorInfo, context);
    }
  }

  return options;
}

/**
 * Pro RSC hydration wraps the returned `onRecoverableError` with an internal handler that has already
 * performed React's default recoverable-error reporting. Keep that invariant in one named helper so
 * Pro call sites do not need to remember the lower-level `defaultReportingHandledInternally` flag.
 *
 * On non-hydrate (`createRoot`) paths, `defaultReportingHandledInternally` is false, so this
 * degrades to `buildRootErrorCallbackOptions` with no reporting-behavior change.
 */
export function buildRootErrorCallbackOptionsWithInternalRecoverableErrorReporting(
  context: RootErrorContext,
  hydrating: boolean,
): RootErrorCallbackOptions {
  return buildRootErrorCallbackOptions(context, hydrating, {
    defaultReportingHandledInternally: hydrating,
  });
}
