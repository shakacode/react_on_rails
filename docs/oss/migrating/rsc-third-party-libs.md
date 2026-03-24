# RSC Migration: Third-Party Library Compatibility

Most third-party React libraries were built before Server Components existed. Many rely on hooks, Context, or browser APIs that are unavailable in Server Components. This guide covers how to identify incompatible libraries, create wrapper patterns, and choose RSC-compatible alternatives.

> **Part 5 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous: [Data Fetching Migration](rsc-data-fetching.md) | Next: [Troubleshooting](rsc-troubleshooting.md)

## Why Libraries Break in Server Components

Server Components cannot use:

- `useState`, `useEffect`, `useRef`, `useReducer`, and most React hooks
- `createContext` / `useContext`
- Browser APIs (`window`, `localStorage`, `document`)
- Event handlers (`onClick`, `onChange`)

> **Note on `React.memo` and `forwardRef`:** These wrappers don't cause errors in Server Components -- the React Flight renderer silently unwraps them. However, their functionality has no effect: `memo` can't memoize (Server Components don't re-render), and `forwardRef` can't forward refs (the `ref` prop is explicitly rejected by the Flight serializer). Libraries that use these wrappers can still render as Server Components, unlike libraries that call hooks. `forwardRef` is deprecated in React 19 in favor of `ref` as a regular prop.
>
> **Note on `ref` in Server Components:** `React.createRef()` is available in the server runtime (it's a plain function, not a hook), but the resulting ref cannot be attached to any element. The Flight serializer explicitly rejects the `ref` prop on any element -- including Client Components -- with: _"Refs cannot be used in Server Components, nor passed to Client Components."_ Refs are inherently a client-side concept -- if a Client Component needs a ref, it should create one itself with `useRef()`.

Any library that relies on these features must be used within a `'use client'` boundary. The React Working Group maintains a [canonical tracking list](https://github.com/reactwg/server-components/discussions/6) of library RSC support status.

## The Thin Wrapper Pattern

The most common solution for incompatible libraries: create a minimal `'use client'` file that re-exports the component. This works because [`'use client'` marks a boundary](rsc-component-patterns.md#use-client-marks-a-boundary-not-a-component-type) -- the wrapper establishes the server-to-client transition point, and the library code below it automatically becomes client code.

### Direct Re-export (Simplest)

```jsx
// ui/carousel.jsx
'use client';

import { Carousel } from 'acme-carousel';

export default Carousel;
```

Then use it in a Server Component:

```jsx
// Page.jsx -- Server Component
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
// ui/chart-components.jsx
'use client';

export { AreaChart, BarChart, LineChart, Tooltip, Legend } from 'recharts';
```

### Wrapper with Default Props

```jsx
// ui/date-picker.jsx
'use client';

import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';

export default function AppDatePicker(props) {
  return <DatePicker dateFormat="yyyy-MM-dd" {...props} />;
}
```

### Provider Wrapper

```jsx
// providers/query-provider.jsx
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

| Library               | RSC Status                                                                                                                                                                                                                         | Notes                                                                                                                                              |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **styled-components** | In maintenance mode. The v6.3.x series added incremental RSC compatibility fixes (e.g., suppressing server-side warnings in v6.3.3, fixing `createGlobalStyle` unmount behavior with React 19's `precedence` attribute in v6.3.9). | The maintainer stated: "For new projects, I would not recommend adopting styled-components." React Context dependency is the root incompatibility. |
| **Emotion**           | No native RSC support                                                                                                                                                                                                              | Workaround: wrap all Emotion-styled components in `'use client'` files.                                                                            |

### Zero-Runtime CSS-in-JS (RSC Compatible)

| Library             | Notes                                                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tailwind CSS**    | No runtime JS. The standard choice for RSC projects.                                                                                    |
| **CSS Modules**     | Built into most frameworks. No runtime overhead.                                                                                        |
| **Panda CSS**       | Zero-runtime, type-safe, created by Chakra UI team. RSC-compatible by design.                                                           |
| **Pigment CSS**     | Created by MUI. Compiles to CSS Modules. Check the [Pigment CSS repo](https://github.com/mui/pigment-css) for current stability status. |
| **vanilla-extract** | TypeScript-native. Known issue: `.css.ts` imports in RSC may need `swc-plugin-vanilla-extract` workaround.                              |
| **StyleX**          | Facebook's compile-time solution.                                                                                                       |
| **Linaria**         | Zero-runtime with familiar styled API.                                                                                                  |

**Migration advice:** If you're currently using styled-components or Emotion and your app's performance is acceptable, there's no urgency to migrate. But for new RSC projects, choose a zero-runtime solution.

## UI Component Libraries

### shadcn/ui

**Best RSC compatibility.** Copy-paste model means you own the source code and control exactly which components have `'use client'`. Built on Radix + Tailwind.

### Radix UI

Best-in-class RSC compatibility among full-featured headless libraries. Non-interactive primitives can be Server Components. Interactive primitives (`Dialog`, `Popover`, etc.) still need `'use client'`.

### Material UI (MUI)

All MUI components require `'use client'` due to Emotion dependency. None can be used as pure Server Components. **v5.14.0+** added `'use client'` directives, so components work alongside Server Components without manual wrappers. Use direct imports (e.g., `import Button from '@mui/material/Button'`) instead of barrel imports to avoid bundling the entire library.

### Chakra UI

Requires `'use client'` for all components due to Emotion runtime. The Chakra team created **Panda CSS** and **Ark UI** as RSC-compatible alternatives.

### Mantine

All components include `'use client'` directives. Cannot use compound components (`<Tabs.Tab />`) in Server Components -- use non-compound equivalents (`<TabsTab />`).

## Form Libraries

| Library             | RSC Pattern                                                                                                                                         | Notes                               |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| **React Hook Form** | Client-only (uses Context). Create a `'use client'` form component, import into Server Component. Submit to Rails controller endpoints via `fetch`. | Most popular option.                |
| **TanStack Form**   | Emerging alternative with RSC-aware architecture. Submit to Rails controller endpoints.                                                             | Framework-agnostic.                 |
| **Standard forms**  | Use Rails' standard form helpers (`form_with`, `form_tag`) for non-React forms. For React forms, submit via `fetch` to Rails API endpoints.         | No library needed for simple forms. |

### Form Submission Pattern

> **Important:** React on Rails does **not** support Server Actions (`'use server'`). Server Actions run on the Node renderer, which has no access to Rails models, sessions, cookies, or CSRF protection. Use Rails controllers for all form submissions.

```jsx
// UserForm.jsx -- Client Component
'use client';

import { useState } from 'react';
import ReactOnRails from 'react-on-rails';

export default function UserForm() {
  const [name, setName] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    const response = await fetch('/api/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': ReactOnRails.authenticityToken(),
      },
      body: JSON.stringify({ user: { name } }),
    });
    if (!response.ok) throw new Error(`Request failed: ${response.status}`);
    setName('');
  }

  return (
    <form onSubmit={handleSubmit}>
      <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
      <button type="submit">Submit</button>
    </form>
  );
}
```

```erb
<%# ERB view %>
<%= stream_react_component("UserForm") %>
```

**Pattern 2: Standard Rails form (no JavaScript required)**

```erb
<%= form_with(model: @user, url: users_path, local: true) do |f| %>
  <%= f.text_field :name %>
  <%= f.submit "Submit" %>
<% end %>
```

> **Note:** `local: true` is required for Rails 5.1–6.0, where `form_with` defaults to `remote: true` (Ajax). Rails 6.1+ defaults to `local: true`, so it can be omitted on newer versions.

Both patterns leverage Rails' full controller/model layer -- authentication, authorization, CSRF protection, and validations all work as expected.

## Animation Libraries

| Library                    | RSC Status                           | Notes                                                   |
| -------------------------- | ------------------------------------ | ------------------------------------------------------- |
| **Framer Motion / Motion** | Client-only. Relies on browser APIs. | Wrap animated elements in `'use client'` files.         |
| **React Spring**           | Client-only. Uses hooks.             | Same wrapper pattern.                                   |
| **CSS animations**         | Fully compatible                     | `@keyframes`, `transition`, Tailwind animate utilities. |
| **View Transitions API**   | Browser-native, compatible           | No React dependency.                                    |

### Animation Wrapper Pattern

```jsx
// ui/animated-div.jsx
'use client';

import { motion } from 'motion/react';

export default function AnimatedDiv({ children, ...props }) {
  return <motion.div {...props}>{children}</motion.div>;
}
```

## Charting Libraries

| Library                        | RSC Compatibility    | Notes                                                                   |
| ------------------------------ | -------------------- | ----------------------------------------------------------------------- |
| **Nivo**                       | Best RSC support     | Pre-renders SVG charts on the server.                                   |
| **Recharts**                   | Client-only          | SVG + React hooks. Needs `'use client'` wrapper.                        |
| **Chart.js / react-chartjs-2** | Client-only          | Canvas-based, requires DOM.                                             |
| **D3.js**                      | Partially compatible | Data transformation works server-side. DOM manipulation is client-only. |
| **Tremor**                     | Client-only          | Built on Recharts + Tailwind.                                           |

## Date Libraries

All major date libraries work in Server Components since they are pure utility functions with no React or browser dependencies:

- **date-fns** -- tree-shakable, recommended
- **dayjs** -- lightweight alternative
- **Moment.js** -- works but deprecated and not tree-shakable

**Performance benefit:** These dependencies stay entirely server-side when used in Server Components, removing them from the client bundle.

## Data Fetching Libraries

| Library                          | RSC Pattern                                                                                        | Notes                                                                                                |
| -------------------------------- | -------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **React on Rails Pro streaming** | Recommended for React on Rails. Rails streams components via `stream_react_component`.             | See [Data Fetching Migration](rsc-data-fetching.md#data-fetching-in-react-on-rails-pro) for details. |
| **TanStack Query**               | Prefetch on server with `queryClient.prefetchQuery()`, hydrate on client with `HydrationBoundary`. | See [Data Fetching Migration](rsc-data-fetching.md) for details.                                     |
| **Apollo Client**                | Server-side queries in Server Components, `ApolloProvider` for client queries.                     | Requires `'use client'` wrapper for provider.                                                        |
| **SWR**                          | Client-only hooks. Use `fallbackData` pattern: fetch in Server Component, pass as props.           | See [Data Fetching Migration](rsc-data-fetching.md) for details.                                     |

## Internationalization

| Library                     | RSC Pattern                                                                                                                                                     | Notes                                                                                        |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Rails I18n + react-intl** | Pass translations from Rails controller as props. Server Components use the translations object directly; Client Components use `<IntlProvider>` + `useIntl()`. | Recommended for React on Rails. See [Context guide](rsc-context-and-state.md#i18n-provider). |
| **i18next / react-i18next** | Requires `'use client'` for hook-based usage. Server Components can use `i18next` directly (no hooks).                                                          | Framework-agnostic alternative.                                                              |

## Authentication

In React on Rails, authentication is handled by Rails (Devise, OmniAuth, etc.) before the React component renders. The controller passes the authenticated user as props:

```ruby
# Rails controller handles auth, passes user to component
stream_react_component("Dashboard", props: { user: current_user.as_json(only: [:id, :name, :email]) })
```

This is a simpler model than client-side auth libraries -- Rails middleware handles sessions, CSRF protection, and authorization before any React code executes. See the [auth provider pattern](rsc-context-and-state.md#auth-provider) for passing auth data to nested Client Components via Context.

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
3. **Mixed server/client exports:** A barrel file that re-exports both server and client components can cause unexpected bundle inclusion

### The Solution: Direct Imports

The most reliable fix is to bypass barrel files entirely. Use direct imports instead:

```jsx
// BAD: Import from barrel -- pulls in everything
import { Button } from './components';
import { AlertIcon } from 'lucide-react';

// GOOD: Import directly -- only bundles what you use
import Button from './components/Button';
import AlertIcon from 'lucide-react/dist/esm/icons/alert';
```

For third-party packages, check if the library provides direct import paths (most popular libraries do). For example:

- `@mui/material/Button` instead of `{ Button } from '@mui/material'`
- `lodash-es/debounce` instead of `{ debounce } from 'lodash-es'`

### For Your Own Code

Avoid creating barrel files that mix server and client components. If you must use a barrel file, keep separate barrels for server and client exports:

```text
components/
├── server/index.js    # Only server components
├── client/index.js    # Only 'use client' components
├── ServerHeader.jsx
├── ClientSearch.jsx
└── ...
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

| Category          | RSC-Native Choices                                                | Requires `'use client'` Wrapper              | Avoid / Migrate Away From                          |
| ----------------- | ----------------------------------------------------------------- | -------------------------------------------- | -------------------------------------------------- |
| **Styling**       | Tailwind, CSS Modules, Panda CSS                                  | vanilla-extract (with workaround)            | styled-components (maintenance mode), Emotion      |
| **UI Components** | shadcn/ui, Radix (non-interactive)                                | MUI, Chakra, Mantine, Radix (interactive)    | CSS-in-JS-dependent UI libs without migration path |
| **Forms**         | Rails controller endpoints + standard forms                       | React Hook Form, TanStack Form               | Formik (less maintained)                           |
| **Animation**     | CSS animations, Tailwind animate                                  | Framer Motion/Motion, React Spring           | --                                                 |
| **Charts**        | Nivo (SSR support)                                                | Recharts, Tremor, Chart.js                   | --                                                 |
| **Data Fetching** | React on Rails Pro streaming, native `fetch` in Server Components | TanStack Query (with hydration), Apollo, SWR | --                                                 |
| **State**         | Server Component props, `React.cache`                             | Zustand, Jotai (v2.6+), Redux Toolkit        | Recoil (discontinued)                              |
| **i18n**          | Rails I18n + react-intl                                           | react-i18next, i18next                       | --                                                 |
| **Auth**          | Rails auth (Devise, etc.) via controller props                    | --                                           | --                                                 |
| **Date Utils**    | date-fns, dayjs (pure functions)                                  | --                                           | Moment.js (not tree-shakable)                      |

## Common Mistakes

### Mistake 1: Adding `'use client'` to a barrel file

Marking a barrel file (e.g., `components/index.js`) with `'use client'` forces every export into the client bundle, even components that could be Server Components:

```jsx
// BAD: All 50 exported components become Client Components
'use client';
export { Header } from './Header';
export { Footer } from './Footer';
export { ProductCard } from './ProductCard';
// ... 47 more
```

**Fix:** Add `'use client'` only to individual component files that actually need it. Better yet, avoid barrel files entirely and use direct imports.

### Mistake 2: Not checking library RSC compatibility before migrating

Starting a component migration only to discover that a deeply nested dependency uses hooks wastes significant time.

**Fix:** Before removing `'use client'` from a component, audit its import tree. Run a build with the change and look for errors like _"You're importing a component that needs useState."_ The [React Working Group compatibility list](https://github.com/reactwg/server-components/discussions/6) tracks library status.

### Mistake 3: Using barrel imports across `'use client'` boundaries

In standard (non-RSC) builds, modern bundlers tree-shake barrel imports effectively -- `import { Button } from '@mui/material'` produces roughly the same output as the direct path import. However, **at `'use client'` boundaries**, the full transitive import graph is included in the client bundle because webpack must serialize the entire module for the RSC manifest. This makes import granularity matter specifically in RSC:

```jsx
// AVOID at 'use client' boundaries: pulls in the full import graph
import { Button } from '@mui/material';

// PREFER: direct import keeps the client boundary small
import Button from '@mui/material/Button';
```

```jsx
// AVOID at 'use client' boundaries
import { debounce } from 'lodash';

// PREFER: imports only what's needed
import debounce from 'lodash-es/debounce';
```

> **Note:** Outside of `'use client'` files, barrel imports are generally fine with modern bundlers. This advice is specific to files that form RSC client boundaries.

### Mistake 4: Continuing to use runtime CSS-in-JS without a plan

Styled-components and Emotion work inside `'use client'` boundaries, but they prevent those components from ever becoming Server Components. If your migration goal includes reducing JavaScript bundle size, CSS-in-JS will be the bottleneck.

**Fix:** For new components, use Tailwind CSS, CSS Modules, or another zero-runtime solution. For existing styled-components/Emotion code, create a migration plan or accept that those components will remain Client Components.

## Next Steps

- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
- [Data Fetching Migration](rsc-data-fetching.md) -- migrating from useEffect to server-side fetching
