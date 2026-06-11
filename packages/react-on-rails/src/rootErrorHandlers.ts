import type { RootErrorContext, RootErrorHandlers } from './types/index.ts';
import type { ReactHydrateOptions } from './reactApis.cts';
import { supportsRootApi, supportsReact19RootErrorCallbacks } from './reactApis.cts';
import { getRailsContext } from './context.ts';

/**
 * Guide linked from the development-mode hydration-mismatch message.
 * TODO(#3894): swap to the stable error-reference URL once error codes and reference pages land.
 */
export const HYDRATION_MISMATCH_GUIDE_URL =
  'https://reactonrails.com/docs/building-features/debugging-hydration-mismatches';

type RootErrorHandlerKey = keyof RootErrorHandlers;

const HANDLER_KEYS: readonly RootErrorHandlerKey[] = [
  'onRecoverableError',
  'onCaughtError',
  'onUncaughtError',
];

// Registered through `ReactOnRails.setOptions({ rootErrorHandlers })`; module-level so both the
// core ClientRenderer and the Pro ClientSideRenderer (which imports this module from the same
// `react-on-rails` package instance) read the same registration.
let registeredHandlers: RootErrorHandlers = {};

/**
 * Validates and stores the user's root error callbacks. Called by `ReactOnRails.setOptions`.
 * On React runtimes without root error callback support this still stores the handlers (so a
 * later React upgrade picks them up) but warns that they will never be called.
 */
export function setRootErrorHandlers(handlers: RootErrorHandlers): void {
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
    console.warn(
      `[ReactOnRails] rootErrorHandlers (${providedKeys.join(', ')}) require the React 18+ root APIs ` +
        '(hydrateRoot/createRoot). The registered callbacks will never be called with the current React version.',
    );
  } else if (!supportsReact19RootErrorCallbacks) {
    const react19OnlyKeys = providedKeys.filter((key) => key !== 'onRecoverableError');
    if (react19OnlyKeys.length > 0) {
      console.warn(
        `[ReactOnRails] rootErrorHandlers (${react19OnlyKeys.join(', ')}) require React 19. ` +
          'Only onRecoverableError is supported on React 18; the other registered callbacks will never be called.',
      );
    }
  }

  registeredHandlers = { ...handlers };
}

/** Clears the registered root error callbacks. Called by `ReactOnRails.resetOptions`. */
export function resetRootErrorHandlers(): void {
  registeredHandlers = {};
}

/** Returns the currently registered root error callbacks. */
export function getRootErrorHandlers(): RootErrorHandlers {
  return registeredHandlers;
}

// A throwing user callback must not break React's own error recovery, so failures are logged
// rather than propagated.
function safeInvoke(
  key: RootErrorHandlerKey,
  error: unknown,
  errorInfo: unknown,
  context: RootErrorContext,
): void {
  const handler = registeredHandlers[key];
  if (!handler) {
    return;
  }
  try {
    handler(error, errorInfo, context);
  } catch (handlerError) {
    console.error(`[ReactOnRails] The registered rootErrorHandlers.${key} callback threw:`, handlerError);
  }
}

function inDevelopmentEnv(): boolean {
  // `getRailsContext` reads from the DOM; this builder only runs client-side, but guard anyway so
  // an unexpected server-side call cannot throw.
  if (typeof document === 'undefined') {
    return false;
  }
  return getRailsContext()?.railsEnv === 'development';
}

function logDevHydrationError(context: RootErrorContext, error: unknown): void {
  const componentName = context.componentName || 'unknown';
  const domNodeId = context.domNodeId || 'unknown';
  console.error(
    `[ReactOnRails] Recoverable hydration error in component "${componentName}" (dom id: "${domNodeId}"). The server-rendered HTML did not match what React rendered on the client, so React threw away the server HTML and re-rendered on the client. Common Rails-specific causes and fixes: ${HYDRATION_MISMATCH_GUIDE_URL}`,
    error,
  );
}

type RootErrorCallbackOptions = Pick<
  ReactHydrateOptions,
  'onRecoverableError' | 'onCaughtError' | 'onUncaughtError'
>;

/**
 * Builds the `hydrateRoot`/`createRoot` error callback options for one React root, wrapping the
 * user's registered handlers so they also receive `context` (component name and dom id).
 *
 * When hydrating in Rails development mode, a React on Rails-branded hydration-mismatch logger is
 * attached in addition to (and before) any user `onRecoverableError`, replacing React's bare
 * console line with an actionable message linking to the debugging guide.
 *
 * Returns `{}` when nothing needs to be attached so React's default error reporting stays
 * untouched, and on React <18 (the legacy `hydrate`/`render` APIs have no such options).
 */
export function buildRootErrorCallbackOptions(
  context: RootErrorContext,
  hydrating: boolean,
): RootErrorCallbackOptions {
  if (!supportsRootApi) {
    return {};
  }

  const options: RootErrorCallbackOptions = {};

  const logDevDefault = hydrating && inDevelopmentEnv();
  if (logDevDefault || registeredHandlers.onRecoverableError) {
    options.onRecoverableError = (error, errorInfo) => {
      if (logDevDefault) {
        logDevHydrationError(context, error);
      }
      safeInvoke('onRecoverableError', error, errorInfo, context);
    };
  }

  if (supportsReact19RootErrorCallbacks) {
    if (registeredHandlers.onCaughtError) {
      options.onCaughtError = (error, errorInfo) => safeInvoke('onCaughtError', error, errorInfo, context);
    }
    if (registeredHandlers.onUncaughtError) {
      options.onUncaughtError = (error, errorInfo) =>
        safeInvoke('onUncaughtError', error, errorInfo, context);
    }
  }

  return options;
}
