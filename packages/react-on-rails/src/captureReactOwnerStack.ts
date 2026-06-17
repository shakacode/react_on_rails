import * as React from 'react';

/**
 * React's `captureOwnerStack` (added in React 19.1) returns the "owner stack" for the component
 * currently rendering or erroring — the chain of components that created the failing element, e.g.
 *
 *   at Avatar
 *   at PostCard
 *   at PostList
 *
 * This is dramatically more useful for debugging than a minified JS stack because it names the
 * components a developer actually wrote.
 *
 * IMPORTANT dev-build-on-server / production constraints (verified against React 19.0.x and 19.2.x):
 *
 * 1. `captureOwnerStack` is exported **only from React's development build**. In a production build
 *    the export does not exist (`typeof React.captureOwnerStack !== 'function'`), so the guard below
 *    makes this a strict no-op in production — there is no capture, no call, and no behavioral change.
 *    This is asserted by tests.
 * 2. It is exported only from React **>= 19.1**. On React 19.0 and earlier the export is `undefined`
 *    even in dev builds, so the same guard covers the version requirement without needing to parse
 *    `React.version`.
 * 3. It returns a meaningful string **only when called synchronously while React is rendering or
 *    handling an error** (e.g. inside an `onError`/`onCaughtError`/`onUncaughtError`/`onShellError`
 *    callback). Called outside that window it returns `null`. Post-hoc formatting (for example the
 *    Ruby layer, or a `try/catch` around `renderToString` after it has already thrown) cannot
 *    capture it — which is why capture must happen JS-side inside the error callback.
 *
 * On the server this only yields output when React's **development** build runs in the SSR bundle.
 * Production SSR bundles run React's production build and therefore get the no-op behavior above;
 * that is the documented, intended outcome for production.
 *
 * @returns React's owner stack string verbatim (it typically begins with a newline and indented
 *   `at <Component>` frames) when a non-empty one is available, otherwise `undefined`. The
 *   whitespace is preserved intentionally so callers can embed it directly under a label. Never
 *   throws.
 */
// `captureOwnerStack` is only present on React's dev build for React >= 19.1. Accessing it through a
// typed-as-optional view keeps this compiling against the broad `react >= 16` peer range.
const reactWithOwnerStack = React as typeof React & {
  captureOwnerStack?: () => string | null;
};

/**
 * Whether React's dev-only `captureOwnerStack` API exists in the current build — i.e. React >= 19.1
 * running its **development** build. Used to gate dev-mode owner-stack logging so that on older
 * React (or any production build), where the API is absent, React's own default error reporting is
 * left untouched (issue #3887).
 */
export function isOwnerStackSupported(): boolean {
  return typeof reactWithOwnerStack.captureOwnerStack === 'function';
}

export default function captureReactOwnerStack(): string | undefined {
  if (typeof reactWithOwnerStack.captureOwnerStack !== 'function') {
    return undefined;
  }

  try {
    const ownerStack = reactWithOwnerStack.captureOwnerStack();
    if (typeof ownerStack === 'string' && ownerStack.trim().length > 0) {
      return ownerStack;
    }
  } catch {
    // captureOwnerStack must never break error reporting; swallow any unexpected failure.
  }

  return undefined;
}
