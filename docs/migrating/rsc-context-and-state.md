# RSC Migration: Context, Providers, and State Management

React Context is one of the biggest migration challenges when adopting RSC. Server Components cannot create or consume Context -- they have no access to `createContext`, `useContext`, or any Context provider. This guide covers the patterns for handling Context, providers, and global state in an RSC world.

> **Part 2 of the [RSC Migration Series](migrating-to-rsc.md)**

## Why Context Doesn't Work in Server Components

Context relies on React's re-rendering mechanism. When a Context value changes, all consumers re-render. Server Components render once on the server and produce static output -- they never re-render. This makes Context fundamentally incompatible with Server Components.

**What happens if you try:**

```jsx
// This will throw an error
import { useContext } from 'react';
import { ThemeContext } from './theme';

export default function ServerComponent() {
  const theme = useContext(ThemeContext); // ERROR: Cannot use useContext in Server Component
  return <div className={theme}>...</div>;
}
```

## Pattern 1: Client Component Provider Wrapper

The most important pattern for Context migration. Create a `'use client'` wrapper component that provides context, and use `children` to pass Server Component content through it.

### Theme Provider Example

```jsx
// theme-provider.jsx
'use client';

import { createContext, useState, useContext } from 'react';

const ThemeContext = createContext('light');

export function useTheme() {
  return useContext(ThemeContext);
}

export default function ThemeProvider({ children }) {
  const [theme, setTheme] = useState('light');

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}
```

```jsx
// layout.jsx -- Server Component
import ThemeProvider from './theme-provider';

export default function Layout({ children }) {
  return (
    <html>
      <body>
        <ThemeProvider>
          {children}  {/* Server Components pass through unchanged */}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

**Why this works:** The Server Component (`Layout`) renders `ThemeProvider` as a Client Component, passing `{children}` (which are Server Components) through it. The children are rendered on the server and passed as pre-rendered content -- they don't become Client Components.

**Best practice:** Render providers as deep as possible in the tree. Wrap only `{children}`, not the entire `<html>` document. This lets the framework optimize static parts outside the provider.

## Pattern 2: Composing Multiple Providers

Real applications need many providers (theme, auth, i18n, query client). Create a single composed provider to avoid "provider hell":

```jsx
// providers.jsx
'use client';

import { ThemeProvider } from 'next-themes';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';
import AuthProvider from './auth-provider';

export default function Providers({ children, user }) {
  const [queryClient] = useState(() => new QueryClient());

  return (
    <AuthProvider user={user}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider attribute="class">
          {children}
        </ThemeProvider>
      </QueryClientProvider>
    </AuthProvider>
  );
}
```

```jsx
// layout.jsx -- Server Component
import Providers from './providers';
import { getUser } from './lib/auth';
import Header from './components/Header';
import Footer from './components/Footer';

export default async function Layout({ children }) {
  const user = await getUser();

  return (
    <html>
      <body>
        <Header />        {/* Server Component -- outside providers */}
        <Providers user={user}>
          {children}
        </Providers>
        <Footer />        {/* Server Component -- outside providers */}
      </body>
    </html>
  );
}
```

**Key insight:** Components that don't need context (static header, footer) stay **outside** the provider wrapper, keeping them as Server Components with zero JavaScript cost.

## Pattern 3: `React.cache()` for Server-Side Data Sharing

Server Components can't use Context, but they can share data using `React.cache()`. This memoizes a function's result within a single request -- multiple Server Components calling the same cached function get the same result without duplicate work.

```jsx
// lib/user.js
import { cache } from 'react';

export const getUser = cache(async () => {
  const res = await fetch('https://api.example.com/user');
  return res.json();
});
```

```jsx
// components/Navbar.jsx -- Server Component
import { getUser } from '../lib/user';

export default async function Navbar() {
  const user = await getUser(); // Cached per request
  return <nav>Welcome, {user.name}</nav>;
}
```

```jsx
// app/dashboard/page.jsx -- Server Component
import { getUser } from '../lib/user';

export default async function DashboardPage() {
  const user = await getUser(); // Same cached result, no duplicate fetch
  return <h1>Dashboard for {user.name}</h1>;
}
```

**Properties of `React.cache()`:**

- Scoped to the **current request only** -- no cross-request data leakage
- Works like "server Context" -- multiple components get the same data
- Only works in Server Components
- Replaces the pattern of prop-drilling shared data through many components

## Pattern 4: Sharing Data Between Server and Client Components

When data must be available to both Server and Client Components, combine `React.cache()` with a Context provider that passes a **Promise**:

```jsx
// lib/user.js
import { cache } from 'react';

export const getUser = cache(async () => {
  const res = await fetch('https://api.example.com/user');
  return res.json();
});
```

```jsx
// user-provider.jsx
'use client';

import { createContext } from 'react';

export const UserContext = createContext(null);

export default function UserProvider({ children, userPromise }) {
  return <UserContext value={userPromise}>{children}</UserContext>;
}
```

```jsx
// layout.jsx -- Server Component
import UserProvider from './user-provider';
import { getUser } from './lib/user';

export default function Layout({ children }) {
  const userPromise = getUser(); // Do NOT await

  return (
    <html>
      <body>
        <UserProvider userPromise={userPromise}>
          {children}
        </UserProvider>
      </body>
    </html>
  );
}
```

```jsx
// components/Profile.jsx -- Client Component
'use client';

import { use, useContext } from 'react';
import { UserContext } from '../user-provider';

export function Profile() {
  const userPromise = useContext(UserContext);
  if (!userPromise) throw new Error('Must be within UserProvider');
  const user = use(userPromise); // Resolves the promise
  return <p>Welcome, {user.name}</p>;
}
```

**How it works:**

1. Server Component starts the fetch (close to data source) but doesn't await
2. Promise is passed to the Client Component provider
3. Client Components resolve the promise with `use()`
4. Server Components can also call `getUser()` directly and `await` it -- `React.cache()` ensures no duplicate fetch

## Migrating Global State Libraries

### Redux Toolkit

Redux must be adapted for RSC. The key rules:

1. **Do NOT create a global singleton store** -- create per-request stores to prevent data leakage across users
2. **Server Components must NOT read or write the Redux store**
3. **Only Client Components interact with Redux**

```jsx
// lib/store.js
import { configureStore } from '@reduxjs/toolkit';

export const makeStore = () => {
  return configureStore({
    reducer: { /* your reducers */ },
  });
};
```

```jsx
// StoreProvider.jsx
'use client';

import { useRef } from 'react';
import { Provider } from 'react-redux';
import { makeStore } from '../lib/store';

export default function StoreProvider({ children }) {
  const storeRef = useRef(null);
  if (!storeRef.current) {
    storeRef.current = makeStore();
  }

  return <Provider store={storeRef.current}>{children}</Provider>;
}
```

**Important:** Use `useRef` for store initialization, NOT `useEffect`. `useEffect` runs only on the client and causes hydration mismatches. `useRef` initializes during the first render.

**To pass server data into Redux:**

```jsx
// StoreProvider.jsx
'use client';

import { useRef } from 'react';
import { Provider } from 'react-redux';
import { makeStore } from '../lib/store';
import { setInitialData } from '../lib/features/dataSlice';

export default function StoreProvider({ initialData, children }) {
  const storeRef = useRef(null);
  if (!storeRef.current) {
    storeRef.current = makeStore();
    storeRef.current.dispatch(setInitialData(initialData));
  }

  return <Provider store={storeRef.current}>{children}</Provider>;
}
```

### Zustand

Zustand follows the same pattern -- per-request store factories with a Client Component provider:

```jsx
// stores/counter-store.js
import { createStore } from 'zustand/vanilla';

export const createCounterStore = (initState = { count: 0 }) => {
  return createStore((set) => ({
    ...initState,
    increment: () => set((state) => ({ count: state.count + 1 })),
    decrement: () => set((state) => ({ count: state.count - 1 })),
  }));
};
```

```jsx
// providers/counter-store-provider.jsx
'use client';

import { createContext, useRef, useContext } from 'react';
import { useStore } from 'zustand';
import { createCounterStore } from '../stores/counter-store';

const CounterStoreContext = createContext(undefined);

export function CounterStoreProvider({ children }) {
  const storeRef = useRef(null);
  if (!storeRef.current) {
    storeRef.current = createCounterStore();
  }

  return (
    <CounterStoreContext.Provider value={storeRef.current}>
      {children}
    </CounterStoreContext.Provider>
  );
}

export function useCounterStore(selector) {
  const store = useContext(CounterStoreContext);
  if (!store) throw new Error('Missing CounterStoreProvider');
  return useStore(store, selector);
}
```

**Critical warning:** Never use Zustand (or any state library) directly in Server Components -- the store would be shared across ALL users on the server, creating severe security and correctness issues.

### General State Management Guidance

RSC reduces the need for global state libraries because data fetching moves to the server:

| Use Case | Recommended Approach |
|----------|---------------------|
| Server data (read-only display) | Async Server Components with direct fetching |
| Server data (with client cache/revalidation) | TanStack Query with prefetch + hydrate |
| Client UI state (modals, forms, selections) | `useState` / Context in Client Components |
| Complex client state (undo/redo, shared across many components) | Zustand or Redux Toolkit in Client Components |
| Request-scoped data sharing (between Server Components) | `React.cache()` |

## Specific Provider Patterns

### Auth Provider

Read auth state on the server, pass to a Client Component provider:

```jsx
// layout.jsx -- Server Component
import { cookies } from 'next/headers';
import { verifyToken } from './lib/auth';
import AuthProvider from './auth-provider';

export default async function Layout({ children }) {
  const cookieStore = await cookies();
  const token = cookieStore.get('session')?.value;
  const user = token ? await verifyToken(token) : null;

  return (
    <html>
      <body>
        <AuthProvider user={user}>{children}</AuthProvider>
      </body>
    </html>
  );
}
```

**Key constraints:**

- Server Components can read `HttpOnly` cookies that client JavaScript cannot access (security advantage)
- Cookies are read-only in Server Components -- use Server Actions or middleware to set cookies
- Session refresh must happen in middleware, before the Server Component renders

### Theme Provider (No Flash of Wrong Theme)

For server-side theme rendering without flicker, store the preference in a cookie:

```jsx
// layout.jsx -- Server Component
import { cookies } from 'next/headers';

export default async function Layout({ children }) {
  const cookieStore = await cookies();
  const theme = cookieStore.get('theme')?.value || 'light';

  return (
    <html className={theme}>
      <body>{children}</body>
    </html>
  );
}
```

The correct CSS class is applied during SSR -- no flash of the wrong theme on initial load. A Client Component can update the cookie via a Server Action when the user toggles themes.

### i18n Provider

Internationalization requires a split approach. Server Components use server-side translation functions; Client Components use a provider:

```jsx
// layout.jsx -- Server Component
import { NextIntlClientProvider } from 'next-intl';
import { getMessages, getLocale } from 'next-intl/server';

export default async function Layout({ children }) {
  const locale = await getLocale();
  const messages = await getMessages();

  return (
    <html lang={locale}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
```

```jsx
// ServerComponent.jsx -- uses server-side translation
import { getTranslations } from 'next-intl/server';

export default async function ServerComponent() {
  const t = await getTranslations('HomePage');
  return <h1>{t('title')}</h1>;
}
```

```jsx
// ClientComponent.jsx -- uses client-side hook
'use client';

import { useTranslations } from 'next-intl';

export default function ClientComponent() {
  const t = useTranslations('Counter');
  return <button>{t('increment')}</button>;
}
```

## Migration Checklist

### Phase 1: Audit

1. List all Context providers in your app
2. Categorize each by type:
   - **Client-only state** (UI state, modals, form state): Keep as Context in Client Components
   - **Server data** (user profile, config, feature flags): Move to server-side fetching
   - **Hybrid** (auth session, locale): Fetch on server, provide via Client Component

### Phase 2: Extract Providers

3. Create a `providers.jsx` file marked with `'use client'`
4. Move all context providers into this file
5. Import the composed provider into your root layout
6. Pass server-fetched data as props to the provider

### Phase 3: Replace Server-Side Context Usage

7. Replace `useContext` in data-fetching components with direct data fetching
8. Use `React.cache()` to share data between Server Components
9. Pass promises to context for hybrid server/client data

### Phase 4: State Management Libraries

10. Create per-request store factories (not global singletons)
11. Remove store reads/writes from Server Components
12. Initialize stores from server-fetched props using `useRef`
13. Consider reducing state library usage -- RSC often eliminates the need for client-side data caching

## Next Steps

- [Data Fetching Migration](rsc-data-fetching.md) -- migrating from useEffect to server-side fetching
- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
