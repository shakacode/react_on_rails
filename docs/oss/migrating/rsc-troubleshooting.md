# RSC Migration: Troubleshooting and Common Pitfalls

This guide covers the most common problems you'll encounter when migrating to React Server Components, with concrete solutions for each. Use it as a reference when you hit errors or unexpected behavior.

> **Part 6 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous: [Third-Party Library Compatibility](rsc-third-party-libs.md)

## Serialization Boundary Issues

Everything passed from a Server Component to a Client Component must be serializable by React. This is the most frequent source of migration errors.

### What Can Cross the Server-to-Client Boundary

| Allowed                                         | Not Allowed                       |
| ----------------------------------------------- | --------------------------------- |
| Strings, numbers, booleans, `null`, `undefined` | Functions (except Server Actions) |
| Plain objects and arrays                        | Class instances                   |
| `Date` objects                                  | `WeakMap`, `WeakSet`              |
| `Map`, `Set`, typed arrays (React 19+)          | Symbols                           |
| `Promise` (resolved by `use()`)                 | DOM nodes                         |
| React elements (`<Component />`)                | Closures                          |
| Server Action references (`'use server'`)       |                                   |

### Common Error: Passing Functions

```jsx
// ERROR: "Functions cannot be passed directly to Client Components
// unless you explicitly expose it by marking it with 'use server'"
async function Page() {
  const handleClick = () => console.log('clicked');
  return <ClientButton onClick={handleClick} />; // Breaks!
}
```

**Fix 1:** Move the function to the Client Component:

```jsx
// Page.jsx -- Server Component
export default function Page() {
  return <ClientButton />;
}

// ClientButton.jsx
'use client';
export default function ClientButton() {
  return <button onClick={() => console.log('clicked')}>Click</button>;
}
```

**Fix 2:** Use a Server Action for server-side logic:

```jsx
// Page.jsx -- Server Component
async function Page() {
  async function handleSubmit(formData) {
    'use server';
    // In React on Rails, Server Actions run in Node.js and cannot access
    // Rails models directly. Call your Rails API endpoint instead:
    // Server-side fetch needs an absolute URL. Point RAILS_BASE_URL at your
    // internal Rails URL (for example http://127.0.0.1:3000 in development),
    // not the public-facing domain.
    // This server-side fetch will not include the browser's CSRF token, so
    // use an API-only route or another non-session auth boundary. If you use
    // `protect_from_forgery with: :null_session`, add another trust check
    // (for example signed tokens, API keys, or same-origin validation)
    // because `null_session` avoids the CSRF failure but does not
    // authenticate the request.
    const railsBaseUrl = process.env.RAILS_BASE_URL;
    if (!railsBaseUrl) {
      throw new Error('RAILS_BASE_URL environment variable is required for Server Actions');
    }
    await fetch(new URL('/api/items', railsBaseUrl), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: formData.get('name') }),
    });
  }
  return <ClientForm action={handleSubmit} />;
}
```

### Common Error: Passing Class Instances

```jsx
// ERROR: Class instances are not serializable
async function Page() {
  const user = await User.findById(1); // Returns a class instance
  return <ProfileCard user={user} />; // Breaks if ProfileCard is 'use client'
}
```

**Fix:** Convert to a plain object:

```jsx
async function Page() {
  const userRecord = await User.findById(1);
  const user = { id: userRecord.id, name: userRecord.name, email: userRecord.email };
  return <ProfileCard user={user} />;
}
```

## Import Chain Contamination

The `'use client'` directive operates at the **module level**. Once a file is marked `'use client'`, all its imports become part of the client bundle, even if those imported modules don't use client features.

### The Problem

```text
ClientComponent.jsx ('use client')
├── imports utils.js          → becomes client code
│   └── imports heavy-lib.js  → becomes client code (100KB wasted)
├── imports helpers.js        → becomes client code
│   └── imports db-utils.js   → becomes client code (SECURITY RISK)
```

### How to Detect It

Use the `server-only` package to create guardrails:

```jsx
// lib/db-utils.js
import 'server-only'; // Build error if imported into client code

export async function getUsers() {
  return await db.query('SELECT * FROM users');
}
```

If someone imports `db-utils.js` from a Client Component (directly or transitively), the build fails immediately rather than silently shipping server code to the client.

### How to Fix It

1. **Split shared files:** Separate server-only and client-safe utilities into different modules
2. **Use `server-only`:** Add the import to any module containing secrets, database access, or server-only logic
3. **Audit import chains:** Check what each `'use client'` file imports transitively

## Chunk Contamination

When a component with `'use client'` is also statically imported by a heavy Client Component, the RSC page may end up downloading much larger chunks than necessary. This doesn't always happen -- it depends on webpack's internal chunk group ordering -- but when it does, the impact can be severe (e.g., 382 KB instead of 8 KB).

### How to Detect It

After building, inspect your `react-client-manifest.json`. Each `'use client'` module has a `chunks` array listing the JS files the browser must download. If you see large vendor chunks listed for a small component, you have contamination:

```json
{
  "file:///app/components/HelloWorldHooks.jsx": {
    "id": "./components/HelloWorldHooks.jsx",
    "chunks": ["2", "2-b77936c4.js", "rsc-PostsPage", "rsc-PostsPage-d655b05a.js"],
    "name": "*"
  }
}
```

In this example, `HelloWorldHooks` (a tiny component) is mapped to PostsPage's chunk group, which includes a 375 KB vendor chunk containing lodash and moment. The browser downloads all of it.

You can also check the browser DevTools **Network** tab: load your RSC page, filter to JS files, and look for unexpectedly large downloads that contain unrelated libraries. Tools like **webpack-bundle-analyzer** can help visualize which modules ended up in which chunks.

### Why It Happens

The RSC webpack plugin builds the client manifest by iterating through all webpack chunk groups and recording which chunks contain each `'use client'` module. If a module appears in multiple chunk groups, the **last one processed overwrites** previous mappings.

When `PostsPage.jsx` (`'use client'`) statically imports `HelloWorldHooks.jsx` along with heavy dependencies (lodash, moment), `HelloWorldHooks.jsx` appears in PostsPage's chunk group. Depending on iteration order, the manifest may map `HelloWorldHooks` to PostsPage's chunks -- including the vendor chunk with lodash and moment.

This behavior is **deterministic for a given build** (not random), but the specific chunk group order depends on webpack internals that are hard to predict and can change when you add or remove components.

Redundant `'use client'` directives increase the risk: the RSC webpack plugin creates a separate async chunk for **every** file with `'use client'`. Adding the directive to components that are already client code (because they're imported by a `'use client'` parent) creates unnecessary chunks and manifest entries -- each one subject to the same last-write-wins overwrite.

### How to Fix It

Create a thin `'use client'` wrapper file that isolates the import tree:

```jsx
// HelloWorldHooksClient.jsx -- thin wrapper (new file)
'use client';
import HelloWorldHooks from './HelloWorldHooks';
export default HelloWorldHooks;
```

```jsx
// HelloWorldHooks.jsx -- NO 'use client' directive
import React, { useState } from 'react';

export default function HelloWorldHooks({ name }) {
  const [greeting, setGreeting] = useState(name);
  return <h3>Hello, {greeting}!</h3>;
}
```

```jsx
// RSCPage.jsx -- Server Component imports the wrapper
import HelloWorldHooks from './HelloWorldHooksClient';

export default function RSCPage() {
  return <HelloWorldHooks name="World" />;
}
```

The wrapper file doesn't appear in PostsPage's import tree, so the RSC plugin always maps it to its own small async chunk (~8 KB), regardless of chunk group ordering.

> **When to apply this:** Check the manifest or Network tab after building. If an RSC page downloads chunks larger than expected, trace which `'use client'` module causes it and introduce a wrapper. For shared components used by both RSC pages and heavy Client Component trees, the wrapper is a safe preventive measure.

## Accidental Client Components

A component that should be a Server Component becomes a Client Component because it's imported by a `'use client'` file.

### The Problem

```jsx
// BAD: ServerComponent becomes client code via import
'use client';
import ServerComponent from './ServerComponent';

export function ClientWrapper() {
  return <ServerComponent />; // This is now client code!
}
```

### The Fix: Children Pattern

```jsx
// GOOD: Pass Server Components as children
'use client';
export function ClientWrapper({ children }) {
  return <div>{children}</div>;
}

// In a Server Component parent:
import ClientWrapper from './ClientWrapper';
import ServerComponent from './ServerComponent';

export default function Page() {
  return (
    <ClientWrapper>
      <ServerComponent /> {/* Stays a Server Component */}
    </ClientWrapper>
  );
}
```

### Why It Works

The Server Component (`Page`) is the "owner" -- it decides what `ServerComponent` receives as props and renders it on the server. `ClientWrapper` receives pre-rendered content as `children`, not the component definition.

## Hydration Mismatches

Hydration mismatches occur when server-rendered HTML doesn't match what React produces during client-side hydration.

### Common Causes

| Cause                | Example                                      | Fix                                                                 |
| -------------------- | -------------------------------------------- | ------------------------------------------------------------------- |
| Timestamps           | `new Date()` differs server vs client        | Use `suppressHydrationWarning` or render in `useEffect`             |
| Browser APIs         | `window.innerWidth` is `undefined` on server | Guard with `typeof window !== 'undefined'` or use `useEffect`       |
| `localStorage` reads | Theme preference stored in browser           | Read from cookie on server, or delay render with `useEffect`        |
| Random values        | `Math.random()` produces different results   | Generate on server, pass as prop                                    |
| Browser extensions   | Extensions inject unexpected HTML            | Cannot prevent; use `suppressHydrationWarning` on affected elements |
| Invalid HTML nesting | `<p>` inside `<p>`, `<div>` inside `<p>`     | Fix HTML structure                                                  |

### Error Messages

- `"Text content does not match server-rendered HTML"`
- `"Hydration failed because the initial UI does not match what was rendered on the server"`
- `"There was an error while hydrating. Because the error happened outside of a Suspense boundary, the entire root will switch to client rendering."`

### The "Mounted" Pattern for Client-Only Rendering

```jsx
'use client';

import { useState, useEffect } from 'react';

function ThemeToggle() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  if (!mounted) return null; // Server and first client render return null

  // Only runs on client
  return <button>{localStorage.getItem('theme')}</button>;
}
```

### `suppressHydrationWarning`

For elements that intentionally differ between server and client:

```jsx
<time suppressHydrationWarning>{new Date().toLocaleDateString()}</time>
```

This suppresses the warning for **this element only** (not its descendants) and does not fix the mismatch -- use it only for non-critical content. If child elements also differ, each needs its own `suppressHydrationWarning`.

> **Warning:** The `if (!mounted) return null` pattern causes **Cumulative Layout Shift (CLS)** -- the element occupies no space on first paint, then pops in after hydration. Only use it for small, positionally stable UI elements (icon buttons, toggles). For anything that affects page layout, read the preference from a server-readable cookie to render the correct value on first paint (see the [Theme Provider](rsc-context-and-state.md#theme-provider-no-flash-of-wrong-theme) section), or use `suppressHydrationWarning` on non-layout-critical elements.

## Error Boundary Limitations

Error Boundaries do **not** catch errors thrown during the initial Server Component HTML stream -- those errors bypass client-side Error Boundaries entirely. However, errors during RSC payload fetches (client-side navigations, `refetchComponent` calls) surface as `ServerComponentFetchError` and **can** be caught by Error Boundaries.

### Workaround: Retry with Page Reload

Since React on Rails renders each component tree independently via `stream_react_component`, a full page reload re-renders all Server Components on the server:

```jsx
'use client';

import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }) {
  function retry() {
    window.location.reload(); // Re-renders Server Components on the server
  }

  return (
    <div>
      <p>Something went wrong</p>
      <button onClick={retry}>Retry</button>
    </div>
  );
}

export default function PageErrorBoundary({ children }) {
  return <ErrorBoundary FallbackComponent={ErrorFallback}>{children}</ErrorBoundary>;
}
```

### Finer-Grained Retry with `refetchComponent`

React on Rails Pro provides `useRSC()` with a `refetchComponent` method that re-fetches a single Server Component's RSC payload without a full page reload:

```jsx
'use client';

import { ErrorBoundary } from 'react-error-boundary';
import { useRSC } from 'react-on-rails-pro/RSCProvider';
import { isServerComponentFetchError } from 'react-on-rails-pro/ServerComponentFetchError';

function ErrorFallback({ error, resetErrorBoundary }) {
  const { refetchComponent } = useRSC();

  function retry() {
    if (isServerComponentFetchError(error)) {
      const { serverComponentName, serverComponentProps } = error;
      refetchComponent(serverComponentName, serverComponentProps)
        .catch((err) => console.error('Retry failed:', err))
        .finally(() => resetErrorBoundary());
    } else {
      window.location.reload();
    }
  }

  return (
    <div>
      <p>Something went wrong</p>
      <button onClick={retry}>Retry</button>
    </div>
  );
}

export default function PageErrorBoundary({ children }) {
  return <ErrorBoundary FallbackComponent={ErrorFallback}>{children}</ErrorBoundary>;
}
```

`refetchComponent` re-fetches the RSC payload for the named component with `enforceRefetch: true`, bypassing any cached promise. This is the React on Rails equivalent of Next.js's `router.refresh()`.

## `'use client'` Directive Mistakes

### Only at the Boundary

`'use client'` marks the server-to-client boundary, not individual components. Components imported below a `'use client'` file are automatically client code -- they don't need their own directive. Adding it redundantly creates unnecessary webpack async chunks and increases [chunk contamination](#chunk-contamination) risk. See [the boundary rule](rsc-component-patterns.md#use-client-marks-a-boundary-not-a-component-type) for details.

### Must Be at the Very Top

**BAD:** Directive after imports

```text
import { useState } from 'react';
'use client'; // Too late -- will not work
```

**GOOD:** Directive before everything (comments allowed above)

```jsx
'use client';
import { useState } from 'react';
```

### Must Use Quotes, Not Backticks

**BAD:**

```text
`use client`;
```

**GOOD:**

```jsx
'use client';
```

### Confusing `'use client'` with `'use server'`

- `'use client'` marks a file's components as **Client Components**
- `'use server'` marks **Server Actions** (functions callable from the client) -- NOT Server Components
- Server Components are the **default** and need no directive

## Performance Pitfalls

### Server Waterfalls

The most common performance regression. Sequential `await` calls create waterfalls on the server:

```jsx
// BAD: Sequential fetching (750ms total)
async function Page() {
  const user = await getUser(); // 200ms
  const stats = await getStats(user.id); // 300ms (waits for user)
  const posts = await getPosts(user.id); // 250ms (waits for user AND stats)
  // Total: 750ms (sequential)
}
```

**Fix 1:** If the user ID is available from props or route params, all three fetches can run in parallel:

```jsx
// GOOD: Parallel fetching when userId is available upfront (300ms total)
async function Page({ userId }) {
  const [user, stats, posts] = await Promise.all([getUser(userId), getStats(userId), getPosts(userId)]);
}
```

**Fix 2:** If you must fetch the user first (e.g., stats and posts depend on user data), fetch the user first, then parallelize the dependent calls:

```jsx
// GOOD: Fetch user first, then parallelize dependent calls (500ms total)
async function Page() {
  const user = await getUser(); // 200ms
  const [stats, posts] = await Promise.all([
    getStats(user.id), // 300ms ── start simultaneously
    getPosts(user.id), // 250ms
  ]);
  // Total: 200 + 300 = 500ms (instead of 750ms)
}
```

See [Data Fetching Migration](rsc-data-fetching.md) for detailed patterns.

### Missing Suspense Boundaries

Without Suspense, Server Components perform similarly to traditional SSR. Benchmarks show that the performance benefit comes from **streaming with Suspense**, not Server Components alone.

### RSC Payload Duplication

The RSC payload (a serialized representation of the component tree) is embedded in `<script>` tags alongside the server-rendered HTML. This payload is used by React on the client to reconcile the component tree without re-rendering from scratch. The HTML and the RSC payload are not exact duplicates -- the payload contains component structure and props, not rendered markup -- but they do represent overlapping information, which increases document size. Monitor RSC payload size to ensure it stays reasonable.

## Testing Strategies

### The Fundamental Challenge

Async Server Components introduce new testing challenges. Vitest and Jest can test async Server Components as **plain async functions** (call the function, `await` the result, assert on the returned JSX). However, **rendering them through React's component pipeline** (e.g., with `@testing-library/react`) does not yet have full support -- React's test renderer does not handle the async server rendering path. The React team has published guidance on testing patterns, and `@testing-library/react` is actively adding RSC support.

### Recommended Testing Approach

```text
Unit Tests (Vitest/Jest)
├── Client Components -- full support with hooks mocking
├── Synchronous Server Components -- basic rendering tests
├── Server Actions -- test as regular async functions
└── Utility/helper functions -- standard unit tests

Integration Tests
├── Component composition -- Server + Client together
└── Data fetching flows -- mock at the boundary

E2E Tests (Playwright)
├── Async Server Components -- the only reliable option currently
├── Streaming behavior -- verify progressive rendering
├── Hydration correctness -- verify interactivity
└── Full page flows -- navigation, forms, etc.
```

### Testing Server Actions

Server Actions can be tested as regular async functions:

```jsx
// actions.test.js
import { createUser } from './actions';

it('rejects invalid input', async () => {
  const formData = new FormData();
  formData.set('name', 'Alice');
  // email is missing -- expect validation error
  const result = await createUser(formData);
  expect(result.error).toBeDefined();
});

it('accepts valid input', async () => {
  const formData = new FormData();
  formData.set('name', 'Alice');
  formData.set('email', 'alice@example.com');
  const result = await createUser(formData);
  expect(result).toBeUndefined(); // createUser returns no value on success
});
```

## TypeScript Considerations

### Async Component Type Error

The most common TypeScript issue:

**Error:** `"'App' cannot be used as a JSX component. Its return type 'Promise<JSX.Element>' is not a valid JSX element type."`

**Fix:** Upgrade to TypeScript 5.1.2+ with `@types/react@19` (React 19 projects) or `@types/react` 18.2.8+ (React 18 projects), or omit the explicit return type annotation:

```tsx
// BROKEN: Explicit return type triggers error in older TS
async function Page(): Promise<React.ReactNode> {
  const data = await fetchData();
  return <div>{data.title}</div>;
}

// FIXED: Let TypeScript infer the type
async function Page() {
  const data = await fetchData();
  return <div>{data.title}</div>;
}
```

### Runtime Validation for Server Actions

TypeScript only provides compile-time checking. Server Actions are public endpoints that can receive arbitrary data. Use runtime validation:

```tsx
'use server';
import { z } from 'zod';

const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
});

export async function createUser(formData: FormData) {
  const parsed = CreateUserSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten() };
  }

  await db.users.create({ data: parsed.data });
}
```

## Bundle Analysis Tools

| Tool                                | Purpose                                                          |
| ----------------------------------- | ---------------------------------------------------------------- |
| **webpack-bundle-analyzer**         | Analyze client bundle composition and module sizes               |
| **RSC Devtools** (Chrome extension) | Visualize RSC streaming data, server vs client rendering         |
| **DevConsole**                      | Color-coded component boundaries (green = client, blue = server) |
| **RSC Parser**                      | Parse the React Flight wire format to inspect the component tree |
| **`webpack-stats-explorer`**        | Interactive exploration of webpack stats for chunk analysis      |

### Key Metrics to Track

- **JavaScript bundle size** (before/after migration, per page)
- **RSC Payload size** (the hidden cost -- check this grows reasonably)
- **LCP / TTFB / TBT** (Core Web Vitals)
- **Time to Interactive** (hydration cost)
- **Server render latency** (new metric to monitor after migration)

## Error Message Catalog

| Error Message                                                                                                                | Cause                                                                                                                                                                                                    | Solution                                                                                                                                                                                                                                    |
| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `"Functions cannot be passed directly to Client Components unless you explicitly expose it by marking it with 'use server'"` | Passing a function prop from Server to Client Component                                                                                                                                                  | Use Server Actions, or define the function in the Client Component                                                                                                                                                                          |
| `"You're importing a component that needs useState/useEffect..."`                                                            | Using hooks in a Server Component                                                                                                                                                                        | Add `'use client'` to the component file                                                                                                                                                                                                    |
| `"Only plain objects, and a few built-ins, can be passed to Client Components..."`                                           | Passing class instances or non-serializable values                                                                                                                                                       | Convert to plain objects with `.toJSON()` or manual serialization                                                                                                                                                                           |
| `"async/await is not yet supported in Client Components"`                                                                    | Making a Client Component async. This is an intentional design constraint, not a temporary limitation -- Client Components re-render on state changes, which is incompatible with async rendering.       | Move async logic to a Server Component, or use `useEffect`/`use()`                                                                                                                                                                          |
| `"A component was suspended by an uncached promise..."`                                                                      | Creating a promise inside a Client Component and passing it to `use()`                                                                                                                                   | Pass the promise from a Server Component as a prop, or use a Suspense-compatible library like TanStack Query. See [Common `use()` Mistakes](rsc-data-fetching.md#common-use-mistakes-in-client-components)                                  |
| `"createContext is not supported in Server Components"`                                                                      | Using `createContext` or `useContext` in a Server Component                                                                                                                                              | Move context to a `'use client'` provider wrapper                                                                                                                                                                                           |
| `"'App' cannot be used as a JSX component. Its return type 'Promise<JSX.Element>' is not a valid JSX element type"`          | TypeScript doesn't recognize async components                                                                                                                                                            | Upgrade to TS 5.1.2+ and `@types/react@19` (or `@types/react` 18.2.8+ for React 18), or omit return type                                                                                                                                    |
| RSC page downloads unexpectedly large chunks                                                                                 | A shared component with `'use client'` appears in multiple chunk groups; webpack's manifest may map it to a heavy chunk group containing unrelated dependencies (depends on chunk group iteration order) | Inspect `react-client-manifest.json` for oversized chunk mappings. If found, create a thin `'use client'` wrapper file for the RSC import. See [Chunk Contamination](#chunk-contamination) above                                            |
| `"Text content does not match server-rendered HTML"`                                                                         | Hydration mismatch                                                                                                                                                                                       | Ensure identical rendering on server and client; use `suppressHydrationWarning` for intentional differences                                                                                                                                 |
| `"Refs cannot be used in Server Components, nor passed to Client Components"`                                                | Using the `ref` prop on any element inside a Server Component -- including on Client Components. The Flight serializer rejects the literal `ref` prop before checking the target type.                   | Remove the `ref` prop. Refs are a client-side concept -- if a Client Component needs a ref, it should create one itself with `useRef()`. While `React.createRef()` is callable on the server, the result cannot be attached to any element. |
| `"Both 'react-on-rails' and 'react-on-rails-pro' packages are installed"`                                                    | Both packages installed as separate top-level dependencies, often due to yalc link issues                                                                                                                | Ensure only `react-on-rails-pro` is in your `package.json`; the base package is installed automatically as a dependency. See [Duplicate Package Detection](#duplicate-package-detection)                                                    |
| `ReferenceError: performance is not defined`                                                                                 | Node renderer VM context missing the `performance` global. Triggered by `React.lazy()` in dev mode                                                                                                       | Enable `supportModules: true` and add `performance` via `additionalContext`. See [Node Renderer VM Context](#node-renderer-vm-context----missing-globals)                                                                                   |
| `"global object mismatch"`                                                                                                   | `react-on-rails` and `react-on-rails-pro` resolved from different sources (e.g., npm vs yalc)                                                                                                            | Force consistent resolution with `pnpm.overrides` or `yarn.resolutions`. See [Version Mismatch](#version-mismatch----global-object-mismatch)                                                                                                |
| SSR hangs indefinitely / request timeout on large RSC payloads                                                               | Stream backpressure deadlock when RSC payload exceeds 16 KB                                                                                                                                              | Update to latest React on Rails Pro. See [Stream Backpressure Deadlock](#stream-backpressure-deadlock)                                                                                                                                      |
| `"The 'react-on-rails' package version does not match the gem version"`                                                      | Gem and npm package installed at different versions                                                                                                                                                      | Install the npm package version matching your gem. See [Gem and npm Package Version Mismatch](#gem-and-npm-package-version-mismatch)                                                                                                        |
| `"The 'react-on-rails' package version is not an exact version"`                                                             | Using semver ranges (`^`, `~`, `*`) instead of an exact version in package.json                                                                                                                          | Pin to the exact version without range operators. See [Gem and npm Package Version Mismatch](#gem-and-npm-package-version-mismatch)                                                                                                         |

## Environment Variable Access

### Server Components

Server Components run on the server (in the node renderer), so they have access to **all** environment variables available to the Node.js process:

```jsx
// Server Component -- full access to Node.js process.env
async function DBComponent() {
  // WARNING: If INTERNAL_API_URL points back to the same Rails server,
  // this creates a circular request (Node renderer → Rails → Node renderer).
  // Use a direct database call or internal service URL that bypasses Rails routing.
  const data = await fetch(process.env.INTERNAL_API_URL); // Works if this env var holds an HTTP(S) URL
  const dbUrl = process.env.DATABASE_URL; // Works
  const secret = process.env.API_SECRET; // Works
}
```

### Client Components

Client Components only have access to environment variables that are explicitly injected into the webpack bundle. In Shakapacker, you control this via `webpack.EnvironmentPlugin` or `webpack.DefinePlugin`:

```js
// config/webpack/webpack.config.js (Shakapacker)
const { generateWebpackConfig } = require('shakapacker');
const webpack = require('webpack');

const webpackConfig = generateWebpackConfig();

// Only these variables are available in Client Components
webpackConfig.plugins.push(new webpack.EnvironmentPlugin(['RAILS_ENV', 'PUBLIC_API_URL']));

module.exports = webpackConfig;
```

```jsx
'use client';
function ClientComp() {
  const apiUrl = process.env.PUBLIC_API_URL; // Works (injected by webpack)
  const secret = process.env.API_SECRET; // undefined (not injected)
}
```

**Security:** Never add secret keys to webpack's `EnvironmentPlugin` -- they would be embedded in the client bundle. Use `server-only` to protect modules that access secrets. Without it, secrets could accidentally leak to the client through import chains.

## React on Rails-Specific Issues

The sections above cover generic RSC pitfalls. The following issues are specific to the React on Rails stack and its node renderer architecture.

### Stream Backpressure Deadlock

**Symptoms:** SSR hangs indefinitely when the RSC payload is large (> 16 KB). The page never loads and eventually times out.

**Cause:** This was a bug in `react-on-rails-pro` where the internal RSC stream teeing mechanism could deadlock under backpressure with large payloads.

**Fix:** Upgrade to a release that includes this patch (`react-on-rails-pro`
16.4.0.rc.3+ was the first patched line). If a newer stable release is
available, prefer that and check the
[CHANGELOG](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md)
for the current recommendation. See also
[PR #2444](https://github.com/shakacode/react_on_rails/pull/2444).

### Node Renderer VM Context -- Missing Globals

**Symptoms:** Cryptic errors like `ReferenceError: performance is not defined` when rendering Server Components. Often triggered by `React.lazy()` which calls `performance.now()` internally in development mode.

**Root cause:** The node renderer runs your JavaScript in an isolated V8 VM context (`vm.createContext`). By default, the VM context only includes basic globals. Node.js-specific globals like `performance`, `Buffer`, `TextDecoder`, etc. must be explicitly added.

**Fix:** Enable `supportModules` in your node renderer configuration to inject common Node.js globals:

```js
// node-renderer.js (or wherever you configure the renderer)
module.exports = {
  supportModules: true, // Injects: Buffer, TextDecoder, TextEncoder,
  // URLSearchParams, ReadableStream, process,
  // setTimeout, setInterval, setImmediate,
  // clearTimeout, clearInterval, clearImmediate,
  // queueMicrotask
};
```

Or set the environment variable:

```bash
RENDERER_SUPPORT_MODULES=true
```

For globals not covered by `supportModules` (e.g., `performance`), use `additionalContext`:

```js
module.exports = {
  supportModules: true,
  additionalContext: {
    performance: require('perf_hooks').performance,
  },
};
```

### Version Mismatch -- "Global Object Mismatch"

**Symptoms:** Runtime error `"global object mismatch"` when both `react-on-rails` and `react-on-rails-pro` JS packages are installed.

**Root cause:** The `react-on-rails` and `react-on-rails-pro` packages share internal global state. If they resolve from different sources (e.g., one from npm and one from yalc during development), each gets its own copy of the shared module, and internal checks detect the mismatch.

**Fix:** Force consistent package resolution using your package manager's override mechanism:

```json
// package.json (pnpm)
{
  "pnpm": {
    "overrides": {
      "react-on-rails": "file:../path/to/local/package",
      "react-on-rails-pro": "file:../path/to/local/pro-package"
    }
  }
}
```

```json
// package.json (yarn)
{
  "resolutions": {
    "react-on-rails": "file:../path/to/local/package"
  }
}
```

When using **yalc** for local development:

1. Publish all packages in dependency order: base package first, then pro
2. Ensure both packages resolve to the same version source
3. Run `yalc installations show` to verify no stale installations exist

### Duplicate Package Detection

**Symptoms:** Boot-time error: `"Both 'react-on-rails' and 'react-on-rails-pro' packages are installed."` This prevents the Rails application from starting.

**Root cause:** The `react_on_rails` gem validates that only one of the JavaScript packages is installed. During development with yalc, both packages may appear in `node_modules` simultaneously if the yalc link chain isn't set up correctly.

**Fix:**

1. **Verify your package setup:** `react-on-rails-pro` includes `react-on-rails` as a direct dependency. You should only have `react-on-rails-pro` in your `package.json` -- the base package is automatically installed through the dependency chain.

2. **Check for stale yalc links:**

   ```bash
   # Remove stale yalc installations
   yalc installations clean
   # Re-publish and re-add in the correct order
   cd /path/to/react-on-rails && yalc publish
   cd /path/to/react-on-rails-pro && yalc publish
   cd /path/to/your-app && yalc add react-on-rails-pro
   ```

3. **Inspect `node_modules`:** Confirm that `node_modules/react-on-rails` is a symlink pointing into `react-on-rails-pro`'s dependency tree, not a separate top-level installation.

### Gem and npm Package Version Mismatch

React on Rails requires the gem and npm package versions to match exactly. The validation runs at Rails boot time and will prevent the application from starting if versions are mismatched or improperly specified.

**Symptom 1 -- Version mismatch:**

```text
**ERROR** ReactOnRails: The 'react-on-rails' package version does not match the gem version.

Package: 16.3.0
    Gem: 16.4.0
```

This happens when you upgrade the gem (e.g., `bundle update react_on_rails`) without upgrading the npm package, or vice versa. Both must be the same version.

**Fix:** Install the npm package version that matches your gem:

```bash
# Check your gem version
bundle show react_on_rails

# Install the matching npm package (use your package manager)
yarn add react-on-rails@16.4.0 --exact
# or
pnpm add react-on-rails@16.4.0 --save-exact
# or
npm install react-on-rails@16.4.0 --save-exact
```

**Symptom 2 -- Non-exact version:**

```text
**ERROR** ReactOnRails: The 'react-on-rails' package version is not an exact version.

Detected: ^16.4.0
     Gem: 16.4.0
```

React on Rails does not allow semver ranges (`^`, `~`, `>`, `<`, `*`) or special tags (`latest`, `next`, `beta`) in `package.json`. The version must be an exact match.

**Fix:** Remove the range operator and pin to the exact version:

```json
{
  "dependencies": {
    "react-on-rails": "16.4.0"
  }
}
```

**Symptom 3 -- Pro gem with base package:**

```text
**ERROR** ReactOnRails: You have the Pro gem installed but are using the base 'react-on-rails' package.
```

If you have the `react_on_rails_pro` gem in your Gemfile, you must use the `react-on-rails-pro` npm package, not `react-on-rails`.

**Fix:** Replace the base package with the Pro package:

```bash
yarn remove react-on-rails && yarn add react-on-rails-pro@16.4.0 --exact
```

**Symptom 4 -- Pro package without Pro gem:**

```text
**ERROR** ReactOnRails: You have the 'react-on-rails-pro' package installed but the Pro gem is not installed.
```

The `react-on-rails-pro` npm package requires the `react_on_rails_pro` gem.

**Fix:** Either add the Pro gem to your Gemfile (`gem 'react_on_rails_pro'`) and run `bundle install`, or switch to the base npm package if you don't have a Pro license.

> **Tip:** Set `REACT_ON_RAILS_SKIP_VALIDATION=true` to temporarily bypass version validation during setup or generator runs.

## When NOT to Use Server Components

Server Components are not always the right choice:

- **Highly interactive interfaces:** Dashboards, design tools, real-time collaboration
- **Offline-first applications:** Systems designed around local persistence
- **Rapid iteration teams:** The architectural constraints may slow development velocity during early prototyping

For these cases, keep components as Client Components and adopt Server Components selectively for data-heavy, display-oriented sections.

## Next Steps

- [Component Tree Restructuring Patterns](rsc-component-patterns.md) -- how to restructure your component tree
- [Context, Providers, and State Management](rsc-context-and-state.md) -- how to handle Context and global state
- [Data Fetching Migration](rsc-data-fetching.md) -- migrating from useEffect to server-side fetching
- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
