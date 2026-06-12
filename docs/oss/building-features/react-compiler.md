# React Compiler with React on Rails

[React Compiler](https://react.dev/learn/react-compiler) (stable **v1.0**, shipped 2025-10-07) is a build-time tool that adds **automatic memoization** to your components. It removes most hand-written `useMemo` / `useCallback` / `React.memo` boilerplate and cuts unnecessary re-renders — a free runtime-performance and DX win that costs you only a build-config change.

Because the Compiler is versioned independently of React itself, it works on React on Rails' current `react`/`react-dom` `~19.0.x` pin. You do **not** need to wait for a React 19.2 bump to adopt it.

React on Rails delegates JavaScript/TypeScript transforms to your app's build tool (Shakapacker → webpack or Rspack, with Babel or SWC). The Compiler is therefore configured in **your app's Babel or SWC config**, not inside React on Rails. This page documents both transform paths.

## TL;DR

- **Babel path is canonical and verified.** Add `babel-plugin-react-compiler` to your `babel.config.js`, ordered **first**. The compiler-memoized output builds and server-renders correctly.
- **SWC path is experimental — not recommended for production yet.** As of June 2026 there is no first-party SWC React Compiler plugin; only a brand-new, pre-1.0 third-party Wasm plugin exists. See [Rspack + SWC path](#rspack--swc-path-experimental).
- **Scope it.** Both paths let you gate the compiler to specific files via the `sources` option. Start scoped to a few components, verify SSR, then widen.
- **RSC boundaries are opt-in from the client side.** Compile the `'use client'` components that hydrate or manage state, keep Server Components directive-free, and verify the RSC payload path separately.

## Prerequisites

- **React ≥ 19** runtime (React on Rails' dummy apps and the Pro runtime already pin `~19.0.x`).
- **Shakapacker** (any bundler/transpiler combination it supports).
- Components that follow the [Rules of React](https://react.dev/reference/rules). The Compiler skips (bails out of) components it cannot safely optimize; it does not crash the build for them.

## Shakapacker + Babel path (canonical)

This is the verified, recommended path.

### 1. Install the plugin

```bash
# pnpm
pnpm add -D babel-plugin-react-compiler@^1.0.0
# npm
npm install --save-dev babel-plugin-react-compiler@^1.0.0
# yarn
yarn add --dev babel-plugin-react-compiler@^1.0.0
```

### 2. Add the plugin to `babel.config.js`, ordered FIRST

The React Compiler **must run before every other Babel plugin and preset** so it sees your original source before any other transform rewrites it (per the [React docs](https://react.dev/learn/react-compiler/installation)). In Babel, plugins run before presets, and within the `plugins` array they run in order — so the compiler must be the **first entry in `plugins`**.

A typical React on Rails `babel.config.js` builds on Shakapacker's preset. Prepend the compiler:

```js
// babel.config.js
const defaultConfigFunc = require('shakapacker/package/babel/preset.js');

module.exports = function createBabelConfig(api) {
  const resultConfig = defaultConfigFunc(api);
  const isProductionEnv = api.env('production');

  resultConfig.presets = [
    ...resultConfig.presets,
    ['@babel/preset-react', { runtime: 'automatic', development: !isProductionEnv }],
  ];

  // React Compiler MUST be first.
  resultConfig.plugins = [
    'babel-plugin-react-compiler', // ← first, ahead of everything else
    ...resultConfig.plugins,
  ];

  return resultConfig;
};
```

### 3. (Recommended) Scope the compiler with `sources`

You usually do not want to flip the compiler on for your entire app in one step — it changes the output of every component and can surface latent Rules-of-React violations. The plugin's `sources` option accepts **either an array of strings or a predicate `(filename) => boolean`**.

The array form is **not glob-based**: each entry is matched as a plain filename **substring** (the plugin checks whether the absolute filename _contains_ the string), so a literal `**` glob like `client/app/**/*.tsx` matches no real path and would silently skip every component. Use the predicate form when you want precise control — it receives the absolute filename and returns `true` to opt a file in:

```js
resultConfig.plugins = [
  [
    'babel-plugin-react-compiler',
    {
      // Compile only files under client/app/startup/compiler-ready/
      sources: (filename) =>
        typeof filename === 'string' && filename.includes('client/app/startup/compiler-ready'),
    },
  ],
  ...resultConfig.plugins,
];
```

Start scoped, verify SSR and your tests, then widen the predicate (or drop `sources` to compile everything).

### 4. Build and verify

```bash
# Your normal Shakapacker build, e.g.:
RAILS_ENV=test NODE_ENV=test bin/shakapacker
```

The compiler injects a memoization cache into each compiled component. In the emitted bundle, a compiled component contains memo-cache slot accesses (`$[0]`, `$[1]`, …) and `useMemoCache` calls — components it skipped do not. That is how you can confirm, against a real build, that the compiler ran and that your `sources` scope is correct.

> **Note:** `Symbol.for("react.memo_cache_sentinel")` appears in every React 19 bundle — it is part of React's runtime, not proof that the compiler ran. Look for `$[n]` memo-slot accesses **inside your component** instead.

## No double-application risk (verified)

A common worry is that Shakapacker's default Babel preset might already include the React Compiler (or `@babel/preset-react`), causing a double transform. **It does not.**

Inspecting the resolved `shakapacker/package/babel/preset.js` (Shakapacker 10.1) shows its full transform set is:

- `@babel/preset-env`
- `@babel/preset-typescript` (when present)
- `@babel/plugin-transform-runtime`

It contains **no** `@babel/preset-react` and **no** `babel-plugin-react-compiler`. Apps add `@babel/preset-react` themselves in `babel.config.js`, and the React Compiler is only present if you add it explicitly. So there is **no double-application** — the compiler runs exactly once, and only where you place it.

## SSR compatibility (verified)

React on Rails server-renders your components through the Node renderer / ExecJS server bundle (`renderToString` / `renderToPipeableStream`). The Compiler's output is plain React — auto-memoization is a render-time optimization that does not change the SSR contract.

This was verified end-to-end: a compiler-memoized example component (`ReactCompilerExample`) was built with the Babel path and server-rendered through the dummy app's server bundle, producing correct HTML with `hasErrors: false`. SSR works unchanged with the compiler enabled.

If you adopt the compiler, keep verifying SSR for your own components — especially any that read browser-only globals at render time, which is a Rules-of-React violation independent of the compiler.

## RSC boundary example

React Server Components do not change where you configure the Compiler: it still runs in the JavaScript transform pipeline. What changes is the scope you choose. Start with a small `'use client'` island that sits at the RSC boundary, then leave the Server Component itself without a directive so React on Rails can register it as a Server Component.

Client island compiled by the Babel `sources` predicate:

```tsx
// client/app/components/compiler-ready/RscQuantityPicker.client.tsx
'use client';

import { useState } from 'react';

export default function RscQuantityPicker({ initialQuantity }: { initialQuantity: number }) {
  const [quantity, setQuantity] = useState(initialQuantity);

  return (
    <button type="button" onClick={() => setQuantity((value) => value + 1)}>
      Quantity: {quantity}
    </button>
  );
}
```

Server Component that streams data and renders the compiled client island:

```tsx
// client/app/ror-auto-load-components/CompilerReadyRscProduct.tsx
import { loadProduct } from '../lib/products'; // replace with your own data-fetching helper
import RscQuantityPicker from '../components/compiler-ready/RscQuantityPicker.client';

export default async function CompilerReadyRscProduct({ productId }: { productId: string }) {
  const product = await loadProduct(productId);

  return (
    <section>
      <h2>{product.name}</h2>
      <RscQuantityPicker initialQuantity={1} />
    </section>
  );
}
```

Scope the Compiler to the client island, not to every RSC file at once:

```js
resultConfig.plugins = [
  [
    'babel-plugin-react-compiler',
    {
      sources: (filename) =>
        typeof filename === 'string' && filename.includes('client/app/components/compiler-ready/'),
    },
  ],
  ...resultConfig.plugins,
];
```

That keeps the first RSC rollout focused on the browser component that benefits from automatic memoization. The Server Component remains a normal RSC entry point: no `'use client'` directive, no browser-only hooks, and registration through `registerServerComponent()` / auto-registration as usual.

## Rspack + SWC path (experimental)

Many React on Rails teams use Rspack with SWC for build speed (see the [Babel → SWC migration guide](../migrating/babel-to-swc-migration.md)). Unfortunately, the SWC React Compiler story is **not production-viable as of June 2026**:

- There is **no first-party SWC plugin**. `@swc/plugin-react-compiler` does not exist on npm (404), and `@swc/core` has no native React Compiler support.
- The only candidate, `swc-plugin-react-compiler`, is a **brand-new third-party Wasm plugin** (first published 2026-06-09, currently `0.1.1`) with no published `@swc/core` peer-version constraints. SWC Wasm plugins do not follow semver for ABI compatibility with the `@swc/core` host, so a plugin built against one `@swc/core` can fail to load against another.

**Recommendation: the Babel path is canonical; the SWC path is experimental.** If you are on SWC/Rspack and want the React Compiler today, the most reliable option is to run the **Babel compiler plugin scoped to your compiler-ready components** while keeping SWC for the rest of the build, or to stay on SWC without the compiler until a first-party `@swc/core` integration ships. Track the React Compiler [working group](https://github.com/reactwg/react-compiler) and `@swc/core` releases before wiring the experimental SWC plugin into a production Rspack build.

If you do experiment with the SWC plugin, do it behind an env flag and scoped to a throwaway component first, exactly as with the Babel `sources` example above — and treat any build that succeeds as unverified until you have an SSR smoke test.

## Reference example in this repo

The standard dummy app (`react_on_rails/spec/dummy`) ships a scoped, runnable reference:

- **Component:** `client/app/startup/ReactCompilerExample.tsx` — a non-RSC component written with **no** manual memoization.
- **Babel wiring:** `babel.config.js` adds `babel-plugin-react-compiler` **first**, gated behind `REACT_COMPILER=1` and scoped via `sources` to just `ReactCompilerExample`, so the default build (which uses SWC) and the existing test suite are unaffected.
- **View / route:** `app/views/pages/react_compiler_example.html.erb` + the `react_compiler_example` route render it with `prerender: true` (SSR + hydration).
- **Lint wiring:** the root flat ESLint config uses `eslint-plugin-react-hooks` v6 and enables the compiler Rules-of-React checks for this scoped compiler example.

Build it with the compiler on (Babel path):

```bash
cd react_on_rails/spec/dummy
REACT_COMPILER=1 SHAKAPACKER_JAVASCRIPT_TRANSPILER=babel \
  RAILS_ENV=test NODE_ENV=test bin/shakapacker
```

The compiler is **off by default**, so nothing changes for the normal SWC build.

## Follow-ups (not yet covered here)

These are intentionally deferred and tracked separately:

- **Performance benchmark.** A concrete before/after re-render / interaction-latency benchmark to quantify the win is a follow-up.

## References

- [React Compiler (v1.0)](https://react.dev/learn/react-compiler)
- [React Compiler installation](https://react.dev/learn/react-compiler/installation)
- [Rules of React](https://react.dev/reference/rules)
- [Babel → SWC migration guide](../migrating/babel-to-swc-migration.md)
- [React Compiler working group](https://github.com/reactwg/react-compiler)
