# React 19.2 `<Activity>` Inside Streamed RSC Trees

React 19.2's [`<Activity>`](https://react.dev/reference/react/Activity) lets you hide part of the UI without unmounting it — hidden subtrees keep their state and DOM (`display: none`) while their effects are deactivated and their updates deferred to idle time. The [OSS guide](../../oss/building-features/react-19-activity.md) covers the basics with `react_component`; this page covers what changes when `<Activity>` boundaries live inside a **streamed React Server Component tree** (`stream_react_component`).

Everything here is verified by the Pro dummy app's working example and tests — see [Working example](#working-example).

## The one rule: host `<Activity>` in a client component

The `react-server` condition build of React — the one your RSC bundle resolves — **does not export `Activity`**. A server component that does `import { Activity } from 'react'` gets `undefined` and the render fails with:

```text
Element type is invalid: expected a string (for built-in components) or a
class/function (for composite components) but got: undefined.
```

Instead, put the `<Activity>` boundaries in a `'use client'` component and pass server-rendered content into them as props:

```jsx
// ActivityTabsClient.jsx — client component
'use client';

import React, { Activity, useState } from 'react';

export default function ActivityTabsClient({ profileContent, draftsContent }) {
  const [activeTab, setActiveTab] = useState('profile');
  const content = { profile: profileContent, drafts: draftsContent };

  return (
    <>
      {/* tab buttons ... */}
      {['profile', 'drafts'].map((tab) => (
        <Activity key={tab} mode={tab === activeTab ? 'visible' : 'hidden'}>
          <div>{content[tab]}</div>
        </Activity>
      ))}
    </>
  );
}
```

```jsx
// RSCActivityTabsPage.jsx — server component (no directive)
import React, { Suspense } from 'react';
import ActivityTabsClient from './ActivityTabsClient';
import ProfileServerContent from './ProfileServerContent';
import SlowDraftsServerContent from './SlowDraftsServerContent';

export default function RSCActivityTabsPage() {
  return (
    <ActivityTabsClient
      profileContent={<ProfileServerContent />}
      draftsContent={
        <Suspense fallback={<p>Loading drafts…</p>}>
          <SlowDraftsServerContent />
        </Suspense>
      }
    />
  );
}
```

This is the standard server-content-through-client-component pattern (see [RSC Inside Client Components](./inside-client-components.md)). Note that in this pattern the `<Activity>` element never crosses the RSC (Flight) boundary at all: `ActivityTabsClient` travels as a client reference, and the `<Activity>` boundaries are constructed inside its own render during SSR and hydration — only the server-rendered content props cross the boundary. React on Rails needs no configuration for any of this.

## Hidden is not free on the server

"Hidden" is a client-rendering concept. The Flight render on the Node renderer executes **all** server components eagerly, hidden or not:

- Data fetching inside a hidden tab's server components runs on every request that renders the page.
- The hidden content's output ships in the RSC payload bytes embedded in the page.
- Client components referenced inside hidden boundaries still emit their module references, so the browser preloads their chunks — that's the "pre-render likely-next content" benefit, but it's bandwidth you should budget.

Wrap slow hidden content in `<Suspense>` (in the server tree, as above) so it streams in a later chunk instead of delaying the shell.

## Hidden content is omitted from the rendered HTML

During SSR of the RSC tree, React's streaming renderer:

- wraps **visible** Activity content in `<!--&-->` / `<!--/&-->` comment markers (the Activity analog of Suspense's `<!--$-->` markers), and
- emits **no HTML at all** for `mode="hidden"` boundaries.

Consequences:

- Hidden content is invisible to SEO and no-JS users. Put anything that must be in the initial HTML in a visible boundary.
- Hidden content **is** present in the page's bytes — inside the embedded RSC payload scripts (`REACT_ON_RAILS_RSC_PAYLOADS`) — just not in the rendered DOM. Search engines index neither.
- After hydration, React mounts hidden subtrees client-side at background priority, with no hydration mismatch.

## Revealing a hidden tab needs no network request

React on Rails embeds the full RSC payload into the page as it streams. When the user reveals a hidden boundary, React renders it from that already-delivered payload — flipping `mode` to `visible` issues **no** `/rsc_payload/` request. If the hidden content's server row hasn't streamed in yet (slow data), the user sees its `<Suspense>` fallback until the row lands — still from the same open stream.

## Selective hydration bonus

Like Suspense boundaries, Activity boundaries divide the tree into independently hydratable units. With [async script loading](./selective-hydration-in-streamed-components.md) (the default on Shakapacker ≥ 8.2), the visible tab's buttons become interactive while a slow hidden tab's content is still streaming — hidden trees never compete with urgent hydration work.

> [!NOTE]
> One browser caveat, unrelated to React: WebKit (Safari) defers executing scripts — including the client bundle — until a streamed document finishes parsing, so mid-stream interactivity only materializes in Chromium/Firefox. The page still hydrates and works normally in Safari once the stream completes.

## Effects and Turbo caveats

The [OSS guide's gotchas](../../oss/building-features/react-19-activity.md) apply unchanged on the RSC path:

- Effects in hidden subtrees are deactivated (cleanups run) and re-run on reveal — sockets, timers, and analytics "view" events behave accordingly.
- `<Activity>` preserves state only within a persistent React root. Turbo Drive page visits tear the root down; Activity does not help across them.

## Working example

The Pro dummy app contains a complete, tested example:

- Page (server component): `react_on_rails_pro/spec/dummy/client/app/ror-auto-load-components/RSCActivityTabsPage.jsx`
- Client host + probes: `react_on_rails_pro/spec/dummy/client/app/components/ActivityRSC/`
- Route: `/activity_rsc_tabs` (optionally `?artificial_delay=5000` to slow the hidden tab's server content)
- Streamed-HTML shape: `react_on_rails_pro/spec/dummy/spec/requests/activity_rsc_spec.rb`
- Browser behavior (reveal without refetch, state preservation, selective hydration): `react_on_rails_pro/spec/dummy/e2e-tests/activity_rsc.spec.ts`

## References

- [React docs: `<Activity>`](https://react.dev/reference/react/Activity)
- [React 19.2 release post](https://react.dev/blog/2025/10/01/react-19-2)
- [React 19.2 `<Activity>` with React on Rails (OSS guide)](../../oss/building-features/react-19-activity.md)
- [Selective Hydration in React Server Components](./selective-hydration-in-streamed-components.md)
