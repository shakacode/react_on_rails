# View Transitions with React on Rails (Experimental)

> **⚠️ Experimental — not officially supported.** This entire page is a canary recipe. The browser
> [View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API) is still
> evolving, React's component-level `<ViewTransition>` API is canary-only, and this recipe may change or
> break without notice. Nothing on this page is covered by React on Rails' support policy or semver
> guarantees. React Server Components are explicitly out of scope here. Tracked in
> [#3888](https://github.com/shakacode/react_on_rails/issues/3888).

This page shows how to use the **browser-native** `document.startViewTransition()` API with components
rendered by `react_component` — first client-side-only (CSR), then with server rendering plus hydration
(SSR-hydrate) — and how it interacts with Turbo Drive's own view-transition support.

## What this covers (Experimental)

- Wrapping React state updates (and client-side route updates) in `document.startViewTransition()`.
- What does and does not work when the component is server-rendered and hydrated.
- The Turbo Drive interplay: Turbo's cross-page transitions vs React-driven in-page transitions.
- A tiny flagged demo in the gem's dummy app.

It deliberately does **not** cover React's canary `<ViewTransition>` component / `addTransitionType`
API beyond a status note (see below), and it does not cover React Server Components.

## Browser support and feature detection (Experimental)

Same-document view transitions (`document.startViewTransition`) ship in Chrome/Edge 111+, Safari 18+,
and recent Firefox releases, but you must always feature-detect — unsupported browsers simply apply the
DOM update without animation:

```js
function withViewTransition(applyUpdate) {
  if (typeof document.startViewTransition === 'function') {
    document.startViewTransition(applyUpdate);
  } else {
    applyUpdate(); // graceful fallback: same update, no animation
  }
}
```

## CSR recipe (Experimental)

`document.startViewTransition(callback)` snapshots the current page, runs your `callback` to mutate the
DOM, snapshots the result, and animates between the two snapshots.

The catch for React: React 18/19 **batches state updates and commits asynchronously**, but the browser
expects the DOM to be fully updated when your callback returns. Wrap the state update in
[`flushSync`](https://react.dev/reference/react-dom/flushSync) so React commits synchronously inside
the callback:

```tsx
import React, { useState } from 'react';
import { flushSync } from 'react-dom';

const Panel = () => {
  const [expanded, setExpanded] = useState(false);

  const toggle = () => {
    const applyUpdate = () => {
      flushSync(() => {
        setExpanded((prev) => !prev);
      });
    };

    if (typeof document.startViewTransition === 'function') {
      document.startViewTransition(applyUpdate);
    } else {
      applyUpdate();
    }
  };

  return (
    <div>
      <button type="button" onClick={toggle}>
        Toggle
      </button>
      <div id="vt-panel" className={expanded ? 'panel panel--expanded' : 'panel'}>
        …
      </div>
    </div>
  );
};
```

Give the animated element a `view-transition-name` so the browser can pair its old/new snapshots, and
optionally style the transition pseudo-elements:

```css
#vt-panel {
  view-transition-name: vt-panel;
}

::view-transition-old(vt-panel),
::view-transition-new(vt-panel) {
  animation-duration: 300ms;
}
```

This works with plain `react_component("Panel", prerender: false)` — no React on Rails configuration is
involved; the recipe is entirely inside your component and CSS.

### Client-side route changes (Experimental)

The same pattern wraps client-side navigation inside a React root: call your router's navigate function
inside the `startViewTransition` callback (with `flushSync` if the router commits asynchronously). If
you use React Router, prefer its built-in integration (`<Link viewTransition>` /
`useViewTransitionState`) instead of hand-rolling — see [React Router](./react-router.md). These
router-level integrations are experimental in the same sense as the rest of this page.

### CSR pitfalls (Experimental)

- **`flushSync` is a forced synchronous render.** Keep the transitioned update small; large trees will
  jank inside the transition callback.
- **One transition at a time.** Starting a new same-document transition skips any transition already
  running. Rapid clicks fall back to the final state — that is by design, but don't queue your own.
- **Duplicate `view-transition-name`s abort the transition.** Each name must be unique on the page at
  snapshot time (watch out for lists; derive names from item ids if you animate list items).

## SSR-hydrate recipe (Experimental)

The same component works with `prerender: true` (server rendering + client hydration) as long as you
follow these rules:

- **Only touch the API in event handlers or effects.** `document` does not exist in the server-side
  rendering environment (ExecJS or the Pro Node renderer). Never call or feature-detect
  `document.startViewTransition` at module scope or during render of a server-rendered component.
- **Don't branch markup on feature support during the initial render.** The server cannot know what the
  browser supports, so support-dependent markup causes hydration mismatches. Feature-detect inside the
  handler (as above), or stash support in state from a `useEffect` after mount.
- **`view-transition-name` in server-rendered HTML is safe.** It is plain CSS — it has no effect until
  a transition starts, and it does not affect hydration.
- **The initial paint is not transitioned.** View transitions animate _updates_; server-rendered HTML
  appearing and React hydrating it produce no transition (and hydration itself must not be wrapped in
  one). Only post-hydration interactions animate.

In short: SSR-hydrate works today with the browser API because the transition only ever runs on the
client, after hydration, inside user-triggered handlers.

## React canary `<ViewTransition>` status (Experimental)

React's component-level API (`<ViewTransition>`, `addTransitionType`) is **canary-only** and is not
part of this recipe. React 19.2 shipped groundwork that matters for the future here — SSR Suspense
reveal batching, and the `useId` prefix change to `_r_` so generated ids are valid
`view-transition-name` values — but running a canary React build under React on Rails is untested and
unsupported. This page intentionally uses only the browser API, which works on stable React 19.

## Turbo Drive interplay (Experimental)

> **⚠️ Turbo claims pending maintainer review.** The claims in this section follow Turbo's documented
> behavior and React on Rails' Turbo event wiring, but they have not yet been verified end-to-end in
> the dummy app. Treat them as provisional until a maintainer confirms them.

Rails apps using [Turbo Drive](https://turbo.hotwired.dev) have a second, independent view-transition
system: Turbo can wrap its **cross-page** (page-to-page) renders in `document.startViewTransition` when
the page opts in via:

```html
<meta name="view-transition" content="same-origin" />
```

How this relates to React-driven transitions:

- **Two different scopes.** Turbo Drive transitions animate whole-page navigations (Turbo replaces the
  `<body>`); React-driven transitions (this page's recipe) animate state/route updates **inside** a
  mounted React root. Use Turbo's mechanism for cross-page continuity and the React recipe for in-page
  interactions — they solve different problems.
- **React state does not survive a Turbo visit.** React on Rails listens to `turbo:before-render` /
  `turbo:render` and unmounts components before Turbo swaps the body, then re-mounts them on the new
  page (see `packages/react-on-rails/src/pageLifecycle.ts`). Any cross-page visual continuity must come
  from Turbo's transition (matching `view-transition-name`s in the old and new HTML), not from React.
- **They must not run simultaneously.** Browsers allow only one active same-document transition;
  starting another skips the one in progress. Avoid triggering a React `startViewTransition` from code
  that runs during a Turbo visit (e.g., in `turbo:before-render`/`turbo:render` handlers or unmount
  paths). In practice this is easy to satisfy: trigger React transitions only from user interactions.
- **Turbo's preview cache can confuse pairing.** Turbo may first render a cached preview of the next
  page and then the fresh response. Elements with `view-transition-name` that appear in both the old
  page and the preview can pair unexpectedly or abort (duplicate names). Test with the cache in play
  before shipping, or disable preview for transitioned pages
  (`<meta name="turbo-cache-control" content="no-preview">`).

## In-repo demo (Experimental)

The gem's dummy app contains a minimal CSR demo of this recipe, inert unless you opt in with an
environment flag:

- Component: `react_on_rails/spec/dummy/client/app/startup/ViewTransitionsDemo.client.tsx`
- View: `react_on_rails/spec/dummy/app/views/pages/view_transitions_demo.html.erb`
- Route: defined in `react_on_rails/spec/dummy/config/routes.rb` only when `VIEW_TRANSITIONS_DEMO=true`

Run it from a React on Rails checkout:

```bash
cd react_on_rails/spec/dummy
VIEW_TRANSITIONS_DEMO=true bin/dev
# then open http://localhost:3000/view_transitions_demo
```

With the flag unset, the route does not exist and the demo page is unreachable.

## Promote-to-supported checklist (Experimental)

This page graduates from experimental to supported only when all of the following are true:

- [ ] React's `<ViewTransition>` / `addTransitionType` ship in a **stable** React release, and React on
      Rails' supported React range includes that release.
- [ ] The Turbo-interplay claims above are verified end-to-end in the dummy app (Turbo is enabled
      there) by a maintainer, and the "pending maintainer review" banner is removed.
- [ ] The CSR and SSR-hydrate recipes are re-validated against the then-current React on Rails major,
      and the dummy demo is either covered by a spec/E2E test or promoted out of its env flag.
- [ ] Browser support is re-confirmed as Baseline for same-document transitions across the browsers the
      docs target (re-check Firefox).
- [ ] Experimental banners are removed from this page and the change is announced in the CHANGELOG.

**Owner:** maintainers — tracked in [#3888](https://github.com/shakacode/react_on_rails/issues/3888).
Re-check cadence: each React minor release (or quarterly, whichever comes first).
