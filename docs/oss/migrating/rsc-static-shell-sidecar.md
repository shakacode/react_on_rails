# Mostly Static RSC Shell With a Tiny Sidecar

Use this pattern when a public page can render almost all useful content as static RSC HTML but still
needs a few browser behaviors. The goal is to keep the static shell and CSS on the critical path while
loading only a small, explicit browser entry for progressive enhancement.

> **Part 10 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous:
> [RSC Performance Validation Playbook](rsc-performance-validation.md)

## When to Use This Pattern

Use a mostly static shell plus tiny sidecar when:

- The page is public, SEO-sensitive, or mostly static.
- The initial UI can render without browser state.
- The normal global application pack is much larger than the required behavior.
- The page needs a small amount of progressive enhancement, such as search, auth, currency, analytics,
  newsletter signup, or URL-driven effects.
- Visual parity with the old page is required.

Do not use it when:

- The page is mostly an authenticated application surface.
- The page needs many eager client islands.
- The global app pack is already tiny.
- Route-level behavior depends on global JavaScript that the team has not audited.
- The team is trying to hide a broad RSC client-reference problem by disabling discovery globally.

## Architecture Sketch

```text
Rails view
|-- renders static RSC component output
|-- appends explicit static shell CSS
|-- opts out of selected global JavaScript packs
|-- emits inert JSON props/context for the sidecar
`-- appends a tiny sidecar JavaScript entry

StaticPublicPage
`-- renders layout, chrome, and page content without browser-only hooks

public-page-effects sidecar
|-- parses JSON props/context
|-- handles URL-driven effects immediately when needed
|-- listens for user intent on static placeholders
`-- lazy-imports React/client islands only on demand
```

The names above are placeholders. In an app, use page-specific names such as `StaticPublicPage`,
`PublicPageEffects`, or `public-page-effects` rather than copying names from another product.

## Rails Layout Pack Opt-Out

Until a first-class helper exists, use an explicit Rails layout convention. Keep global CSS and layout
markup intact; skip only the selected JavaScript pack on pages that opt in. The broader Pro layout
pattern is documented in
[Page-Level Global JavaScript Opt-Out for Static Shells](../../pro/react-server-components/static-shell-global-js-opt-out.md),
and the public follow-up is [#4297](https://github.com/shakacode/react_on_rails/issues/4297).

```erb
<%# app/views/layouts/application.html.erb %>
<% unless content_for?(:skip_global_javascript) %>
  <% append_javascript_pack_tag "global" %>
<% end %>
<%= javascript_pack_tag defer: true %>
```

```erb
<%# app/views/public/home.html.erb %>
<% content_for :skip_global_javascript, "true" %>
<% append_javascript_pack_tag "public-page-effects" %>
```

Keep the contract narrow:

- Skip only the JavaScript pack you intend to replace.
- Keep global CSS, layout CSS, fonts, and RSC/page-specific styles if the static HTML depends on
  them.
- Make the opt-out page-scoped and visible in the view.
- List behavior normally initialized by the skipped pack and either replace it, move it to a smaller
  sidecar, or consciously drop it.

## Props and Context Handoff

Avoid mounting a full React on Rails client component just to pass props to the sidecar. Emit inert
JSON and let the sidecar parse it.

```erb
<script type="application/json" id="public-page-effects-props">
  <%= raw json_escape(props.to_json) %>
</script>
```

The sidecar can also read a small Rails context script when it needs CSRF, locale, currency, or
feature flags. Keep the payload serializable and page-specific.

```js
function readJsonScript(id) {
  const element = document.getElementById(id);
  if (!element?.textContent) return {};
  return JSON.parse(element.textContent);
}

const props = readJsonScript('public-page-effects-props');
const context = readJsonScript('public-page-effects-context');
```

Sidecar rules:

- Parse inert JSON scripts; do not depend on a hidden React mount for data transport.
- Create a small root only when a real client island is needed.
- Lazy import React and `react-dom/client` only when user intent or URL state requires it.
- Fail safely when optional target elements are absent.
- Keep sidecar behavior independent from RSC client-reference hydration.

## Intent Hydration

Render a static placeholder or fallback UI in the RSC HTML. Attach lightweight listeners to it from
the sidecar. On first user intent, lazy import the real client island, mount it, and replay the
intent.

```js
const searchTarget = document.querySelector('[data-public-search]');
const props = readJsonScript('public-page-effects-props');
let hydrating = false;

async function hydrateSearch(firstEvent) {
  const [{ default: SearchIsland }, { createRoot }, React] = await Promise.all([
    import('./SearchIsland'),
    import('react-dom/client'),
    import('react'),
  ]);

  const root = createRoot(searchTarget);
  root.render(React.createElement(SearchIsland, { props, firstEventType: firstEvent.type }));
}

async function onIntent(event) {
  if (hydrating) return;

  hydrating = true;
  try {
    await hydrateSearch(event);
    searchTarget.removeEventListener('click', onIntent);
    searchTarget.removeEventListener('focusin', onIntent);
    searchTarget.removeEventListener('keydown', onKeydown);
  } catch (error) {
    console.error('Failed to load search island', error);
  } finally {
    hydrating = false;
  }
}

function onKeydown(event) {
  if (event.key !== 'Enter' && event.key !== ' ') return;

  event.preventDefault();
  onIntent(event);
}

if (searchTarget) {
  searchTarget.addEventListener('click', onIntent);
  searchTarget.addEventListener('focusin', onIntent);
  searchTarget.addEventListener('keydown', onKeydown);
}
```

Keep accessibility and fallback behavior explicit:

- Support keyboard activation, not only pointer clicks.
- Preserve focus order and visible focus styles before and after hydration.
- Provide a no-JS or slow-JS fallback for required flows, such as a normal form action or link.
- Replay the first intent so the user does not need to click or type twice.
- Smoke-test URL-driven effects that must run without waiting for a click, such as auth or
  query-param flows.

## CSS Parity

A static RSC shell cannot rely on a skipped JavaScript pack to incidentally import required styles.
Make CSS delivery explicit:

- Keep layout/global styles loaded when the static HTML depends on them.
- Add a static shell stylesheet entry for page chrome that moved out of the old client graph.
- Add page-specific CSS entries for page-only styles.
- Keep existing preload or modulepreload behavior when it is part of the old page's critical path.
- Compare before/after screenshots for fonts, icons, spacing, layout wrappers, hover/focus states,
  mobile navigation, and responsive breakpoints.
- Avoid hidden dependencies where a JavaScript pack imports SCSS needed by static HTML.

If the RSC page downloads unexpected CSS or JS through client references, check
[Chunk Contamination](rsc-troubleshooting.md#chunk-contamination) and
[RSC Stylesheet Injection](rsc-troubleshooting.md#rsc-stylesheet-injection-render-blocking-links-and-cascade-order).

## Bundler and Client-Reference Caveats

A tiny sidecar is ordinary browser JavaScript. It is not an RSC Client Component and it is not an RSC
client reference. Sidecar success does not prove RSC client islands will hydrate.

Do not use this pattern as a reason to globally disable RSC client-reference discovery:

- Do not set `clientReferences = []` as a general app optimization.
- Do not change normal RSC vendor or client-reference chunking unless the change is isolated and
  tested.
- If a sidecar is kept out of a monolithic vendor split, verify that RSC client-reference hydration
  still works on a route that has a real Client Component.
- Prefer app-source-scoped discovery until route-scoped client-reference manifests exist.

See
[Client Reference Scope and Empty `clientReferences`](rsc-troubleshooting.md#client-reference-scope-and-empty-clientreferences),
[react_on_rails_rsc#134](https://github.com/shakacode/react_on_rails_rsc/issues/134), and
[react_on_rails_rsc#145](https://github.com/shakacode/react_on_rails_rsc/issues/145).

## Behavior Audit Before Skipping Global JavaScript

Audit the selected global pack before opting a page out:

- Auth, sign-in modal, sign-up modal, account menu, and session-expiration behavior.
- Magic-link, campaign, referral, flash, or query-param flows.
- CSRF/session-dependent fetches or forms.
- Analytics, consent management, error tracking, and web-vitals reporting.
- Currency, locale, theme, or user-preference state.
- Navbar, menu, search, footer, and mobile layout interactions.
- Third-party widgets and embeds.
- Event handlers installed by the global pack on layout elements.
- CSS imported only by the global pack.

Move required behavior into the sidecar or a smaller layout-owned script. Do not assume skipped global
JavaScript is harmless just because the page still renders.

## Verification Checklist

For each static shell page:

- Smoke-test control and experiment URLs before measuring.
- Confirm the global JavaScript pack is absent only on opted-out pages.
- Confirm global CSS, static shell CSS, page CSS, fonts, and critical images still load.
- Run visual regression for every changed page and viewport.
- Compare total downloads and JavaScript bytes against the control.
- Run the [RSC Performance Validation Playbook](rsc-performance-validation.md) when the PR claims a
  performance win.
- Exercise every sidecar-triggered flow, including URL-driven flows.
- Check keyboard activation, focus management, and no-JS or slow-JS fallback behavior.
- Add targeted system or E2E specs for behavior moved out of the global pack.
- Test at least one RSC route with a real Client Component if `clientReferences` was narrowed.

Related work: [#4295](https://github.com/shakacode/react_on_rails/issues/4295) tracks cached RSC
output for static public pages, [#4297](https://github.com/shakacode/react_on_rails/issues/4297)
tracks the page-level global JavaScript opt-out, and
[#4299](https://github.com/shakacode/react_on_rails/issues/4299) tracks the performance validation
playbook behind this guide.
