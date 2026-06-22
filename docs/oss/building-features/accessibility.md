# Accessibility (a11y)

This page covers accessibility problems caused by the Rails/React boundary in React on Rails and React on Rails Pro apps. It is not a general accessibility handbook. For WCAG rules, ARIA patterns, keyboard behavior, and screen reader basics, use [General Web Accessibility References](#general-web-accessibility-references).

**Target: WCAG 2.2 Level AA.** See the [W3C quick reference](https://www.w3.org/WAI/WCAG22/quickref/) for the criteria.

These React on Rails terms appear throughout this page:

- A **React island** is one React component mounted inside a Rails-rendered page.
- A **mount point** is the DOM container where React on Rails mounts that island.
- `react_component` is the Rails view helper that writes the mount point and passes props to your component.
- `prerender: true` tells React on Rails to render the component HTML on the server; `prerender: false` leaves only the container until JavaScript loads.
- **SSR** means server-side rendering: the server sends real HTML in the first response.
- **Hydration** is when React attaches client-side behavior to HTML that was rendered on the server.
- `stream_react_component` is the React on Rails Pro helper for streaming server-rendered HTML as it becomes ready.
- A **render-function** is JavaScript registered with React on Rails to render a component and receive request context.
- `railsContext` is request-level data that React on Rails passes to render-functions, such as locale.
- **React Server Components (RSC)** are React components that render on the server and do not run browser effects.

## Contents

**Framework-specific**

1. [Rails shell vs. React island responsibilities](#1-rails-shell-vs-react-island-responsibilities)
2. [The `react_component` accessibility contract](#2-the-react_component-accessibility-contract)
3. [SSR and hydration](#3-ssr-and-hydration)
4. [Stable IDs in an SSR context](#4-stable-ids-in-an-ssr-context)
5. [Pro streaming SSR and Suspense](#5-pro-streaming-ssr-and-suspense)
6. [React Server Components in React on Rails Pro](#6-react-server-components-in-react-on-rails-pro)
7. [Routing, page transitions, and focus](#7-routing-page-transitions-and-focus)
8. [Rails + React forms](#8-rails--react-forms)
9. [Flash messages, toasts, and async status](#9-flash-messages-toasts-and-async-status)
10. [Fragment caching and accessibility freshness](#10-fragment-caching-and-accessibility-freshness)
11. [Internationalization through railsContext / RSC](#11-internationalization-through-railscontext--rsc)
12. [Testing in React on Rails](#12-testing-in-react-on-rails)
13. [Hydration and accessibility debugging](#13-hydration-and-accessibility-debugging)

**General references**

- [General Web Accessibility References](#general-web-accessibility-references)

---

## 1. Rails shell vs. React island responsibilities

When Rails renders the page shell and React renders islands inside it, screen readers get one combined page. If both sides add the same page structure, users hear duplicate landmarks, duplicate headings, or missing context.

Fix this by deciding which side owns each page-level item.

| Concern                                              | Usually owned by                                     |
| ---------------------------------------------------- | ---------------------------------------------------- |
| `<html lang>`, `dir`, `<title>`, meta                | Rails layout (ERB)                                   |
| Landmarks: `<header>`, `<nav>`, `<main>`, `<footer>` | Rails layout, usually                                |
| Skip links                                           | Rails layout                                         |
| The single `<h1>`                                    | Decide explicitly: layout or island                  |
| Flash messages container + live region               | Rails layout, with React writing into it when needed |
| Interactive widgets, focus management, live updates  | React islands                                        |

Use `react_component` when Rails should place a React island on the page:

```erb
<%= react_component(
  "ProductSummary",
  props: { product_id: @product.id },
  prerender: true
) %>
```

Guidance:

- If the Rails layout already has `<main>`, the island should not render another `<main>`.
- Pick one owner for the page `<h1>`. If the island renders it, the layout should not.
- Use `prerender: true` for content that must exist in the first HTML response.
- Use `prerender: false` only for client-only widgets where an empty first response is acceptable.

---

## 2. The `react_component` accessibility contract

When you call `react_component`, React on Rails writes a container element. React then mounts your component inside that container as its children. The container stays in the DOM and in the accessibility tree.

If you omit an `id`, React on Rails auto-assigns one to the container.

```erb
<%= react_component("AccountMenu", props: { signed_in: true }) %>
```

- **Wrapper element and `tag`.** The default container is a `<div>`. That is usually fine because a plain `<div>` has no landmark or widget meaning. If the container itself needs attributes, pass them through `html_options`. To change the container element, put `tag` inside `html_options`. (The `tag` option applies to `react_component` only — the `react_component_hash` helper always renders a `<div>` container.)

```erb
<%= react_component(
  "InlineBadge",
  props: { text: "New" },
  id: "account-badge",
  html_options: { tag: "span", class: "badge" }
) %>
```

- **The real wrapper pitfall is duplicate semantics.** Do not put a landmark role on the container if your component already renders the same landmark inside it.

Before: this creates two navigation landmarks.

```erb
<%= react_component(
  "HeaderNav",
  props: {},
  html_options: { role: "navigation", "aria-label": "Main" }
) %>
```

```jsx
export default function HeaderNav() {
  return <nav aria-label="Main">...</nav>;
}
```

After: keep the container neutral and let the component own the landmark.

```erb
<%= react_component("HeaderNav", props: {}) %>
```

```jsx
export default function HeaderNav() {
  return <nav aria-label="Main">...</nav>;
}
```

- **Set the container `id` with the top-level `id:` option, not inside `html_options`.** React on Rails overwrites `html_options[:id]` with the value from the top-level `id:` option (or an auto-generated id), so an `id` placed inside `html_options` is ignored. Put `class`, `style`, `role`, and `aria-*` in `html_options`; put `id` at the top level. (`role="status"` already implies `aria-live="polite"`, so it is not repeated here.)

```erb
<%= react_component(
  "SaveStatus",
  props: { state: "saving" },
  id: "save-status",
  html_options: { role: "status" }
) %>
```

- **Keep container IDs and internal IDs separate.** The container `id` comes from the top-level `id:` option (or is auto-generated). Your component still needs its own stable IDs for labels, descriptions, and ARIA relationships inside the island. See section 4.
- **Server and client must agree.** Do not set a wrapper role or ARIA attribute in ERB that the hydrated React tree contradicts.

The markup inside the component follows normal web accessibility rules: native elements first, labels for inputs, names for icon-only buttons, visible focus, and correct keyboard behavior. For those rules, use [WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/) and [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility).

---

## 3. SSR and hydration

When you use `prerender: false`, the first HTML response contains the container but not the component content. Screen readers and no-JS users get an empty island until the JavaScript bundle loads.

Fix this by using `prerender: true` for content-bearing islands.

```erb
<%= react_component("ArticleBody", props: { article_id: @article.id }, prerender: true) %>
<%= react_component("ColorSchemeToggle", props: {}, prerender: false) %>
```

React hydration then attaches event handlers and client behavior to the server-rendered HTML. The accessibility risk is that users can reach HTML before hydration is done.

Guidance:

- Keep server and client output deterministic. Do not use `Date.now()`, `Math.random()`, browser-only checks, or client-only locale detection in render output.
- Pass request data from Rails as props, or read it from `railsContext` in a render-function, so server and client render the same text.
- Do not hide hydration warnings with `suppressHydrationWarning` unless you have confirmed the mismatch is harmless.
- A prerendered button is announced as a button before its `onClick` works. For critical actions, use a real form submit that works without JavaScript, or render an honest pending state until hydration finishes.
- Do not move focus in a mount effect on first page load. Move focus only after a user action, such as route navigation or opening a dialog.

For React's general hydration behavior, see [`hydrateRoot`](https://react.dev/reference/react-dom/client/hydrateRoot).

---

## 4. Stable IDs in an SSR context

When an input points to a label or error message by `id`, the `id` must be the same on the server and client. It must also be unique on the page. If it changes during hydration, screen readers can lose the label or description.

This is easy to break in React on Rails because the same component can be mounted more than once with `react_component`.

Do not hard-code IDs inside reusable islands. Do not generate IDs with `Math.random()` or a module-level counter.

Use React's [`useId`](https://react.dev/reference/react/useId) for IDs that must match SSR and hydration.

```jsx
import { useId } from 'react';

export default function EmailField({ error }) {
  const id = useId();
  const errorId = `${id}-error`;

  return (
    <>
      <label htmlFor={id}>Email</label>
      <input
        id={id}
        type="email"
        aria-invalid={error ? 'true' : undefined}
        aria-describedby={error ? errorId : undefined}
      />
      {error && <p id={errorId}>{error}</p>}
    </>
  );
}
```

**With the open-source package, `useId` is not enough when you mount the same component more than once on a page.** `useId` keeps an id stable between the server render and hydration _within one mount_, but React only guarantees uniqueness _across_ separate roots when each root is given a distinct [`identifierPrefix`](https://react.dev/reference/react-dom/client/hydrateRoot#parameters). The open-source React on Rails package does not set a per-mount `identifierPrefix`, so two mounts of the same component can produce the same `useId` value (for example `«r0»`) and collide. (React on Rails Pro sets `identifierPrefix` to the container DOM id automatically only on the default RSC-provider path — that is, when RSC support is enabled — so `useId` is already safe there. Every other path, including `stream_react_component` _without_ RSC support, has the same caveat as the open-source package.)

When a component can appear more than once on a page, pass a unique prefix into it — the container `id` you set with the top-level `id:` option (section 2) works well — and build your ARIA ids from that. Use the same value for `id:` and the prefix prop so they stay in sync:

```erb
<%# Each mount gets a unique id; the same value is threaded in as the prefix prop.
    Prop keys are passed through verbatim (React on Rails does not camelize them),
    so use the same `idPrefix` key the component reads. %>
<%= react_component("EmailField", props: { idPrefix: "signup-email" }, id: "signup-email") %>
<%= react_component("EmailField", props: { idPrefix: "contact-email" }, id: "contact-email") %>
```

```jsx
export default function EmailField({ idPrefix, error }) {
  const errorId = `${idPrefix}-email-error`;
  // ...use `${idPrefix}-email` for the input id, etc.
}
```

---

## 5. Pro streaming SSR and Suspense

When you use `stream_react_component`, React on Rails Pro can send server-rendered HTML in pieces as work finishes. Screen readers still read the DOM in logical order, not your loading plan.

Fix this by making each streamed `Suspense` boundary match the reading order of the page.

Guidance:

- Keep streamed chunks in the same order a user should read them.
- Mark loading regions as busy with `aria-busy` while content is still pending.
- Do not wrap a large streamed subtree (such as a full result list) in `aria-live` — that queues the entire subtree for announcement and overwhelms screen-reader users. Instead, announce a short message like "Results loaded" in the page's shared live region (section 9) once the content commits.
- Reserve `aria-live` for small, deliberately announced status text, and set that text after the real content commits so the announcement is not missed or repeated.
- Do not move focus when a late chunk arrives. Preserve the user's current focus.
- Mark skeleton placeholders as decorative.

```jsx
function ResultsRegion({ loading, children }) {
  // `aria-busy` signals loading; a plain <div> avoids implying a landmark.
  return (
    <div aria-busy={loading ? 'true' : undefined}>
      {loading ? <div aria-hidden="true" className="skeleton" /> : children}
    </div>
  );
}
```

---

## 6. React Server Components in React on Rails Pro

When part of the page is a React Server Component, that part can render HTML but cannot run browser effects. If focus movement, keyboard handlers, or live-region updates live only in a server component, they will not run in the browser.

Fix this by putting browser behavior in client components and keeping server components for static, semantic HTML.

Guidance:

- Put focus management, keyboard handlers, live-region updates, and effect-driven ARIA in client components.
- Use server components for headings, articles, navigation markup, and other static content that does not need hydration.
- Use Rails-owned data consistently. If an accessible name depends on locale, permissions, or user state, make sure the server-rendered content and any hydrated client component receive the same value.
- If a form returns server-side validation errors, surface those errors with the same accessible pattern described in section 8.

The accessibility guidance above is what is specific to the server/client split. For the RSC helper names, the config flag that enables RSC mode, and how to register server vs. client components — which are version-dependent — see the [React on Rails Pro React Server Components docs](../../pro/react-server-components/index.md).

---

## 7. Routing, page transitions, and focus

When a React island changes routes without a full page load, the browser does not automatically announce a new page. Focus may stay on a link or button from the old view.

Fix this with the standard SPA pattern:

- Update `document.title`.
- Move focus to the new view's `<h1 tabIndex={-1}>` or `<main tabIndex={-1}>`.
- Write the new page name into one visually hidden `aria-live="polite"` route announcer.

What is specific to React on Rails is where this code lives.

- If React Router, TanStack Router, or another client router runs inside an island, hook this behavior into that router's navigation events.
- If Rails or Turbo changes the page, run the same behavior after the new page loads. For Turbo, that usually means the `turbo:load` event.
- Keep one route announcer for the page. Do not create one announcer per island.
- Make sure skip links still point to the current main content after navigation.

A minimal announcer inside a router island, reusing the shared live region from section 9:

```jsx
// Inside a React Router / TanStack Router island
function RouteAnnouncer() {
  const { pathname } = useLocation(); // or the router's location hook

  useEffect(() => {
    const region = document.getElementById('app-live-region');
    if (region) {
      // Clear first, then set on the next tick so the change is announced
      region.textContent = '';
      requestAnimationFrame(() => {
        region.textContent = `Navigated to ${document.title}`;
      });
    }
    document.querySelector('main')?.focus(); // <main tabIndex={-1}>
  }, [pathname]);

  return null;
}
```

For the general SPA pattern, see [Gatsby's user testing of accessible client-side routing](https://www.gatsbyjs.com/blog/2019-07-11-user-testing-accessible-client-routing/) and [Deque's SPA accessibility tips](https://www.deque.com/blog/accessibility-tips-in-single-page-applications/).

---

## 8. Rails + React forms

When Rails validates a form on the server and React renders the fields, errors can land in the wrong place or lose their label relationship.

Fix this by passing Rails errors into the island once, then rendering one accessible error UI in React.

Guidance:

- Map the Rails `errors` hash to field-level errors and one top-of-form summary.
- Do not render the same error once in ERB and again in React.
- Keep each label connected to its input with matching `for` and `id`.
- Keep `aria-describedby` pointed at the error message after hydration.
- If the server prerenders an error state, the hydrated React output must use the same IDs and text.
- If the form island can be mounted more than once on a page, pass a unique `idPrefix` prop (section 4) instead of relying on `useId` alone, so the OSS path does not produce colliding field IDs.

```jsx
function NameField({ idPrefix, value, error }) {
  const id = `${idPrefix}-name`;
  const errorId = `${id}-error`;

  return (
    <div>
      <label htmlFor={id}>Name</label>
      <input
        id={id}
        name="name"
        defaultValue={value}
        aria-invalid={error ? 'true' : undefined}
        aria-describedby={error ? errorId : undefined}
      />
      {error && <p id={errorId}>{error}</p>}
    </div>
  );
}
```

For the general form rules, see the [WAI forms tutorial](https://www.w3.org/WAI/tutorials/forms/).

---

## 9. Flash messages, toasts, and async status

When Rails flash messages and React toasts each create their own live region, screen readers may announce the same message twice or miss one.

Fix this by creating one persistent live region in the Rails layout. Rails can render the first message there, and React islands can update the same region later.

```erb
<div id="app-live-region" role="status" aria-atomic="true"></div>
```

`role="status"` already implies `aria-live="polite"`, so that is not repeated. `aria-atomic="true"` is set explicitly so screen readers announce the whole message rather than only the changed text node.

Guidance:

- The live region should exist before the message text is inserted.
- When updating the region, clear it first and set the new text on the next tick (`region.textContent = ''; requestAnimationFrame(() => { region.textContent = message; })`). Some older screen readers (e.g. JAWS, NVDA in certain modes) do not announce text injected into a region that was empty on first load; the clear-then-set pattern avoids that silent failure.
- Use the same region for Rails flash, React toasts, and async status such as "Saving", "Saved", and "Failed".
- Use `role="alert"` only for urgent messages that require interruption.
- Do not auto-dismiss messages before users have time to read them.

For general live-region behavior, see [MDN on live regions](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/ARIA_Live_Regions).

---

## 10. Fragment caching and accessibility freshness

When Rails caches HTML around a `react_component` call, it can also cache accessible names, ARIA attributes, and visible controls. If the cache key is too broad, screen readers get stale or wrong information.

Fix this by including every accessibility-affecting input in the cache key, or by keeping that state out of the cached fragment.

Cache keys must include anything that affects:

- Locale and text direction.
- Translated visible text and accessible names.
- Permissions and role-based controls.
- User-specific labels, such as "Log out, Jane".
- Feature-flagged controls and their labels.

Do not cache per-request or interactive ARIA state:

- `aria-expanded`
- `aria-pressed`
- `aria-selected`
- `aria-current`
- live-region text

Before caching a fragment, ask: does any label, role, ARIA attribute, or visible control depend on user, request, locale, or feature flag state? If yes, put that input in the key or render that piece outside the cache.

---

## 11. Internationalization through railsContext / RSC

When Rails and React choose locale or direction separately, the server HTML can say one thing and the hydrated client can replace it with another. Screen readers may pronounce text with the wrong language rules, and React may hit hydration mismatches.

Fix this by using one request-level source for locale and direction.

Guidance:

- Set `<html lang>` and `dir` in the Rails layout from the request locale.
- Use `railsContext` in render-functions when a component needs request-level data such as locale.
- Pass the same locale and direction into islands that branch on language or layout direction.
- Apply the same rule to RSC output: server-rendered content and hydrated client components should use the same locale and direction.
- Do not re-detect locale on the client if Rails already knows it.

In production, prefer a single source of truth for direction — many i18n setups
expose it (for example `rails-i18n` locale files carry direction metadata), and a
shared helper avoids duplicating a language list. The snippet below is a minimal,
**non-exhaustive** illustration; the `rtl_subtags` list omits many RTL locales
(`ks`, `ku-Arab`, `pa-Arab`, …) and should not be copied verbatim into an app
that needs broad coverage.

```erb
<%# Minimal example only — derive `dir` from your i18n metadata in real apps. %>
<% rtl_subtags = %w[ar he fa ur yi ug dv ps sd ckb] %>
<% primary_subtag = I18n.locale.to_s.split(/[-_]/).first  # handles ar-EG and ar_EG %>
<%= react_component(
  "LocalizedNav",
  props: {
    locale: I18n.locale.to_s,
    dir: rtl_subtags.include?(primary_subtag) ? "rtl" : "ltr"
  },
  prerender: true
) %>
```

For general RTL and `dir` behavior, see [MDN on `dir`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/dir).

---

## 12. Testing in React on Rails

When a React on Rails page uses SSR, the first HTML response and the hydrated browser page can have different accessibility bugs. Testing only the hydrated React tree misses the no-JS baseline.

Fix this by testing both states.

Guidance:

- Run automated checks against the server-rendered HTML from `prerender: true`.
- Run automated checks again after hydration in a real browser.
- Test important pages with JavaScript disabled. This confirms the accessible baseline exists before hydration.
- For `stream_react_component`, wait for the streamed content to finish before asserting.
- For forms, test the server-rendered error state and the hydrated error state.
- If strict CSP blocks injected axe scripts or streaming test scripts, fix the test setup rather than weakening production accessibility checks.

Use tools such as `jest-axe`, `vitest-axe`, `axe-core`, `pa11y`, Lighthouse, Capybara system tests, or Playwright with `@axe-core/playwright`. Add manual keyboard and screen reader passes for streaming, navigation, dialogs, and live-region flows.

---

## 13. Hydration and accessibility debugging

When an accessibility bug appears only after the JavaScript bundle loads, debug the Rails output and the hydrated React output separately.

| Symptom                                           | Likely cause                                                                   | Where to look                                                                                                                                                                                                                                                                                  |
| ------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Screen reader reads stale or duplicated labels    | Duplicate IDs from a component mounted more than once                          | Section 4; pass a per-mount `idPrefix` (`useId` alone collides across roots on the OSS package and every Pro path except the default RSC-provider path, which sets `identifierPrefix` automatically)                                                                                           |
| `aria-describedby` points at nothing after load   | ID differs between server and client                                           | Non-deterministic ID generation                                                                                                                                                                                                                                                                |
| Button is announced but does nothing              | Control rendered before hydration attached handlers                            | Section 3; add no-JS fallback or pending state                                                                                                                                                                                                                                                 |
| Hydration warning and visual flicker              | Server markup differs from client markup                                       | Dates, random values, locale, browser-only branches                                                                                                                                                                                                                                            |
| Streamed content is read in the wrong order       | DOM order differs from logical reading order                                   | Section 5; align `Suspense` boundaries                                                                                                                                                                                                                                                         |
| Announcement is missed or doubled while streaming | Live-region text changed before content committed, or changed twice            | Section 5; update after commit and guard repeats                                                                                                                                                                                                                                               |
| Content is missing for no-JS users                | `prerender: false`, or SSR failed and the page fell back to client-only output | Sections 1 and 3; check the Rails log for `ReactOnRails::PrerenderError` and the Node render-server output (stdout of the JS server process). `config.raise_on_prerender_error` (on by default in development) surfaces these failures instead of silently falling back to client-only output. |

**Portals and modals (SSR note).** If a dialog's DOM is created only after hydration, keyboard and screen reader users do not get a usable dialog in the first response. Fix this by not showing the dialog until JavaScript is ready, or by rendering an accessible non-portal fallback. After hydration, follow the [APG dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) or use a vetted dialog component.

---

## General Web Accessibility References

Short checklist: follow the links for the actual rules. This page does not restate them.

- **WCAG 2.2 AA** - the standard we target. [Quick reference](https://www.w3.org/WAI/WCAG22/quickref/).
- **Semantic HTML** - native elements first. [MDN HTML elements](https://developer.mozilla.org/en-US/docs/Web/HTML/Element), [WAI tutorials](https://www.w3.org/WAI/tutorials/).
- **ARIA fundamentals** - ARIA is not a substitute for native HTML. [WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/).
- **Complex widget keyboard patterns** - combobox, menu, dialog, tabs, and similar widgets. [APG patterns](https://www.w3.org/WAI/ARIA/apg/patterns/).
- **Color contrast, reduced motion, target size** - PR checklist items. [WCAG contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), [`prefers-reduced-motion`](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion), [target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).
- **Images, icons, media** - for alt text and captions. [WAI images tutorial](https://www.w3.org/WAI/tutorials/images/).
- **Screen reader usage** - driving [VoiceOver](https://www.apple.com/voiceover/info/guide/), [NVDA](https://www.nvaccess.org/), and JAWS for manual testing.
