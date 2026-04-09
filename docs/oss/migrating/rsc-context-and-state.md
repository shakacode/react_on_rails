# RSC Migration: Context, Providers, and State Management

React Context is one of the biggest migration challenges when adopting RSC. Server Components cannot create or consume Context -- they have no access to `createContext`, `useContext`, or any Context provider. This guide covers the patterns for handling Context, providers, and global state in an RSC world.

> **Part 3 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous: [Component Tree Restructuring](rsc-component-patterns.md) | Next: [Data Fetching Migration](rsc-data-fetching.md)

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

const ThemeContext = createContext({ theme: 'light', setTheme: () => {} });

export function useTheme() {
  return useContext(ThemeContext);
}

export default function ThemeProvider({ children }) {
  const [theme, setTheme] = useState('light');

  // React 19: <Context value={...}> replaces <Context.Provider value={...}>
  return <ThemeContext value={{ theme, setTheme }}>{children}</ThemeContext>;
}
```

```jsx
// ProductPage.jsx -- Server Component (registered with registerServerComponent)
import ThemeProvider from './theme-provider';
import ProductDetails from './ProductDetails';

export default function ProductPage(props) {
  return (
    <ThemeProvider>
      <ProductDetails product={props.product} /> {/* Server Component passes through unchanged */}
    </ThemeProvider>
  );
}
```

**Why this works:** The Server Component (`ProductPage`) renders `ThemeProvider` as a Client Component, passing Server Component children through it. The children are rendered on the server and passed as pre-rendered content -- they don't become Client Components.

**Best practice:** Render providers as deep as possible in the tree. Keep components that don't need context outside the provider wrapper.

## Pattern 2: Composing Multiple Providers

Real applications need many providers (theme, auth, i18n, query client). Create a single composed provider to avoid "provider hell":

```jsx
// providers.jsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';
import AuthProvider from './auth-provider';
import ThemeProvider from './theme-provider';

export default function Providers({ children, user }) {
  const [queryClient] = useState(() => new QueryClient());

  return (
    <AuthProvider user={user}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>{children}</ThemeProvider>
      </QueryClientProvider>
    </AuthProvider>
  );
}
```

```erb
<%# ERB view — Rails passes the data as props %>
<%= stream_react_component("ProductPage",
      props: { user: current_user.as_json(only: [:id, :name]),
               product: @product.as_json(
                          include: { specs: { only: [:id, :label, :value] },
                                     reviews: { only: [:id, :text, :rating] } }) }) %>
```

```jsx
// ProductPage.jsx -- Server Component (registered with registerServerComponent)
import Providers from './providers';
import Header from './components/Header';
import Footer from './components/Footer';
import ProductDetails from './components/ProductDetails';

export default function ProductPage({ user, product }) {
  return (
    <div>
      <Header /> {/* Server Component -- outside providers */}
      <Providers user={user}>
        <ProductDetails product={product} />
      </Providers>
      <Footer /> {/* Server Component -- outside providers */}
    </div>
  );
}
```

**Key insight:** Components that don't need context (static header, footer) stay **outside** the provider wrapper, keeping them as Server Components with zero JavaScript cost.

## Pattern 3: Streaming HTML Delivery

> **Note:** This section covers a cross-cutting concern (data fetching via `stream_react_component`) that affects how you structure context and state. For the full treatment of data fetching patterns, see [Data Fetching Migration](rsc-data-fetching.md).

In React on Rails, data comes from Rails as props. Rails loads all data synchronously in the controller and passes it to `stream_react_component`, which streams the rendered HTML to the browser as React processes the component tree.

```erb
<%= stream_react_component("ProductPage",
      props: { name: product.name, price: product.price,
               reviews: product.reviews
                          .as_json(only: [:id, :text, :rating]),
               recommendations: RecommendationService.for(product)
                          .as_json(only: [:id, :name, :price]) }) %>
```

The component renders with all data available as props. `stream_react_component` streams the HTML to the browser as React processes the component tree:

```jsx
// ProductPage.jsx -- Server Component
export default function ProductPage({ name, price, reviews, recommendations }) {
  return (
    <div>
      <h1>{name}</h1>
      <p>${price}</p>

      <ReviewList reviews={reviews} />
      <RecommendationList items={recommendations} />
    </div>
  );
}

function ReviewList({ reviews }) {
  return (
    <ul>
      {reviews.map((r) => (
        <li key={r.id}>{r.text}</li>
      ))}
    </ul>
  );
}
```

All data is loaded in Rails before rendering begins. `stream_react_component` then streams the rendered HTML to the browser via React's `renderToPipeableStream`.

> **Note:** `React.cache()` is only available in React Server Component environments. It is not available in client components or non-RSC server rendering (e.g., `renderToString`).

> For more streaming patterns and examples, see [Data Fetching in React on Rails Pro](rsc-data-fetching.md#data-fetching-in-react-on-rails-pro).

## Migrating Global State Libraries

### Redux Toolkit

The key rule for RSC: **Server Components must NOT read or write the Redux store.** Only Client Components interact with Redux. This is straightforward in React on Rails because your component's client/server split is explicit.

React on Rails provides two Redux patterns. Both continue to work with RSC as long as Redux access stays in Client Components:

**Pattern 1: Shared store (`registerStore` + `redux_store` helper)**

If you use `ReactOnRails.registerStore()` with the `redux_store` view helper, no changes are needed for Client Components. The framework already creates a fresh store per request (store generators receive `(props, railsContext)` and return a new store instance). Client Components continue using `ReactOnRails.getStore()` and `<Provider>` as before.

```jsx
// ReduxApp.client.jsx -- Client Component (unchanged)
'use client';

import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails/client';
import MyComponent from './MyComponent';

export default () => {
  const store = ReactOnRails.getStore('MyStore');

  return (
    <Provider store={store}>
      <MyComponent />
    </Provider>
  );
};
```

When you migrate a component to a Server Component, use the donut pattern -- a Client Component `<Provider>` at the root with Server Components passed as `children`:

```jsx
// ReduxProvider.jsx -- Client Component (the "donut")
'use client';

import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails/client';

export default function ReduxProvider({ children }) {
  const store = ReactOnRails.getStore('MyStore');

  return <Provider store={store}>{children}</Provider>;
}
```

```jsx
// ProductPage.jsx -- Server Component (migrated, receives product as Rails prop)
import ReduxProvider from './ReduxProvider';
import ProductSpecs from './ProductSpecs';
import AddToCartButton from './AddToCartButton';

export default function ProductPage({ product }) {
  return (
    <ReduxProvider>
      <h1>{product.name}</h1> {/* Server-rendered */}
      <ProductSpecs product={product} /> {/* Server Component */}
      <AddToCartButton product={product} /> {/* Client Component -- uses useDispatch */}
    </ReduxProvider>
  );
}
```

Server Components pass through the `<Provider>` unchanged (they don't consume the store). Client Components deeper in the tree (like `AddToCartButton`) can use `useSelector` and `useDispatch` as usual.

**Pattern 2: Per-component store (render function with `useMemo`)**

If your component creates its own store from props (the pattern used by the React on Rails generator), it already works -- the component is a Client Component with `'use client'`:

```jsx
// HelloWorldApp.client.jsx
'use client';

import { useState } from 'react';
import { Provider } from 'react-redux';
import configureStore from '../store/helloWorldStore';
import HelloWorldContainer from '../containers/HelloWorldContainer';

export default function HelloWorldApp(props) {
  // useState ensures the store is only created once (on mount), even though
  // props is a new object reference on every render.
  const [store] = useState(() => configureStore(props));

  return (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );
}
```

**What RSC changes for Redux:** With Server Components, only the props that Client Components actually need get serialized into the HTML. Previously, all props passed via `react_component` were encoded in the page for hydration -- even data only used for display. Now, Server Components consume display-only data on the server (it never reaches the client), so you should pass only the interactive state your Client Components need into the `<ReduxProvider>`. This reduces the HTML page size and the amount of data the browser must parse.

### Zustand and Jotai

Zustand and Jotai follow the same pattern as Redux: keep all store access in Client Components. Both are lighter-weight alternatives that work well with RSC because they don't require a `<Provider>` wrapper (Zustand) or use a minimal one (Jotai). Wrap store-consuming components with `'use client'` and pass server-fetched data as initial values via props. See the [compatibility matrix](rsc-third-party-libs.md#library-compatibility-decision-matrix) for version requirements.

### General State Management Guidance

RSC reduces the need for global state libraries because data fetching moves to the server:

| Use Case                                                        | Recommended Approach                                                                                |
| --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Server data (read-only display)                                 | Rails controller props → Server Component renders directly                                          |
| Server data (slow, shouldn't block the shell)                   | [Streaming](rsc-data-fetching.md#data-fetching-in-react-on-rails-pro) with `stream_react_component` |
| Server data (with client cache/revalidation)                    | TanStack Query with prefetch + hydrate                                                              |
| Client UI state (modals, forms, selections)                     | `useState` / Context in Client Components                                                           |
| Complex client state (undo/redo, shared across many components) | Redux Toolkit in Client Components                                                                  |

## Specific Provider Patterns

### Auth Provider

In React on Rails, auth data typically comes from the Rails controller as props. The controller has access to the session, cookies, and your authentication system (Devise, etc.) -- pass the current user to the component:

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  include ReactOnRailsPro::Stream

  def show
    stream_view_containing_react_components(template: "dashboard/show")
  end

  helper_method :dashboard_props

  def dashboard_props
    { user: current_user&.as_json(only: [:id, :name, :email, :role]) }
  end
end
```

```erb
<%# app/views/dashboard/show.html.erb %>
<%= stream_react_component("Dashboard", props: dashboard_props, prerender: true) %>
```

```jsx
// Dashboard.jsx -- Server Component (registered with registerServerComponent)
import AuthProvider from './auth-provider';

export default function Dashboard({ user }) {
  return (
    <AuthProvider user={user}>
      <DashboardContent />
    </AuthProvider>
  );
}
```

**Key advantage over client-side auth:** The Rails controller handles authentication and authorization before the component ever renders. `HttpOnly` session cookies never touch JavaScript. The component receives only the serialized user data it needs.

### Theme Provider (No Flash of Wrong Theme)

For server-side theme rendering without flicker, read the theme preference in the Rails controller and pass it as a prop:

```ruby
# app/controllers/application_controller.rb
def theme_preference
  cookies[:theme] || current_user&.theme_preference || 'light'
end
```

```erb
<%# app/views/layouts/application.html.erb %>
<html class="<%= theme_preference %>">
  <body>
    <%= yield %>
  </body>
</html>
```

The correct CSS class is applied during the initial HTML response from Rails -- no flash of the wrong theme on initial load. A Client Component can update the cookie (via a `fetch` call or form submission) when the user toggles themes.

If your React components also need the theme value, pass it as a prop:

```erb
<%= stream_react_component("App", props: { theme: theme_preference, ... }) %>
```

### i18n Provider

Internationalization in React on Rails typically uses Rails I18n on the server side and `react-intl` for Client Components. The challenge with RSC is that `react-intl`'s `useIntl()` hook and `<FormattedMessage>` component require React Context, which is unavailable in Server Components.

> **Two i18n systems:** React on Rails has a [build-time locale system](../building-features/i18n.md) (`config.i18n_dir`) that compiles Rails YAML translations into JSON/JS files with flat dot-separated keys (e.g., `"product.title"`). The controller-props approach below passes translations at request time with whatever key structure you choose. Both are valid — see the comparison below.

#### Passing translations from Rails

```ruby
# app/controllers/application_controller.rb
helper_method :i18n_props

def i18n_props
  {
    locale: I18n.locale.to_s,
    # IMPORTANT: I18n.t('.') returns the ENTIRE translation tree for the locale,
    # which can be thousands of keys. For production, pass only the subset needed:
    messages: I18n.t('product_page').deep_stringify_keys,
  }
end
```

#### Server Components: plain string lookup (limited)

The simplest approach is to read translation values directly from the messages object:

```jsx
// ProductPage.jsx -- Server Component
export default function ProductPage({ locale, messages, ...props }) {
  const title = messages['title'];

  return <h1>{title}</h1>;
}
```

> **Limitation:** This only works for **pre-formatted strings** — plain text with no interpolation, pluralization, or number/date formatting. React on Rails' build-time locale system converts Rails `%{variable}` placeholders to ICU `{variable}` syntax, so `messages['greeting']` would render the literal text `{name}` instead of a substituted value. For anything beyond plain strings, use `createIntl` or Rails pre-formatting (both described below).

#### Server Components: `createIntl` from `react-intl` (recommended)

Import `createIntl` from `react-intl` for a **context-free API** that provides full interpolation, pluralization, and date/number formatting without React Context. This is the recommended approach for i18n in Server Components:

```jsx
// ProductPage.jsx -- Server Component
import { createIntl } from 'react-intl';
import I18nProvider from './I18nProvider';

export default function ProductPage({ locale, messages, ...props }) {
  const intl = createIntl({ locale, messages });

  return (
    <div>
      {/* Full formatting works in Server Components */}
      <h1>{intl.formatMessage({ id: 'greeting' }, { name: props.userName })}</h1>
      <p>{intl.formatNumber(props.price, { style: 'currency', currency: 'USD' })}</p>
      <p>{intl.formatMessage({ id: 'items_count' }, { count: props.itemCount })}</p>

      <I18nProvider locale={locale} messages={messages}>
        <InteractiveFilters /> {/* Client Component can use useIntl() */}
      </I18nProvider>
    </div>
  );
}
```

> **Note:** `createIntl` is a plain function call — no hooks, no Context, no `'use client'` needed. It creates a new `intl` object per call, which is fine for Server Components since they render once per request.

#### Alternative: Rails pre-formatting

Instead of formatting on the client, let Rails compute interpolation and pluralization before passing translations as props. This keeps Server Components simple at the cost of less flexible client-side formatting:

```ruby
def i18n_props
  {
    locale: I18n.locale.to_s,
    # Pre-format with variables — Server Components receive ready-to-render strings
    greeting: I18n.t('greeting', name: current_user.name),
    items_count: I18n.t('items_count', count: @cart.item_count),
    # Pass raw messages for Client Components that need dynamic formatting
    messages: I18n.t('product_page').deep_stringify_keys,
  }
end
```

#### Client Components: `IntlProvider` + `useIntl()`

Client Components use the standard `react-intl` Context pattern:

```jsx
// I18nProvider.jsx
'use client';

import { IntlProvider } from 'react-intl';

export default function I18nProvider({ locale, messages, children }) {
  return (
    <IntlProvider locale={locale} messages={messages}>
      {children}
    </IntlProvider>
  );
}
```

```jsx
// InteractiveFilters.jsx -- Client Component
'use client';

import { useIntl } from 'react-intl';

export default function InteractiveFilters() {
  const intl = useIntl();
  return <button>{intl.formatMessage({ id: 'filters.apply' })}</button>;
}
```

#### Build-time vs controller-props: when to use each

| Approach                       | Source                     | Key format                   | Best for                                                                                |
| ------------------------------ | -------------------------- | ---------------------------- | --------------------------------------------------------------------------------------- |
| Build-time (`config.i18n_dir`) | YAML → compiled JSON/JS    | Flat: `"product.title"`      | Static translations shared across pages; client-side `react-intl` with `defineMessages` |
| Controller-props (`I18n.t`)    | Rails I18n at request time | Your choice (flat or nested) | Page-specific translations; pre-formatted strings with variables; RSC `createIntl`      |

Both can be used together — for example, build-time translations for the client bundle and controller-props for Server Component content. See the [Internationalization guide](../building-features/i18n.md) for build-time setup details.

## Common Mistakes

### Mistake 1: Wrapping the entire tree in providers unnecessarily

Wrapping the entire component tree in a `'use client'` provider works correctly -- children passed from a Server Component remain Server Components (this is the "children as props" pattern). However, wrapping more than necessary has real costs:

- Every child that **consumes** the context (via `useContext`) must be a Client Component
- Provider scope is broader than needed, making refactoring harder
- Context value changes trigger re-renders across a wider subtree

Narrow the provider scope to only the subtree that actually needs the context:

```jsx
// WIDER THAN NEEDED: Header and Footer don't use this context,
// but they're inside the provider scope unnecessarily
export default function ProductPage({ user, product }) {
  return (
    <Providers user={user}>
      <Header />
      <ProductDetails product={product} />
      <Footer />
    </Providers>
  );
}
```

```jsx
// BETTER: Only wrap components that actually need context
export default function ProductPage({ user, product }) {
  return (
    <div>
      <Header /> {/* Server Component -- outside provider scope */}
      <Providers user={user}>
        <ProductDetails product={product} />
      </Providers>
      <Footer /> {/* Server Component -- outside provider scope */}
    </div>
  );
}
```

### Mistake 2: Passing the entire I18n translation tree

`I18n.t('.')` returns every translation key for the locale, which can be thousands of entries. Serializing this into props bloats the HTML page and the RSC payload:

```ruby
# BAD: Sends the entire translation tree (potentially hundreds of KB)
messages: I18n.t('.').deep_stringify_keys

# GOOD: Send only the subset this page needs
messages: I18n.t('product_page').deep_stringify_keys
```

### Mistake 3: Using `messages['key']` for translations with placeholders

The build-time locale system converts Rails `%{variable}` placeholders to ICU `{variable}` syntax. Reading these directly from the messages object renders the literal placeholder text:

```jsx
// BAD: Renders "Hello, {name}" as literal text
const greeting = messages['greeting'];
```

```jsx
// GOOD: Use createIntl to format with variable substitution
import { createIntl } from 'react-intl';
const intl = createIntl({ locale, messages });
const greeting = intl.formatMessage({ id: 'greeting' }, { name: 'John' });
```

### Mistake 4: Reading Redux store in Server Components

Server Components render once on the server and never re-render. They cannot subscribe to store changes:

```jsx
// BAD: useSelector is a hook -- breaks in Server Components
export default function Dashboard({ user }) {
  const theme = useSelector((state) => state.theme); // ERROR
  return <div className={theme}>...</div>;
}
```

**Fix:** Keep the component as a Client Component (add `'use client'`), or pass the value from Rails as a prop to a Server Component that doesn't need the Redux store.

### Mistake 5: Creating new QueryClient on every render

If the `QueryClient` is created without `useState`, React creates a new instance on every render, losing the cache:

```jsx
// BAD: New QueryClient on every render -- cache is lost
'use client';
export default function QueryProvider({ children }) {
  const queryClient = new QueryClient(); // Re-created each render!
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}

// GOOD: useState ensures single instance
'use client';
import { useState } from 'react';
export default function QueryProvider({ children }) {
  const [queryClient] = useState(() => new QueryClient());
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
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
5. Import the composed provider into each registered Server Component that needs it
6. Pass server-fetched data (from Rails controller props) into the provider

### Phase 3: Replace Server-Side Context Usage

7. Replace `useContext` in data-fetching components with Rails controller props
8. For data shared between Server and Client Components, pass data directly as props (no Context needed)
9. Remove Context providers that only existed to pass server data down the tree

### Phase 4: State Management Libraries

10. Remove store reads/writes from Server Components
11. Move `<Provider>` wrapping into Client Component children when the parent becomes a Server Component
12. Consider reducing state library usage -- data previously fetched client-side and stored in Redux can now come directly from Rails controller props

## Next Steps

- [Data Fetching Migration](rsc-data-fetching.md) -- migrating from useEffect to server-side fetching
- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
