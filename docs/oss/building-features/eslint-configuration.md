# ESLint Configuration

React on Rails does not scaffold an ESLint config into your app — linting is your app's concern, and the right setup depends on your stack. This page gives a **recommended, verified flat-config setup** for a React on Rails app, including the pieces that are specific to React on Rails (ignoring generated bundles, globals for server-side rendering) and the React 19.2-era rules that protect `useEffectEvent`.

## TL;DR

- Use **flat config** (`eslint.config.mjs`) — the default since ESLint 9; the legacy `.eslintrc` format is deprecated and removed in ESLint 10.
- Use **`eslint-plugin-react-hooks` v6 or later**. Version 6 is the first version whose `recommended` preset is flat-config native, and the first whose `exhaustive-deps` rule understands React's `useEffectEvent` — v5 actively gives **wrong guidance** for it (details [below](#useeffectevent-and-the-linter)).
- Ignore React on Rails' **auto-generated packs** (`**/generated/**`) and Shakapacker build output (`public/packs*/`).
- Enable **both browser and Node globals** for `app/javascript` — your components run in the browser _and_ in Node/ExecJS during server-side rendering.

## Installation

```bash
npm install --save-dev eslint @eslint/js eslint-plugin-react eslint-plugin-react-hooks eslint-config-prettier globals
# or: yarn add --dev / pnpm add -D
```

Notes:

- Keep `@eslint/js` on the same major version as `eslint` (e.g., both `^9` or both `^10`); npm fails resolution if they diverge.
- `eslint-plugin-react-hooks` must be `^6.0.0` or later. v7 (current) also works with this config and drops the legacy-format presets entirely.
- `eslint-config-prettier` is only needed if you format with Prettier (recommended).

## Recommended `eslint.config.mjs`

This exact config was verified against `eslint` 9.x, `eslint-plugin-react-hooks` 6.1.1, and `eslint-plugin-react` 7.37:

```js
// eslint.config.mjs
import js from '@eslint/js';
import { defineConfig, globalIgnores } from 'eslint/config';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import prettier from 'eslint-config-prettier';
import globals from 'globals';

export default defineConfig([
  // Never lint build output or React on Rails' auto-generated packs.
  globalIgnores([
    'public/packs/**',
    'public/packs-test/**',
    'app/javascript/**/generated/**',
    'node_modules/**',
  ]),

  {
    files: ['app/javascript/**/*.{js,jsx,ts,tsx}'],
    extends: [js.configs.recommended, react.configs.flat.recommended, reactHooks.configs.recommended],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
      // React on Rails code runs in the browser AND in Node/ExecJS during
      // server-side rendering, so enable both sets of globals.
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    settings: {
      react: { version: 'detect' },
    },
    rules: {
      // With the automatic JSX runtime (React 17+), importing React is unnecessary.
      'react/react-in-jsx-scope': 'off',
      // Most apps use TypeScript or skip PropTypes; remove if you use prop-types.
      'react/prop-types': 'off',
    },
  },

  // Webpack/Shakapacker config files are plain Node scripts.
  {
    files: ['config/webpack/**/*.js'],
    languageOptions: {
      sourceType: 'commonjs',
      globals: { ...globals.node },
    },
  },

  // Turn off stylistic rules that conflict with Prettier. Keep this last.
  prettier,
]);
```

### TypeScript

For TypeScript apps, add [typescript-eslint](https://typescript-eslint.io/getting-started/) and extend its recommended config alongside the ones above:

```bash
npm install --save-dev typescript-eslint
```

```js
import tseslint from 'typescript-eslint';

// In the app/javascript block:
extends: [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  react.configs.flat.recommended,
  reactHooks.configs.recommended,
],
```

## React on Rails specifics

### Ignore generated files

If you use [auto-bundling](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md), React on Rails writes generated entry points to `<source_entry_path>/generated/` (typically `app/javascript/packs/generated/`) and a generated server bundle under a `generated/` directory. These files are machine-written and regenerated on every build — linting them produces noise and CI churn. The `globalIgnores` block above excludes them, along with Shakapacker's compiled output in `public/packs/` and `public/packs-test/`.

### Globals for server-side rendering

With server-side rendering, the same component code executes in two environments: the browser, and a JavaScript runtime on the server (Node renderer or ExecJS). Code guarded by environment checks (e.g., `typeof window === 'undefined'`) legitimately references both browser globals (`window`, `document`) and Node globals (`process`, `global`). Enabling both `globals.browser` and `globals.node` for `app/javascript` avoids false `no-undef` errors in either direction.

If you keep [separate client and server entry files](./how-to-use-different-files-for-client-and-server-rendering.md) (e.g., `*.client.jsx` / `*.server.jsx`), you can tighten this with per-pattern overrides — browser globals only for `**/*.client.*`, Node globals only for `**/*.server.*`.

## `useEffectEvent` and the linter

### What `useEffectEvent` is for

React 19.2 added [`useEffectEvent`](https://react.dev/reference/react/useEffectEvent): it extracts the "event" part of an Effect's logic so the Effect doesn't re-run when values used only inside that event change. Effect Events always see the latest props and state, but they are **not reactive** — they never appear in dependency arrays.

The canonical example: a chat room should reconnect when `roomId` changes, but not when the notification `theme` changes:

```jsx
import { useEffect, useEffectEvent } from 'react';

const serverUrl = 'https://localhost:1234';

function ChatRoom({ roomId, theme }) {
  const onConnected = useEffectEvent(() => {
    // Always sees the latest theme — without making the Effect depend on it.
    showNotification('Connected!', theme);
  });

  useEffect(() => {
    const connection = createConnection(serverUrl, roomId);
    connection.on('connected', () => {
      onConnected();
    });
    connection.connect();
    return () => connection.disconnect();
  }, [roomId]); // ✅ theme changes do NOT reconnect the chat
  // ...
}
```

`useEffectEvent` requires **React 19.2 or later** at runtime. (React on Rails supports React 16+, so check your app's React version before adopting it.)

### Why the hooks plugin version matters

`useEffectEvent` only works if effect events are kept **out** of dependency arrays — that is its entire semantic. Only `eslint-plugin-react-hooks` v6+ knows this. Verified behavior on the example above:

| Plugin version              | Behavior on the code above                                                                                                                                                                                                                                                                       |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **v5** (`exhaustive-deps`)  | ❌ Wrong guidance: `React Hook useEffect has a missing dependency: 'onConnected'. Either include it or remove the dependency array.` Following it breaks effect-event semantics (the Effect re-runs on every render, or you wrap things in `useCallback` and reintroduce the staleness problem). |
| **v6+** (`exhaustive-deps`) | ✅ Clean pass. And if you _do_ add the effect event to the array, it flags it: `Functions returned from 'useEffectEvent' must not be included in the dependency array. Remove 'onConnected' from the list.`                                                                                      |

v6 also enforces the other `useEffectEvent` restrictions from the React docs — effect events may only be called from inside Effects in the same component or Hook, not passed around or called during render.

One more v6 difference worth knowing: in v5, `configs.recommended` was the **legacy** (eslintrc) format and fails outright inside flat config (flat config users needed `recommended-latest`). In v6, `configs.recommended` is flat-config native, and `recommended-legacy` exists for eslintrc holdouts. In v7, the legacy presets are gone.

### Opting into the React Compiler rules

v6+ also ships the React Compiler-powered diagnostics (purity, immutability, set-state-in-render, and friends). To enable them, swap the preset:

```js
extends: [js.configs.recommended, react.configs.flat.recommended, reactHooks.configs['recommended-latest']],
```

`recommended-latest` includes everything in `recommended` plus the compiler rules. These diagnostics are useful even if you have not adopted the compiler itself; if you have, see [React Compiler with React on Rails](https://www.shakacode.com/react-on-rails/docs/building-features/react-compiler/) for build-side setup.

## References

- [React 19.2 release post](https://react.dev/blog/2025/10/01/react-19-2) — `useEffectEvent` and `eslint-plugin-react-hooks` v6
- [`useEffectEvent` API reference](https://react.dev/reference/react/useEffectEvent)
- [Separating Events from Effects](https://react.dev/learn/separating-events-from-effects)
- [ESLint flat config migration guide](https://eslint.org/docs/latest/use/configure/migration-guide)
- [`eslint-plugin-react-hooks` on npm](https://www.npmjs.com/package/eslint-plugin-react-hooks)
