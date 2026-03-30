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
               product: @product.as_json(include: [:specs, :reviews]) }) %>
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

## Pattern 3: Streaming Slow Data

> **Note:** This section covers a cross-cutting concern (data fetching via `stream_react_component`) that affects how you structure context and state. For the full treatment of data fetching patterns, see [Data Fetching Migration](rsc-data-fetching.md).

In React on Rails, data comes from Rails as props. Rails fetches all data in the controller and passes it to `stream_react_component`, which uses React's streaming SSR to deliver the rendered HTML progressively.

```erb
<%= stream_react_component("ProductPage",
      props: { name: product.name, price: product.price,
               reviews: product.reviews.includes(:author).as_json,
               recommendations: RecommendationService.for(product).as_json }) %>
```

The component renders with all data available as props. `stream_react_component` uses React's streaming SSR to deliver the HTML progressively:

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

All props are available immediately in the component. `stream_react_component` handles progressive HTML delivery via React's `renderToPipeableStream`.

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

Internationalization in React on Rails typically uses Rails I18n on the server side and a client-side library (like `react-intl` or `i18next`) for Client Components. Pass translations from Rails as props:

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
// ProductPage.jsx -- Server Component
import I18nProvider from './I18nProvider';

export default function ProductPage({ locale, messages, ...props }) {
  // Server Components can use the translations object directly
  const title = messages['title'];

  return (
    <div>
      <h1>{title}</h1>
      <I18nProvider locale={locale} messages={messages}>
        <InteractiveFilters /> {/* Client Component can use useIntl() */}
      </I18nProvider>
    </div>
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
