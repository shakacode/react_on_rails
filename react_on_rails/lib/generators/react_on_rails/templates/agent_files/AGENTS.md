# AGENTS.md — React on Rails (for AI coding agents working IN this app)

This app uses **React on Rails** to render React components from Rails views, with
optional server-side rendering (SSR). This file teaches an AI agent the conventions
it needs to add, register, and render a component correctly on the first try.

It is intentionally short. For the full reference, see the links at the bottom.

> This file describes an app that **uses** React on Rails. It is not the
> contributor guide for the React on Rails framework itself.

## 1. Adding a component (auto-bundling — the default)

Place a component under any directory named `ror_components`. React on Rails
auto-bundles it, so **no manual registration is needed**:

```
app/javascript/src/<Name>/ror_components/<Name>.tsx   # or .jsx
```

The component file **must `export default`** the React component. Example:

```tsx
// app/javascript/src/SimpleCounter/ror_components/SimpleCounter.tsx
import React, { useState } from 'react';

const SimpleCounter = (props: { initialCount?: number }) => {
  const [count, setCount] = useState(props.initialCount ?? 0);
  return <button onClick={() => setCount((c) => c + 1)}>Count: {count}</button>;
};

export default SimpleCounter; // default export is required
```

### Manual registration (alternative)

If you are not using the `ror_components/` auto-bundling convention, register the
component explicitly from a pack/entry file, importing from the `react-on-rails`
npm package:

```ts
import ReactOnRails from 'react-on-rails';
import SimpleCounter from './SimpleCounter';

ReactOnRails.register({ SimpleCounter });
```

The key (`SimpleCounter`) is the name you pass to `react_component` in the Rails view.

## 2. Rendering it from a Rails view

Use the `react_component` view helper in any `.html.erb` view (e.g.
`app/views/<controller>/<action>.html.erb`). The first argument is the registered
component name; it must match the file/registration name exactly (case-sensitive).

```erb
<%= react_component("SimpleCounter", props: { initialCount: 5 }, prerender: true) %>
```

- `props:` — a Ruby Hash serialized to JSON and passed to the component.
- `prerender:` — `true` renders the component on the server (SSR) then hydrates on
  the client; `false` renders only on the client. Set `prerender: false` to isolate
  SSR issues while debugging.

## 3. `.client` vs `.server` (and plain) bundles — what runs where

When a component name resolves to multiple files, React on Rails picks by suffix:

- `<Name>.client.tsx` — runs in the **browser** only. May use `window`, `document`,
  browser-only APIs, and client-side hooks/effects.
- `<Name>.server.tsx` — runs during **server-side rendering** (Node, no DOM). It
  **must not** use browser-only globals (`window`, `document`, `localStorage`).
  Often it just re-exports the client component for SSR.
- `<Name>.tsx` (plain, no suffix) — used for **both** server and client. Keep it
  isomorphic: guard any browser-only code with `if (typeof window !== 'undefined')`.

Rule of thumb: if `prerender: true`, the code path must run in Node without a DOM.

## 4. The `ReactOnRails` JS API you will actually touch

Import from the `react-on-rails` npm package:

```ts
import ReactOnRails from 'react-on-rails';
```

- `ReactOnRails.register({ Name })` — register one or more components by name.
- `ReactOnRails.registerStore({ name })` / `ReactOnRails.getStore(name)` — register
  and retrieve a Redux store (only if this app uses Redux).
- `ReactOnRails.reactOnRailsPageLoaded()` — rarely needed; React on Rails wires
  client hydration automatically.

You usually only need `register` (and only when not using `ror_components/`).

## 5. Top errors and fixes

These messages come straight from React on Rails' runtime errors. When you hit one,
apply the matching fix.

### `Component '<Name>' Not Registered`

The component name in the view does not match a registered/auto-bundled component.

- Recommended (auto-bundling): put the component file directly inside a
  `ror_components/` directory, e.g.
  `app/javascript/src/<Name>/ror_components/<Name>.client.tsx`, with a `default`
  export, then regenerate packs: `bin/rails react_on_rails:generate_packs`.
- Or register manually: `ReactOnRails.register({ <Name>: <Name> });` and
  `import <Name> from './components/<Name>';`.
- Check the name matches the `react_component("<Name>", ...)` call exactly (case-sensitive).

### `Auto-loaded Bundle Missing`

The component is set up for auto-loading but its bundle is missing.

1. Run the pack generation task: `bin/rails react_on_rails:generate_packs`.
2. Ensure the component is in the correct directory under `app/javascript`.
3. Check naming conventions: file is `<Name>.jsx` or `<Name>.tsx` and `export default`s.
4. Verify nested entries are enabled in your Shakapacker/webpack config.

### `Hydration Mismatch`

Server-rendered HTML doesn't match what React rendered on the client.

1. **Random IDs or timestamps**: use props or deterministic values, not
   `Math.random()` / `Date.now()`.
2. **Browser-only APIs**: guard with `if (typeof window !== 'undefined') { ... }`.
3. **Different data**: ensure props/`railsContext`/store init are identical on
   server and client.
4. Temporarily set `prerender: false` to isolate the issue.

### `Server Rendering Failed`

An error occurred while server-rendering a component.

1. Check JS console output in the Rails log: `tail -f log/development.log | grep 'React on Rails'`.
2. Common causes: missing Node dependencies, syntax errors, or browser-only APIs in
   server code.
3. Set `config.trace = true` and check `config.server_bundle_js_file` points at the
   correct file.

### `Redux Store Not Found`

A Redux store wasn't registered before a component that depends on it rendered.

1. Register the store: `ReactOnRails.registerStore({ <store> });`.
2. Initialize it in the view before the component: `<%= redux_store('<store>', props: {}) %>`.
3. Declare the dependency: `store_dependencies: ['<store>']`.

## 6. Diagnose your setup

Before guessing, run the doctor in its stable machine-readable mode — it checks
configuration, bundles, and dependencies and returns copy-promptable remediation:

```bash
bin/rails react_on_rails:doctor FORMAT=json
```

Exit code `0` means there are no errors (warnings may still be present); exit code
`1` means at least one error must be fixed. Use each non-passing check's stable
`id`, `severity`, `message`, and `remediation.prompt`, then rerun the command until
the report no longer contains errors. The JSON contract is documented at
https://reactonrails.com/docs/api-reference/doctor.

## 7. Where the full reference lives

- Hosted docs: https://reactonrails.com/docs/
- Getting-started tutorial: https://reactonrails.com/docs/getting-started/tutorial/
- Machine-readable route map / expanded reference (for agents):
  https://github.com/shakacode/react_on_rails/blob/main/llms.txt,
  https://github.com/shakacode/react_on_rails/blob/main/llms-full.txt (OSS), and
  https://github.com/shakacode/react_on_rails/blob/main/llms-full-pro.txt (Pro)
