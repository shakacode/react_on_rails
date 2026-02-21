# RSC Migration: Troubleshooting and Common Pitfalls

This guide covers the most common problems you'll encounter when migrating to React Server Components, with concrete solutions for each. Use it as a reference when you hit errors or unexpected behavior.

> **Part 5 of the [RSC Migration Series](migrating-to-rsc.md)**

## Serialization Boundary Issues

Everything passed from a Server Component to a Client Component must be serializable by React. This is the most frequent source of migration errors.

### What Can Cross the Server-to-Client Boundary

| Allowed | Not Allowed |
|---------|-------------|
| Strings, numbers, booleans, `null`, `undefined` | Functions (except Server Actions) |
| Plain objects and arrays | Class instances |
| `Date` objects | `Map`, `Set`, `WeakMap`, `WeakSet` |
| `Promise` (resolved by `use()`) | Symbols |
| React elements (`<Component />`) | DOM nodes |
| Server Action references (`'use server'`) | Closures |

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
    await db.items.create({ data: { name: formData.get('name') } });
  }
  return <ClientForm action={handleSubmit} />;
}
```

### Common Error: Passing Class Instances

```jsx
// ERROR: Class instances are not serializable
async function Page() {
  const user = await User.findById(1); // Returns a class instance
  return <ProfileCard user={user} />;  // Breaks if ProfileCard is 'use client'
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

```
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
      <ServerComponent />  {/* Stays a Server Component */}
    </ClientWrapper>
  );
}
```

### Why It Works

The Server Component (`Page`) is the "owner" -- it decides what `ServerComponent` receives as props and renders it on the server. `ClientWrapper` receives pre-rendered content as `children`, not the component definition.

## Hydration Mismatches

Hydration mismatches occur when server-rendered HTML doesn't match what React produces during client-side hydration.

### Common Causes

| Cause | Example | Fix |
|-------|---------|-----|
| Timestamps | `new Date()` differs server vs client | Use `suppressHydrationWarning` or render in `useEffect` |
| Browser APIs | `window.innerWidth` is `undefined` on server | Guard with `typeof window !== 'undefined'` or use `useEffect` |
| `localStorage` reads | Theme preference stored in browser | Read from cookie on server, or delay render with `useEffect` |
| Random values | `Math.random()` produces different results | Generate on server, pass as prop |
| Browser extensions | Extensions inject unexpected HTML | Cannot prevent; use `suppressHydrationWarning` on affected elements |
| Invalid HTML nesting | `<p>` inside `<p>`, `<div>` inside `<p>` | Fix HTML structure |

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

  if (!mounted) return null; // Server render returns null

  // Only runs on client
  return <button>{localStorage.getItem('theme')}</button>;
}
```

### `suppressHydrationWarning`

For elements that intentionally differ between server and client:

```jsx
<time suppressHydrationWarning>
  {new Date().toLocaleDateString()}
</time>
```

This suppresses the warning but does not fix the mismatch -- use it only for non-critical content.

## Error Boundary Limitations

Error Boundaries do **not** catch errors thrown in Server Components. Errors from Server Components are uncaught on the client.

### Workaround: Retry with `router.refresh()`

```jsx
'use client';

import { useRouter, startTransition } from 'next/navigation';
import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }) {
  const router = useRouter();

  function retry() {
    startTransition(() => {
      router.refresh();       // Re-renders Server Components on the server
      resetErrorBoundary();   // Resets client error boundary state
    });
  }

  return (
    <div>
      <p>Something went wrong</p>
      <button onClick={retry}>Retry</button>
    </div>
  );
}

export default function PageErrorBoundary({ children }) {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      {children}
    </ErrorBoundary>
  );
}
```

## `'use client'` Directive Mistakes

### Must Be at the Very Top

```jsx
// BAD: Directive after imports
import { useState } from 'react';
'use client'; // Too late -- will not work

// GOOD: Directive before everything (comments allowed above)
'use client';
import { useState } from 'react';
```

### Must Use Quotes, Not Backticks

```jsx
// BAD
`use client`

// GOOD
'use client'
"use client"
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
  const user = await getUser();           // 200ms
  const stats = await getStats(user.id);  // 300ms (waits for user)
  const posts = await getPosts(user.id);  // 250ms (waits for stats)
}

// GOOD: Parallel fetching (300ms total)
async function Page({ userId }) {
  const [user, stats, posts] = await Promise.all([
    getUser(userId),
    getStats(userId),
    getPosts(userId),
  ]);
}
```

See [Data Fetching Migration](rsc-data-fetching.md) for detailed patterns.

### Missing Suspense Boundaries

Without Suspense, Server Components perform similarly to traditional SSR. Benchmarks show that the performance benefit comes from **streaming with Suspense**, not Server Components alone.

### RSC Payload Duplication

Server-rendered content is sent twice: once as visible HTML and once as the RSC payload (serialized component tree) in `<script>` tags. This increases document size. Monitor RSC payload size to ensure it stays reasonable.

## Testing Strategies

### The Fundamental Challenge

Async Server Components are a new paradigm that existing testing tools were not designed for. **Vitest does not support async Server Components** as of early 2026.

### Recommended Testing Approach

```
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

it('creates a user', async () => {
  const formData = new FormData();
  formData.set('name', 'Alice');
  const result = await createUser(formData);
  expect(result.name).toBe('Alice');
});
```

## TypeScript Considerations

### Async Component Type Error

The most common TypeScript issue:

**Error:** `"'App' cannot be used as a JSX component. Its return type 'Promise<JSX.Element>' is not a valid JSX element type."`

**Fix:** Upgrade to TypeScript 5.1.2+ with `@types/react` 18.2.8+, or omit the explicit return type annotation:

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

### Params Must Be Awaited (Next.js 15+)

```tsx
// BROKEN in Next.js 15
export default function Post({ params }: { params: { id: string } }) {
  const post = getBlogPost(params.id);
}

// FIXED: params is now a Promise
export default async function Post({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const post = await getBlogPost(id);
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

| Tool | Purpose |
|------|---------|
| **webpack-bundle-analyzer** | Analyze client bundle composition and module sizes |
| **RSC Devtools** (Chrome extension) | Visualize RSC streaming data, server vs client rendering |
| **DevConsole** | Color-coded component boundaries (green = client, blue = server) |
| **RSC Parser** | Parse the React Flight wire format to inspect the component tree |
| **`@next/bundle-analyzer`** | Next.js-specific wrapper around webpack-bundle-analyzer |

### Key Metrics to Track

- **JavaScript bundle size** (before/after migration, per page)
- **RSC Payload size** (the hidden cost -- check this grows reasonably)
- **LCP / TTFB / TBT** (Core Web Vitals)
- **Time to Interactive** (hydration cost)
- **Server render latency** (new metric to monitor after migration)

## Error Message Catalog

| Error Message | Cause | Solution |
|---|---|---|
| `"Functions cannot be passed directly to Client Components unless you explicitly expose it by marking it with 'use server'"` | Passing a function prop from Server to Client Component | Use Server Actions, or define the function in the Client Component |
| `"You're importing a component that needs useState/useEffect..."` | Using hooks in a Server Component | Add `'use client'` to the component file |
| `"Only plain objects, and a few built-ins, can be passed to Client Components..."` | Passing class instances or non-serializable values | Convert to plain objects with `.toJSON()` or manual serialization |
| `"async/await is not yet supported in Client Components"` | Making a Client Component async | Move async logic to a Server Component, or use `useEffect`/`use()` |
| `"createContext is not supported in Server Components"` | Using `createContext` or `useContext` in a Server Component | Move context to a `'use client'` provider wrapper |
| `"'App' cannot be used as a JSX component. Its return type 'Promise<JSX.Element>' is not a valid JSX element type"` | TypeScript doesn't recognize async components | Upgrade to TS 5.1.2+ and `@types/react` 18.2.8+, or omit return type |
| `"Text content does not match server-rendered HTML"` | Hydration mismatch | Ensure identical rendering on server and client; use `suppressHydrationWarning` for intentional differences |
| `"Route used params.id. params should be awaited before using its properties"` | Next.js 15 changed params to async | Await params: `const { id } = await params;` |

## Environment Variable Access

### Server Components

Server Components have access to **all** environment variables:

```jsx
// Server Component -- full access
async function DBComponent() {
  const data = await fetch(process.env.DATABASE_URL);  // Works
  const secret = process.env.API_SECRET;               // Works
}
```

### Client Components

Client Components only have access to specifically prefixed variables:

- **Next.js:** `NEXT_PUBLIC_` prefix
- **Vite:** `VITE_` prefix

```jsx
'use client';
function ClientComp() {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL;  // Works
  const secret = process.env.API_SECRET;           // undefined
}
```

**Security:** Use `server-only` to protect modules that access secrets. Without it, secrets could accidentally leak to the client through import chains.

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
