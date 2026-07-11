# React 19.2 `<Activity>` with React on Rails

React 19.2 introduces [`<Activity>`](https://react.dev/reference/react/Activity), a built-in component that lets you **hide part of your UI without unmounting it**:

```jsx
import { Activity } from 'react';

<Activity mode={isActive ? 'visible' : 'hidden'}>
  <TabPanel />
</Activity>;
```

When `mode="hidden"`:

- The subtree stays **mounted** — all component state (inputs, scroll positions, fetched data held in state) is preserved.
- Its DOM stays in the document but is hidden with `display: none`.
- Its **effects are deactivated** (cleanup functions run), and they reactivate when the boundary becomes visible again.
- Updates inside the hidden subtree are **deferred** to idle time, so hidden UI never competes with visible UI for rendering priority.

This is the React-blessed replacement for the classic "keep the inactive tab alive" hacks (`display: none` wrappers, lifting every tab's state up, etc.). Typical uses: tab switchers, master/detail panes, and pre-rendering likely-next screens.

## Version requirements

| Layer                              | Requirement                                                                                                                                                                                                                         |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `react` / `react-dom` in your app  | **19.2.0 or later** (`Activity` does not exist in earlier versions, including 19.0/19.1)                                                                                                                                            |
| `react_on_rails` gem + npm package | Any current version — the package's peer dependency is `react >= 16`, so React on Rails does not constrain you; just upgrade `react`/`react-dom` in **your app's** bundle                                                           |
| RSC / Pro streaming path           | React on Rails Pro 17 RSC uses React/React DOM 19.2.x with patch >= 19.2.7 and the supported `react-on-rails-rsc` 19.2.x line (`>= 19.2.1`; `19.2.1-rc.1` during the RC soak), so `<Activity>` is available on that coordinated set |

`<Activity>` is a regular React feature inside your components. React on Rails needs no configuration for it — it works with the standard `react_component` helper in both client-side rendering and server-side rendering with hydration.

## Client-side rendering (CSR)

```erb
<%= react_component("ActivityTabSwitcher", props: { initialTab: "profile" }, prerender: false) %>
```

```tsx
import { Activity, useState } from 'react';

const TAB_NAMES = ['profile', 'drafts'] as const;
type TabName = (typeof TAB_NAMES)[number];

function TabPanel({ tab }: { tab: TabName }) {
  // This state survives tab switches because the hidden panel stays mounted.
  const [draft, setDraft] = useState('');
  return (
    <label>
      Draft for {tab}: <input value={draft} onChange={(e) => setDraft(e.target.value)} />
    </label>
  );
}

const ActivityTabSwitcher = ({ initialTab = 'profile' }: { initialTab?: TabName }) => {
  const [activeTab, setActiveTab] = useState<TabName>(initialTab);
  return (
    <div>
      {TAB_NAMES.map((tab) => (
        <button key={tab} type="button" onClick={() => setActiveTab(tab)}>
          {tab}
        </button>
      ))}
      {TAB_NAMES.map((tab) => (
        <Activity key={tab} mode={tab === activeTab ? 'visible' : 'hidden'}>
          <TabPanel tab={tab} />
        </Activity>
      ))}
    </div>
  );
};

export default ActivityTabSwitcher;
```

Contrast with the usual conditional render `{tab === activeTab && <TabPanel tab={tab} />}`, which unmounts the inactive panel and **loses** its state.

## Server-side rendering + hydration (`prerender: true`)

```erb
<%= react_component("ActivityTabSwitcher", props: { initialTab: "profile" }, prerender: true) %>
```

This works with React on Rails' standard string SSR (verified in the dummy app on the ExecJS path; the Pro Node renderer uses the same `renderToString` API). Verified behavior on React 19.2:

- **Visible** Activity content is included in the server-rendered HTML (delimited by `<!--&-->` / `<!--/&-->` boundary markers).
- **Hidden** Activity content is **omitted from the server HTML entirely**. React renders hidden subtrees on the client after hydration, at low priority.
- Hydration produces **no mismatch warnings** — React knows hidden boundaries are server-skipped and fills them in client-side.

Practical consequences:

- Your initial HTML payload only pays for visible content. Hidden tabs do not bloat the SSR response.
- Hidden content is **not available for SEO** or for users with JavaScript disabled. Put content that must be in the initial HTML in the visible boundary.
- Hidden subtrees still consume client memory once rendered — do not keep unbounded numbers of hidden trees mounted.

## Effects unmount while hidden — gotchas

When a boundary goes `hidden`, React runs all effect cleanups in that subtree (and re-runs the effects when it becomes visible again). State is preserved; effects are not. Audit hidden-able components for:

- **Subscriptions / sockets**: a WebSocket opened in `useEffect` disconnects when the tab hides and reconnects when shown. That is the designed behavior — not a bug. If the connection must outlive visibility, own it above the `<Activity>` boundary.
- **Timers and intervals**: cleared on hide; restart on show.
- **Analytics "view" events fired from effects**: they will fire again each time the boundary becomes visible.

## Turbo / Turbolinks caveat (important)

**`<Activity>` cannot preserve state across Turbo (or Turbolinks) page visits.** State preservation only works **within a persistent React root**. On a Turbo Drive navigation, Turbo replaces the document `<body>`; React on Rails unmounts your components on the page-change events and mounts fresh ones on the new page. Every `<Activity>` boundary — hidden or visible — is destroyed with its root, and all React state is gone.

Use the right tool for each axis:

- **Within one page** (tabs, panes, wizards rendered by a single `react_component`): `<Activity>` preserves the hidden parts' state. ✅
- **Across Turbo page visits**: `<Activity>` does not help. ❌ If you need UI to survive Turbo navigation, the element must be excluded from Turbo's body swap (e.g., Turbo's [`data-turbo-permanent`](https://turbo.hotwired.dev/handbook/building#persisting-elements-across-page-loads)), which is independent of React and has its own significant constraints with React-managed DOM. For React-native cross-"page" state preservation, use client-side routing (e.g., React Router) inside one persistent React root instead of full Turbo page loads — then `<Activity>` can keep inactive route trees alive.

## Working example

The React on Rails dummy app contains a complete, tested example:

- Component: `react_on_rails/spec/dummy/client/app/startup/ActivityTabSwitcher.tsx`
- CSR page: `/client_side_activity` (`prerender: false`)
- SSR page: `/server_side_activity` (`prerender: true`)
- Tests: `react_on_rails/spec/dummy/spec/requests/activity_component_spec.rb` (server HTML shape) and `react_on_rails/spec/dummy/spec/system/activity_spec.rb` (state preservation + hydration in a real browser)

## References

- [React docs: `<Activity>`](https://react.dev/reference/react/Activity)
- [React 19.2 release post](https://react.dev/blog/2025/10/01/react-19-2)
- [Turbo handbook: persisting elements across page loads](https://turbo.hotwired.dev/handbook/building#persisting-elements-across-page-loads)
