# RSC Migration: Third-Party Library Compatibility

Most third-party React libraries were built before Server Components existed. Many rely on hooks, Context, or browser APIs that are unavailable in Server Components. This guide covers how to identify incompatible libraries, create wrapper patterns, and choose RSC-compatible alternatives.

> **Part 4 of the [RSC Migration Series](migrating-to-rsc.md)**

## Why Libraries Break in Server Components

Server Components cannot use:

- `useState`, `useEffect`, `useRef`, `useReducer`, and most React hooks
- `createContext` / `useContext`
- `forwardRef`, `memo`
- Browser APIs (`window`, `localStorage`, `document`)
- Event handlers (`onClick`, `onChange`)

Any library that relies on these features must be used within a `'use client'` boundary. The React Working Group maintains a [canonical tracking list](https://github.com/reactwg/server-components/discussions/6) of library RSC support status.

## The Thin Wrapper Pattern

The most common solution for incompatible libraries: create a minimal `'use client'` file that re-exports the component.

### Direct Re-export (Simplest)

```jsx
// app/ui/carousel.jsx
'use client';

import { Carousel } from 'acme-carousel';

export default Carousel;
```

Then use it in a Server Component:

```jsx
// app/page.jsx -- Server Component
import Carousel from './ui/carousel';

export default function Page() {
  return (
    <div>
      <p>View pictures</p>
      <Carousel />
    </div>
  );
}
```

### Named Re-exports (Multiple Components)

```jsx
// app/ui/chart-components.jsx
'use client';

export { AreaChart, BarChart, LineChart, Tooltip, Legend } from 'recharts';
```

### Wrapper with Default Props

```jsx
// app/ui/date-picker.jsx
'use client';

import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';

export default function AppDatePicker(props) {
  return <DatePicker dateFormat="yyyy-MM-dd" {...props} />;
}
```

### Provider Wrapper

```jsx
// app/providers/query-provider.jsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';

export default function QueryProvider({ children }) {
  const [queryClient] = useState(() => new QueryClient());
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
```

## CSS-in-JS Libraries

CSS-in-JS is the most impactful compatibility challenge for RSC migration. Runtime CSS-in-JS libraries depend on React Context and re-rendering, which Server Components fundamentally lack.

### Runtime CSS-in-JS (Problematic)

| Library | RSC Status | Notes |
|---------|-----------|-------|
| **styled-components** | Maintenance mode (March 2025). v6.3.0+ added RSC support via React's `<style>` tag hoisting. | The maintainer stated: "For new projects, I would not recommend adopting styled-components." React Context dependency is the root incompatibility. |
| **Emotion** | No native RSC support | Workaround: wrap all Emotion-styled components in `'use client'` files. |

### Zero-Runtime CSS-in-JS (RSC Compatible)

| Library | Notes |
|---------|-------|
| **Tailwind CSS** | No runtime JS. The standard choice for RSC projects. |
| **CSS Modules** | Built into most frameworks. No runtime overhead. |
| **Panda CSS** | Zero-runtime, type-safe, created by Chakra UI team. RSC-compatible by design. |
| **Pigment CSS** | Created by MUI. Compiles to CSS Modules. Still unstable as of early 2026. |
| **vanilla-extract** | TypeScript-native. Known issue: `.css.ts` imports in RSC may need `swc-plugin-vanilla-extract` workaround. |
| **StyleX** | Facebook's compile-time solution. |
| **Linaria** | Zero-runtime with familiar styled API. |

**Migration advice:** If you're currently using styled-components or Emotion and your app's performance is acceptable, there's no urgency to migrate. But for new RSC projects, choose a zero-runtime solution.

## UI Component Libraries

### shadcn/ui

**Best RSC compatibility.** Copy-paste model means you own the source code and control exactly which components have `'use client'`. Built on Radix + Tailwind.

### Radix UI

Best-in-class RSC compatibility among full-featured headless libraries. Non-interactive primitives can be Server Components. Interactive primitives (`Dialog`, `Popover`, etc.) still need `'use client'`.

### Material UI (MUI)

All MUI components require `'use client'` due to Emotion dependency. None can be used as pure Server Components. **v5.14.0+** added `'use client'` directives, so components work alongside Server Components without manual wrappers. Add `@mui/material` to `optimizePackageImports` to avoid barrel file overhead.

### Chakra UI

Requires `'use client'` for all components due to Emotion runtime. The Chakra team created **Panda CSS** and **Ark UI** as RSC-compatible alternatives.

### Mantine

All components include `'use client'` directives. Cannot use compound components (`<Tabs.Tab />`) in Server Components -- use non-compound equivalents (`<TabsTab />`).

## Form Libraries

| Library | RSC Pattern | Notes |
|---------|-------------|-------|
| **React Hook Form** | Client-only (uses Context). Create a `'use client'` form component, import into Server Component. Can combine with Server Actions for submission. | Most popular option. |
| **TanStack Form** | Emerging alternative with RSC-aware architecture. | Framework-agnostic. |
| **React 19 built-in** | `useActionState` + `useFormStatus` hooks work natively with Server Actions. | Reduces need for third-party form libraries. |

### Server Action Form Pattern

```jsx
// actions.js
'use server';

export async function submitForm(formData) {
  const name = formData.get('name');
  await db.users.create({ data: { name } });
  revalidatePath('/users');
}
```

```jsx
// Page.jsx -- Server Component (works without JavaScript)
import { submitForm } from './actions';

export default function Page() {
  return (
    <form action={submitForm}>
      <input type="text" name="name" />
      <button type="submit">Submit</button>
    </form>
  );
}
```

## Animation Libraries

| Library | RSC Status | Notes |
|---------|-----------|-------|
| **Framer Motion / Motion** | Client-only. Relies on browser APIs. | Wrap animated elements in `'use client'` files. |
| **React Spring** | Client-only. Uses hooks. | Same wrapper pattern. |
| **CSS animations** | Fully compatible | `@keyframes`, `transition`, Tailwind animate utilities. |
| **View Transitions API** | Browser-native, compatible | No React dependency. |

### Animation Wrapper Pattern

```jsx
// app/ui/animated-div.jsx
'use client';

import { motion } from 'motion/react';

export default function AnimatedDiv({ children, ...props }) {
  return <motion.div {...props}>{children}</motion.div>;
}
```

## Charting Libraries

| Library | RSC Compatibility | Notes |
|---------|------------------|-------|
| **Nivo** | Best RSC support | Pre-renders SVG charts on the server. |
| **Recharts** | Client-only | SVG + React hooks. Needs `'use client'` wrapper. |
| **Chart.js / react-chartjs-2** | Client-only | Canvas-based, requires DOM. |
| **D3.js** | Partially compatible | Data transformation works server-side. DOM manipulation is client-only. |
| **Tremor** | Client-only | Built on Recharts + Tailwind. |

## Date Libraries

All major date libraries work in Server Components since they are pure utility functions with no React or browser dependencies:

- **date-fns** -- tree-shakable, recommended
- **dayjs** -- lightweight alternative
- **Moment.js** -- works but deprecated and not tree-shakable

**Performance benefit:** These dependencies stay entirely server-side when used in Server Components, removing them from the client bundle.

## Data Fetching Libraries

| Library | RSC Pattern | Notes |
|---------|-------------|-------|
| **TanStack Query** | Prefetch on server with `queryClient.prefetchQuery()`, hydrate on client with `HydrationBoundary`. | See [Data Fetching Migration](rsc-data-fetching.md) for details. |
| **Apollo Client** | Use `@apollo/client-integration-nextjs`. Separate RSC and SSR clients. | `registerApolloClient` for RSC queries, `ApolloNextAppProvider` for client queries. |
| **SWR** | Client-only hooks. Use `fallbackData` pattern: fetch in Server Component, pass as props. | See [Data Fetching Migration](rsc-data-fetching.md) for details. |

## Internationalization

| Library | RSC Pattern | Notes |
|---------|-------------|-------|
| **next-intl** (v3+) | Full RSC support. `useTranslations`, `useFormatter`, `useLocale` work in Server Components. Async APIs available for async Server Components. | Recommended for Next.js. |
| **react-i18next** | Requires `'use client'` for hook-based usage. | Partial support. |

## Authentication

| Library | RSC Pattern | Notes |
|---------|-------------|-------|
| **Clerk** | Full RSC support. `auth()` helper works directly in Server Components. | Purpose-built for App Router. |
| **NextAuth.js / Auth.js** | `SessionProvider` requires Context (client-only). Use `getServerSession()` in Server Components. | Partial support. |

## The Barrel File Problem

Barrel files (`index.js` files that re-export from many modules) cause serious issues with RSC.

### The Problem

```jsx
// components/index.js -- barrel file
export { Button } from './Button';
export { Modal } from './Modal';
export { Chart } from './Chart';
// ... hundreds more
```

When you `import { Button } from './components'`, the bundler must parse the entire barrel file and all transitive imports. With RSC:

1. **Client boundary infection:** Adding `'use client'` to a barrel file forces ALL exports into the client bundle
2. **Tree-shaking failure:** Bundlers struggle to eliminate unused exports
3. **Mixed server/client exports:** Known bugs in Next.js when a barrel file exports both server and client components

### The Solution: `optimizePackageImports`

For third-party packages, Next.js can automatically transform barrel imports into direct imports:

```js
// next.config.js
module.exports = {
  experimental: {
    optimizePackageImports: ['lucide-react', '@mui/material', 'my-lib'],
  },
};
```

This transforms `import { AlertIcon } from 'lucide-react'` into `import AlertIcon from 'lucide-react/dist/icons/alert'` under the hood.

### For Your Own Code

Avoid barrel files entirely. Use direct imports:

```jsx
// BAD: Import from barrel
import { Button } from './components';

// GOOD: Import directly
import Button from './components/Button';
```

## The `server-only` and `client-only` Packages

These packages act as build-time guards to prevent code from running in the wrong environment:

```jsx
// lib/database.js
import 'server-only'; // Build error if imported in a Client Component

export async function getUser(id) {
  return await db.users.findUnique({ where: { id } });
}
```

```jsx
// lib/analytics.js
import 'client-only'; // Build error if imported in a Server Component

export function trackEvent(event) {
  window.analytics.track(event);
}
```

Use `server-only` for:
- Database access modules
- Modules that use API keys or secrets
- Server-side utility functions

Use `client-only` for:
- Browser analytics
- Modules that access `window`, `document`, `localStorage`
- Client-specific utilities

## Library Compatibility Decision Matrix

| Category | RSC-Native Choices | Requires `'use client'` Wrapper | Avoid / Migrate Away From |
|----------|-------------------|-------------------------------|--------------------------|
| **Styling** | Tailwind, CSS Modules, Panda CSS | vanilla-extract (with workaround) | styled-components (maintenance mode), Emotion |
| **UI Components** | shadcn/ui, Radix (non-interactive) | MUI, Chakra, Mantine, Radix (interactive) | CSS-in-JS-dependent UI libs without migration path |
| **Forms** | React 19 `useActionState` + Server Actions | React Hook Form, TanStack Form | Formik (less maintained) |
| **Animation** | CSS animations, Tailwind animate | Framer Motion/Motion, React Spring | -- |
| **Charts** | Nivo (SSR support) | Recharts, Tremor, Chart.js | -- |
| **Data Fetching** | Native `fetch` in Server Components | TanStack Query (with hydration), Apollo, SWR | -- |
| **State** | Server Component props, `React.cache` | Zustand, Jotai (v2.6+), Redux Toolkit | Recoil (discontinued) |
| **i18n** | next-intl v3+ | react-i18next | -- |
| **Auth** | Clerk, Auth.js `getServerSession` | NextAuth SessionProvider | -- |
| **Date Utils** | date-fns, dayjs (pure functions) | -- | Moment.js (not tree-shakable) |

## Next Steps

- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
- [Data Fetching Migration](rsc-data-fetching.md) -- migrating from useEffect to server-side fetching
