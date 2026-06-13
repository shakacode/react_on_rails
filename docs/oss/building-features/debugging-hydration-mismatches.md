# Debugging Hydration Mismatches in Rails

A hydration mismatch happens when the HTML your Rails server rendered for a React component does not match what React renders on the client during hydration. React 18+ recovers automatically by throwing away the server HTML and re-rendering on the client — which means the page still "works," but you pay for the server render twice, the UI can visibly flicker, and the underlying bug stays hidden unless you are watching for it.

Rails apps hit a set of systematic causes that JavaScript-only frameworks rarely see, because the server render happens in a Rails request context (time zones, `current_user`, I18n, CSRF, asset hosts) while the client render does not. This guide catalogs those causes, the fix patterns, and how to observe hydration errors with React on Rails' root error callbacks.

## Observing hydration errors

### Development default

When `Rails.env.development?`, React on Rails automatically logs every recoverable hydration error with the component name, the DOM id, the component stack (when React provides one), and a link to this guide:

```text
[ReactOnRails] Recoverable hydration error in component "MyComponent" (dom id: "MyComponent-react-component-0"). ...
Component stack:
    at MyComponent
```

React's default error reporting is preserved: the error itself is still reported once via `reportError` (falling back to `console.error`), so dev overlays and other window-`'error'`-based tooling keep working. The branded line is supplemental context. On React on Rails Pro RSC hydration paths, Pro's internal handler already reports the error, so only the supplemental line is added — each error is reported exactly once either way.

No setup is required. The default logger runs in addition to any callback you register.

### Registering root error callbacks (React 19)

React's root APIs accept error callbacks, and React on Rails exposes them globally through `ReactOnRails.setOptions`. They apply to every React root that React on Rails creates (`hydrateRoot` and `createRoot`):

```js
// In your client bundle entry, before your components render
// (typically next to your ReactOnRails.register call).
import ReactOnRails from 'react-on-rails/client';

ReactOnRails.setOptions({
  rootErrorHandlers: {
    // React recovered from an error (most commonly a hydration mismatch). React 18+.
    onRecoverableError: (error, errorInfo, context) => {
      const rootContext = {
        componentName: context.componentName ?? 'unknown',
        domNodeId: context.domNodeId ?? 'unknown',
      };
      myErrorReporter.report(error, {
        level: 'warning',
        ...rootContext,
      });
    },
    // An error boundary caught an error. React 19+.
    onCaughtError: (error, errorInfo, context) => {
      const rootContext = {
        componentName: context.componentName ?? 'unknown',
        domNodeId: context.domNodeId ?? 'unknown',
      };
      myErrorReporter.report(error, { level: 'error', handled: true, ...rootContext });
    },
    // An error was NOT caught by any error boundary. React 19+.
    onUncaughtError: (error, errorInfo, context) => {
      const rootContext = {
        componentName: context.componentName ?? 'unknown',
        domNodeId: context.domNodeId ?? 'unknown',
      };
      myErrorReporter.report(error, { level: 'fatal', handled: false, ...rootContext });
    },
  },
});
```

Each callback receives React's original `(error, errorInfo)` arguments plus a `context` object that may include the React on Rails `componentName` and `domNodeId` of the affected root. Treat both fields as optional because lower-level render paths or custom mount nodes may not supply one.

Notes:

- **Register before rendering.** Each root captures the callbacks registered when it is created; register them in the same pack file where you call `ReactOnRails.register`.
- **Partial updates merge per key.** A later `setOptions({ rootErrorHandlers: { onCaughtError } })` keeps a previously registered `onRecoverableError`/`onUncaughtError`. Pass an explicit `undefined` for a key to clear just that callback; `ReactOnRails.resetOptions()` clears all of them.
- **React version support:** `onRecoverableError` requires React 18+; `onCaughtError`/`onUncaughtError` require React 19. On unsupported React versions, React on Rails still stores the registered handlers so they start working after a React upgrade, but the current runtime cannot invoke them and logs a one-time `console.warn`.
- **React on Rails Pro:** on RSC/streaming hydration paths, Pro installs an internal `onRecoverableError` for its own bookkeeping. Your callback is chained after it — both always run, and Pro's internal control-flow signals (such as the `RSCRoute` `ssr: false` bailout) are filtered out of both so they never reach your error reporter.
- **Per-component overrides** are not currently supported; the global registration above is the blessed route.

### Sentry example (and avoiding double reporting)

```js
import * as Sentry from '@sentry/react';
import ReactOnRails from 'react-on-rails/client';

ReactOnRails.setOptions({
  rootErrorHandlers: {
    onRecoverableError: (error, errorInfo, context) => {
      Sentry.captureException(error, {
        level: 'warning',
        tags: {
          ror_component: context.componentName ?? 'unknown',
          ror_dom_id: context.domNodeId ?? 'unknown',
        },
      });
    },
    onUncaughtError: (error, errorInfo, context) => {
      Sentry.captureException(error, {
        tags: {
          ror_component: context.componentName ?? 'unknown',
          ror_dom_id: context.domNodeId ?? 'unknown',
        },
      });
    },
  },
});
```

**Precedence:** an error is routed to exactly one of React's callbacks. If an error boundary catches it, it reaches `onCaughtError` (not `onUncaughtError`); otherwise it reaches `onUncaughtError`. But error boundaries themselves (like `Sentry.ErrorBoundary` or a `componentDidCatch` that reports) run **in addition to** `onCaughtError` — so if you report from both your boundary and `onCaughtError`, the same error is reported twice. Pick one layer: either report from boundaries and leave `onCaughtError` for logging/metrics, or report from `onCaughtError` and keep boundaries presentational. Similarly, `window.onerror`-based reporters may also see uncaught errors that React rethrows; deduplicate by error identity if you wire both.

## Rails-specific causes and fixes

### 1. Time, dates, and time zones (`Time.current`, `l(...)`, relative times)

**Symptom:** timestamps, "x minutes ago" labels, or date-dependent UI differ between the server HTML and the client render.

**Why:** the server renders with the Rails process time (and `Time.zone`), while the client renders with the browser clock and locale — even a one-second delta changes "rendered at" strings. Passing `Time.current.to_s` as a prop is fine; _formatting the current time independently on both sides_ is not.

```erb
<%# BAD: the view bakes a server-formatted "now" next to a component that renders its own clock %>
<%= react_component("OrderSummary", props: { renderedAt: Time.current.strftime("%H:%M:%S") }, prerender: true) %>
```

**Fixes:**

- Pass a stable value (epoch milliseconds or ISO8601 string) as a prop and format it the same way on both sides:

  ```erb
  <%= react_component("OrderSummary", props: { createdAtMs: @order.created_at.to_i * 1000 }, prerender: true) %>
  ```

- For values that _must_ differ (live clocks, relative "ago" labels), render them client-side only — initialize state to the server-safe value and update in `useEffect`:

  ```jsx
  function TimeAgo({ createdAtMs }) {
    const [label, setLabel] = useState(null); // server renders nothing dynamic
    useEffect(() => setLabel(formatTimeAgo(createdAtMs)), [createdAtMs]);
    return <span suppressHydrationWarning>{label ?? '…'}</span>;
  }
  ```

- `suppressHydrationWarning` on the single text node that legitimately differs is acceptable for things like timestamps. It only suppresses one element's text/attribute warning — do not wrap whole trees in it to silence a real bug.

### 2. `current_user`-conditional ERB around components

**Symptom:** components hydrate fine logged out but mismatch (or render the wrong UI) logged in, or vice versa.

**Why:** ERB that conditionally wraps or alters a server-rendered component bakes the login state into the server HTML, but the client bundle renders from props alone:

```erb
<%# BAD: the server HTML contains the admin toolbar, the client render doesn't know about it %>
<% if current_user&.admin? %>
  <div class="admin-frame"><%= react_component("Dashboard", prerender: true) %></div>
<% else %>
  <%= react_component("Dashboard", prerender: true) %>
<% end %>
```

**Fix — props, not ERB:** pass the user state as props and branch inside the component, so server and client render from the same inputs:

```erb
<%= react_component("Dashboard",
  props: { currentUser: { admin: current_user&.admin? || false, name: current_user&.name } },
  prerender: true) %>
```

### 3. I18n locale drift

**Symptom:** translated strings mismatch — the server renders one language, the client another.

**Why:** the server render uses `I18n.locale` from the Rails request, while the client may initialize its JS i18n library from `navigator.language`, a cookie, or a default that disagrees with Rails.

**Fix:** drive the client locale from the same source as the server. React on Rails already passes `i18nLocale` and `i18nDefaultLocale` in the `railsContext` to every render function on both server and client:

```jsx
const MyApp = (props, railsContext) => {
  i18n.locale = railsContext.i18nLocale; // same value on server and client
  return () => <App {...props} />;
};
```

See the [Internationalization guide](./i18n.md) for generating translation files.

### 4. CSRF-token-dependent props and markup

**Symptom:** forms or fetch wrappers that embed the CSRF token mismatch on every page load.

**Why:** the token from `csrf_meta_tags` is per-session/request. If the server render embeds one token into component HTML (e.g., a hidden input rendered from a prop) and the client reads a fresh one from the meta tag, the values differ. With Rails action caching, the cached server HTML can even contain another user's masked token.

**Fix:** never render the token during SSR. Read it client-side with React on Rails' helper when you actually submit:

```js
import ReactOnRails from 'react-on-rails/client';

fetch('/orders', {
  method: 'POST',
  headers: ReactOnRails.authenticityHeaders({ 'Content-Type': 'application/json' }),
  body: JSON.stringify(payload),
});
```

If a hidden field is unavoidable, populate it in `useEffect` (client-only) instead of from a server-rendered prop.

### 5. Asset hosts and URL helpers

**Symptom:** `<img>`/`<link>` attribute mismatches where the server URL has a CDN host (or different protocol) and the client-computed URL does not.

**Why:** `config.asset_host`, `default_url_options`, and request-dependent helpers (`request.base_url`) apply during the Rails-side render, while client code building URLs from relative paths or `window.location` produces different strings.

**Fixes:**

- Compute asset URLs once in Rails and pass them as props (`image_url`, not client-side string building). The [images guide](./images.md) covers webpack-side asset imports that produce identical URLs in both bundles.
- Avoid `window.location`-derived URLs during initial render; if needed, move them to `useEffect`.

### 6. Anything nondeterministic in render

`Math.random()`, `Date.now()`, `crypto.randomUUID()`, or unstable iteration order used during render guarantees a mismatch. Generate the value once on the server, pass it as a prop, or compute it in `useEffect`. For stable generated IDs across server and client, use React's `useId()` — React on Rails Pro's streaming SSR already coordinates the required `identifierPrefix` between server and client for multi-root pages.

## General fix patterns

| Pattern                        | When to use                                                                                                                                                     |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Props, not ERB**             | Any request-dependent value (user, locale, URLs, feature flags): pass it into the component instead of branching in the view around server-rendered HTML.       |
| **Render client-side only**    | Values that genuinely differ per client (clocks, viewport, `window`-derived state): initialize state server-safe, fill in via `useEffect`.                      |
| **`suppressHydrationWarning`** | A single text node/attribute that legitimately differs (e.g. a timestamp). Last resort, narrowest possible scope — it hides the warning, not the double render. |
| **`prerender: false`**         | Components that are inherently client-only; skip SSR entirely rather than fighting mismatches.                                                                  |

## Verifying a fix

1. In development, load the page and confirm the `[ReactOnRails] Recoverable hydration error...` message no longer appears.
2. Keep an `onRecoverableError` callback wired to your error reporter in production — hydration regressions are otherwise invisible (React recovers silently).
3. For ongoing protection, assert in an E2E test that no recoverable events fire on your critical pages (see `spec/dummy/e2e/playwright/e2e/react_on_rails/root_error_callbacks.spec.js` in the React on Rails repo for a working example).

## Related documentation

- [Client vs. Server Rendering](../core-concepts/client-vs-server-rendering.md)
- [React Server Rendering](../core-concepts/react-server-rendering.md)
- [Debugging React on Rails](./debugging.md)
- [Internationalization](./i18n.md)
- [React `hydrateRoot` error callback options](https://react.dev/reference/react-dom/client/hydrateRoot)
