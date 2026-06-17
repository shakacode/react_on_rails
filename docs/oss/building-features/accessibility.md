# Accessibility (a11y)

Accessibility is not a feature you bolt on at the end — it is a property of every
surface your app renders. React on Rails apps have an unusual accessibility
surface area because the same UI can be produced three different ways: as
server-rendered HTML (SSR), as client-hydrated React, and — in
[React on Rails Pro](../../pro/react-on-rails-pro.md) — as
[React Server Components (RSC)](../../pro/react-server-components/index.md)
streamed over the wire. Each path has its own failure modes for focus, live
regions, and progressive enhancement.

This guide collects the accessibility practices that matter for React on Rails
specifically. The baseline target is **WCAG 2.1 Level AA** (WCAG 2.2, the current
W3C Recommendation, is a backwards-compatible superset — the guidance here meets
both). Where a practice is RSC-specific, it is called out in the
[Server Components](#server-components) section.

> **Scope note:** Most of the general guidance below is plain web a11y that
> applies to any React on Rails app. The Server Components section assumes the
> Pro RSC stack. Concrete RSC streaming/Suspense behavior referenced here is
> documented in the
> [Pro RSC docs](../../pro/react-server-components/index.md).

## General React on Rails accessibility

### Color contrast (WCAG AA)

Every text and interactive surface must meet WCAG AA contrast ratios:

- **4.5:1** for normal text
- **3:1** for large text (≥ 24px, or ≥ 19px bold) and for UI component
  boundaries / focus indicators

Contrast is a design-token concern, not a per-component one. If you use
[Tailwind](./styling-with-tailwind.md), pin accessible color pairs in your theme
rather than reaching for arbitrary values per component, and audit them with a
contrast checker (browser DevTools, or the axe tooling described
[below](#automated-a11y-tooling)). Do not rely on color alone to convey state —
pair color with text or an icon.

### Keyboard navigation

Everything actionable must be reachable and operable with the keyboard alone:

- Use native interactive elements (`<button>`, `<a href>`, `<input>`) so you get
  focusability, Enter/Space activation, and roles for free. A `<div onClick>` is
  not keyboard-accessible.
- Keep a visible focus indicator. Never `outline: none` without a replacement.
- Maintain a logical tab order that follows the visual/reading order. Avoid
  positive `tabIndex` values.

Verify keyboard behavior in an E2E test rather than by hand — see
[Testing](#testing-accessibility).

### `aria-live` for Rails flash messages and form errors

Content that appears asynchronously (flash messages after a Turbo navigation,
validation errors after a failed submit) is invisible to screen readers unless
it lands in a **live region**. Render the live region container in the initial
markup and update its contents — do not create the region at the moment the
message appears, or the announcement may be missed.

```erb
<%# app/views/layouts/application.html.erb
    This element is plain server-rendered ERB — it is not React-managed, so it
    won't re-mount on hydration and won't trigger the double-announcement
    described later for hydrated React live regions. %>
<div aria-live="polite" aria-atomic="true" id="flash">
  <% flash.each do |type, message| %>
    <div class="flash flash--<%= type %>"><%= message %></div>
  <% end %>
</div>
```

Use `aria-live="polite"` for non-urgent updates (flash notices) and
`aria-live="assertive"` (or `role="alert"`) for errors that need immediate
attention.

For React forms, the same rule applies. If you use
[`useRailsForm`](./forms.md), the hook exposes a per-field `errors` object
(`{ field: ["message", ...] }`). Surface validation errors in a live region and
associate each message with its field via `aria-describedby` so the error is
announced when focus reaches the input:

```tsx
function EmailField() {
  const form = useRailsForm({ email: '' });

  // Use the same guard (`?.[0]`) for the attribute and the element it points to,
  // so `aria-describedby` never references a `<p>` that isn't in the DOM.
  const emailError = form.errors.email?.[0];

  return (
    <div>
      <label htmlFor="email">Email</label>
      <input
        id="email"
        name="email"
        aria-invalid={Boolean(emailError)}
        aria-describedby={emailError ? 'email-error' : undefined}
        value={form.data.email}
        onChange={(e) => form.setData('email', e.target.value)}
      />
      {emailError && (
        <p id="email-error" role="alert" className="error">
          {emailError}
        </p>
      )}
    </div>
  );
}
```

After a submit that returns a 422, move focus to a summary of errors (or to the
first invalid field) so keyboard and screen-reader users are taken to the
problem rather than left at the submit button.

The example above conditionally mounts the `role="alert"` element, which is the
simplest pattern and works in most modern screen readers (a newly-inserted
`role="alert"` is announced). If you need to support older AT pairings that only
announce **mutations** of an already-present live region, render a persistent
empty container in the initial markup and update its text instead:

```tsx
// Always rendered; only its contents change.
<p id="email-error" role="alert" className="error">
  {form.errors.email?.[0] ?? ''}
</p>
```

### Focus management on dialogs and route changes

React on Rails apps commonly mix client-side routing
([React Router](./react-router.md),
[TanStack Router](./tanstack-router.md),
[instant navigation](./client-side-routing-instant-navigation.md)) with
server-rendered pages. Both transitions need explicit focus handling:

- **Dialogs / modals:** on open, move focus into the dialog; trap focus while it
  is open; on close, return focus to the element that opened it. Prefer the
  native `<dialog>` element (opened with `showModal()`, which handles focus
  trapping and the implicit `role="dialog"` for you) or a well-tested library —
  hand-rolled focus trapping is easy to get wrong. Always give the dialog an
  accessible name via `aria-labelledby`. On a custom (non-`<dialog>`) container,
  add `role="dialog"` and `aria-modal="true"` yourself.
- **Client-side route changes:** unlike a full page load, an SPA navigation does
  not reset focus. On each route change, move focus to a logical landmark (the
  new page's `<h1>` or main heading) and announce the new page title in a live
  region, so screen-reader users know the view changed.

### `prefers-reduced-motion`

Respect users who have requested reduced motion at the OS level. Gate non-
essential animation and transitions behind the media query:

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

If you use [View Transitions](./view-transitions.md) or other JS-driven motion,
read the same preference in JS and skip the animation:

```ts
// Browser-only — `window` is undefined during SSR / in a Server Component, so
// guard it and prefer the CSS media query above, which applies before JS runs.
const reduceMotion =
  typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
```

See [SSR and reduced motion](#ssr-reduced-motion-and-fouc) for the server/client
boundary caveat.

### Touch targets

The WCAG **AA** floor is **24×24 CSS pixels** (WCAG 2.2 SC 2.5.8). Aim higher:
**44×44 CSS pixels** (WCAG 2.1/2.2 AAA, SC 2.5.5) is widely treated as the
practical minimum on touch devices. Apply minimum sizes with padding rather than
shrinking the visible label, and keep adequate spacing between adjacent targets.

### `eslint-plugin-jsx-a11y`

React on Rails ships with
[`eslint-plugin-jsx-a11y`](https://github.com/jsx-eslint/eslint-plugin-jsx-a11y)
as a dev dependency, and the lint config exercises it. It is a fast static
backstop that catches missing `alt` text, invalid ARIA, non-interactive elements
with handlers, and similar mistakes at author time. Keep it in your own app's
ESLint config and treat its warnings as bugs.

**Caveat — `jsx-a11y/anchor-is-valid` is disabled in this repository.** In
`eslint.config.ts` the rule is turned `off`:

```ts
'jsx-a11y/anchor-is-valid': 'off',
```

This is a project lint choice for the React on Rails codebase, not a
recommendation that you disable it in your app. `anchor-is-valid` guards against
the common anti-pattern of using `<a>` as a button (e.g. `<a href="#">` or an
anchor with only an `onClick`). In application code, keep this rule **on**: use
`<a href>` for navigation and `<button>` for actions. If you re-enable it and use
a framework `<Link>` component, configure the rule's `components`/`specialLink`
options instead of suppressing it.

## Server Components

[React Server Components](../../pro/react-server-components/index.md) (Pro)
change how UI reaches the browser: the server streams an RSC payload, the shell
and Suspense fallbacks render immediately, and slow boundaries stream in and
hydrate independently
([selective hydration](../../pro/react-server-components/selective-hydration-in-streamed-components.md)).
This streaming, partially-hydrated model introduces accessibility failure modes
that do not exist in a single synchronous render.

### Progressive enhancement: accessible HTML before JS

The strongest accessibility guarantee RSC gives you is that meaningful HTML
exists **before** client JavaScript runs. Lean into it:

- Ensure the server-rendered markup is usable on its own — real `<a href>`
  links, real `<form action>` targets, headings and landmarks in place — so
  keyboard and screen-reader users are not blocked while JS loads or if it never
  loads.
- Keep behavior that only exists after hydration (anything driven purely by
  `onClick` in a Client Component) as an enhancement on top of a working server
  baseline, not the only path.

### Focus management across Suspense-streamed content

When a [`<Suspense>`](../../pro/react-server-components/add-streaming-and-interactivity.md)
boundary resolves, React swaps the fallback for the real content. If the user's
focus was inside the fallback (or the streamed content should receive focus —
e.g. it is the result of an action), that focus is not managed for you.

- Do not auto-steal focus on every boundary resolution — content streaming in
  below the fold should not yank a reader away from where they are.
- When streamed content **is** the user's destination (a route's main content, a
  submitted result), move focus to its heading once it mounts, and announce the
  change in a live region.
- Keep skeletons and their resolved content the same size where possible to avoid
  layout shift that moves targets out from under a pointer or magnifier.

### Avoiding `aria-live` double-announcements

A live region that is present in the server-rendered HTML **and** re-rendered
during hydration can announce its contents twice — once when the SSR'd DOM is
read, and again when React reconciles. To avoid duplicate or spurious
announcements across the server → client boundary:

- Render live-region **containers** on the server, but treat them as empty at
  first paint; populate them only in response to client-side events after
  hydration.
- Do not place already-rendered server content inside an `aria-live` region that
  will re-mount on hydration. Reserve live regions for genuinely dynamic,
  post-hydration updates.
- For status messages that exist purely to be announced, gate them so they are
  emitted once, on the client, after the component is interactive.

### Keyboard navigability through partially-hydrated trees

With selective hydration, parts of the page become interactive at different
times. A control that is visible but whose Client Component has not yet hydrated
can swallow or drop keyboard input.

- Server-render interactive controls as real, natively-operable elements
  (`<button>`, `<a href>`) so they work before hydration and stay in the tab
  order throughout.
- Avoid disabling controls "until hydrated" if the underlying action has a
  server-side fallback — a disabled control is removed from the keyboard flow.
- Test tab order on a throttled connection, where the gap between paint and
  hydration is largest (see [Testing](#testing-accessibility)).

### Loading and skeleton states (`role` / `aria-busy`)

Suspense fallbacks and skeletons are not just visual placeholders — communicate
their state to assistive tech:

- Mark the region that is loading with `aria-busy="true"` while its content is
  pending, and remove it (or set `false`) once resolved.
- Give a meaningful status, e.g. a visually-hidden `role="status"` /
  `aria-live="polite"` message like "Loading reviews", rather than an unlabeled
  spinner.
- Purely decorative skeleton shapes should be hidden from assistive tech with
  `aria-hidden="true"`.

> The `sr-only` class used below visually hides text while keeping it available
> to screen readers. It ships with [Tailwind](./styling-with-tailwind.md); without
> Tailwind, define it yourself (see the
> [WebAIM recipe](https://webaim.org/techniques/css/invisiblecontent/)):
> `position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0;`

Drive `aria-busy` from the loading state rather than hard-coding it, so it
clears once the content resolves. Put the busy flag and the status message on the
fallback (which is unmounted when the boundary resolves), and leave the resolved
content with its normal semantics:

```tsx
import React, { Suspense } from 'react';

function ReviewsFallback() {
  return (
    <div aria-busy="true">
      <span role="status" className="sr-only">
        Loading reviews
      </span>
      {/* Wrap in a real DOM element: a custom component only honors aria-hidden
          if it forwards the prop to its root, so the wrapper is the reliable way
          to hide decorative skeleton shapes from assistive tech. */}
      <div aria-hidden="true">
        <ReviewsSkeleton />
      </div>
    </div>
  );
}

function ReviewsSection() {
  return (
    <Suspense fallback={<ReviewsFallback />}>
      <Reviews />
    </Suspense>
  );
}
```

When the boundary resolves, React unmounts the fallback — so `aria-busy="true"`
and the "Loading reviews" status go away with it, and `<Reviews />` renders
without a stale busy flag.

### SSR, reduced motion, and FOUC

[`prefers-reduced-motion`](#prefers-reduced-motion) is only readable in the
browser — the server cannot know the user's preference at render time. Drive
motion suppression from **CSS media queries**, which apply in the server-rendered
HTML before any JS runs, rather than from a JS check that only takes effect after
hydration. A JS-gated animation can fire on first paint before the preference is
read.

Streaming SSR can also surface a flash of unstyled content (FOUC) as chunks
arrive. Beyond the visual annoyance, FOUC can mean focus styles or contrast are
briefly wrong. Make sure critical CSS (including focus indicators and the
reduced-motion query) is available with the initial shell, not deferred. See the
[Pro Streaming SSR guide](../../pro/streaming-ssr.md) for how the shell and
script loading are ordered.

## Testing accessibility

Automated checks catch regressions cheaply; treat them as a floor, not a
substitute for manual keyboard and screen-reader testing.

### Playwright: ARIA and keyboard assertions

React on Rails apps already run E2E tests against a real browser via
[Playwright or Cypress](./dev-server-and-testing.md#playwright--cypress-e2e).
Use accessible-role/name locators (which fail when the accessibility tree is
wrong) and assert keyboard operability directly:

```ts
import { test, expect } from '@playwright/test';

test('dialog is keyboard accessible', async ({ page }) => {
  await page.goto('/');

  // Locate by role + accessible name, not by CSS — this exercises the a11y tree.
  await page.getByRole('button', { name: 'Open settings' }).click();

  const dialog = page.getByRole('dialog', { name: 'Settings' });
  await expect(dialog).toBeVisible();

  // Focus should have moved into the dialog on open — assert the focused element
  // is inside it, not merely that the dialog rendered.
  await expect(dialog.locator(':focus')).toBeVisible();

  // Escape closes and returns focus to the trigger.
  await page.keyboard.press('Escape');
  await expect(dialog).toBeHidden();
  await expect(page.getByRole('button', { name: 'Open settings' })).toBeFocused();
});

test('main nav is reachable by keyboard', async ({ page }) => {
  await page.goto('/');

  // A skip-navigation link is a WCAG 2.4.1 (Level A) requirement and the correct
  // first tab stop, so assert it first, then the first nav item.
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: /skip to main content/i })).toBeFocused();

  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Home' })).toBeFocused();
});
```

If your app has no skip link, the first `Tab` lands on the first nav item — but
add the skip link: it is a Level A requirement.

For an example of asserting React runtime behavior from a Playwright spec in this
project, see
`react_on_rails/spec/dummy/e2e/playwright/e2e/react_on_rails/root_error_callbacks.spec.js`
(referenced from
[Debugging hydration mismatches](./debugging-hydration-mismatches.md)).

### Automated a11y tooling

Layer a dedicated a11y scanner on top of role-based assertions to catch contrast,
ARIA, and structural issues across whole pages. [axe-core](https://github.com/dequelabs/axe-core)
is the standard engine; it is **not** a React on Rails dependency, so add it to
your own app:

- **Playwright:** [`@axe-core/playwright`](https://github.com/dequelabs/axe-core-npm/tree/develop/packages/playwright)
  to scan rendered pages in your existing E2E suite.
- **Component/unit tests:** [`jest-axe`](https://github.com/nickcolley/jest-axe)
  (or the Vitest equivalent) to assert individual components have no violations.
- **CI / static:** run the scan on your key routes so a11y regressions fail the
  build the same way a broken test would.

When testing RSC pages, scan **after** streaming and hydration have settled
(wait for your loading state to clear / `aria-busy` to drop) so the scanner sees
the final tree, and consider a second scan of the pre-hydration HTML to confirm
the server baseline is accessible on its own.

## Related documentation

- [Forms and mutations with `useRailsForm`](./forms.md) — validation error shape
  used in the live-region example above
- [Styling with Tailwind](./styling-with-tailwind.md) — where to centralize
  accessible color tokens
- [View Transitions](./view-transitions.md) — JS-driven motion and reduced-motion
- [Dev server and testing](./dev-server-and-testing.md) — Playwright / Cypress
  setup
- [React Server Components (Pro)](../../pro/react-server-components/index.md) —
  streaming, Suspense, and selective hydration model
- [Streaming SSR (Pro)](../../pro/streaming-ssr.md) — shell and script ordering
