# React Server Components & Streaming in React on Rails Pro

## Why RSC with Streaming?

### Waterfall Loading Pattern Benefits

React Server Components with streaming is beneficial for most applications, but it's especially powerful for applications with waterfall loading patterns where data dependencies chain together. For example, when you need to load a user profile before loading their posts, or fetch categories before products. Here's why:

### How RSC Fixes Waterfall Server Rendering Issues:

When a user visits the page, they'll experience the following sequence:

1. The initial HTML shell is sent immediately, including:
   - The page layout
   - Any static content (like the `<h1>` and footer)
   - Placeholder content for the React component (typically a loading state)

2. Selective Hydration:
   - Client components hydrate independently as their code chunks load
   - Multiple components can hydrate in parallel
   - User interactions automatically prioritize hydration of interacted components
   - No waiting for full page JavaScript or other components to load
   - Each component becomes interactive immediately after its own hydration

### Bundle Size Benefits

React Server Components significantly reduce client-side JavaScript by:

1. **Server-Only Code Elimination:**
   - Dependencies used only in server components never ship to the client
   - Database queries, API calls, and their libraries stay server-side
   - Heavy data processing utilities remain on the server
   - Server-only NPM packages don't impact client bundle

2. **Concrete Examples:**
   - Routing logic can stay server-side
   - Data fetching libraries (like React Query) are often unnecessary
   - Large formatting libraries (e.g., date-fns, numeral) can be server-only
   - Image processing utilities stay on server
   - Markdown parsers run server-side only
   - Heavy validation libraries remain server-side

For example, a typical dashboard might see:

```jsx
// Before: All code shipped to client
import { format } from 'date-fns'; // ~30KB
import { marked } from 'marked'; // ~35KB
import numeral from 'numeral'; // ~25KB

// After: With RSC, these imports stay server-side
// Client bundle reduced by ~90KB
```

### [Selective Hydration](https://github.com/reactwg/react-18/discussions/37) Benefits

React's selective hydration is a powerful feature that significantly improves page interactivity by:

1. **Independent Component Hydration**
   - Each client component hydrates independently as soon as its code loads
   - No waiting for the entire page's JavaScript to load and execute
   - Components become interactive progressively rather than all at once

2. **Interaction-Based Prioritization**
   - React automatically prioritizes hydrating components that users try to interact with
   - If a user clicks a button before hydration, that component gets priority
   - Other components continue hydrating in the background
   - Better perceived performance as users can interact sooner

3. **Parallel Processing**
   - Multiple components can hydrate simultaneously
   - Network requests for component code happen in parallel
   - CPU processing for hydration is interleaved efficiently
   - Maximizes browser resources for faster overall interactivity

For example, in a typical page layout:

```jsx
<Layout>
  <Suspense fallback={<NavSkeleton />}>
    <Navigation /> {/* Client component */}
  </Suspense>
  <Suspense fallback={<MainSkeleton />}>
    <MainContent /> {/* Client component */}
    <Comments /> {/* Client component */}
  </Suspense>
  <Suspense fallback={<SidebarSkeleton />}>
    <Sidebar /> {/* Client component */}
  </Suspense>
</Layout>
```

With selective hydration:

- Navigation could become interactive while Comments are still loading
- If user tries to click a Sidebar button, it gets priority hydration
- Each component hydrates independently when ready
- No waiting for all components to load before any become interactive

This approach significantly improves the user experience by:

- Reducing Time to Interactive (TTI) for important components
- Providing faster response to user interactions
- Maintaining smooth performance even on slower devices or networks
- Eliminating the "all or nothing" hydration approach of traditional SSR

For a deeper dive into selective hydration, see our [Selective Hydration in Streamed Components](./selective-hydration-in-streamed-components.md) guide.

### Comparison with Other Approaches:

1. **Full Server Rendering:**

- ❌ Delays First Byte until entire page is rendered
- ❌ All-or-nothing approach to hydration
- ❌ Must wait for all JavaScript before any interactivity
- ✅ Good SEO
- ✅ Complete initial HTML

2. **Client-side Lazy Loading:**

- ❌ Empty initial HTML for lazy components
- ❌ Must wait for hydration to load
- ❌ Poor SEO for lazy content
- ❌ No prioritization of component hydration
- ❌ Initial page must be loaded and hydrated before loading lazy components
- ✅ Reduces initial bundle size

3. **RSC with Streaming:**

- ✅ Immediate First Byte
- ✅ Progressive HTML streaming
- ✅ SEO-friendly for all content
- ✅ No hydration waiting for server components
- ✅ Selective client hydration

## Migration Guide

### 1. Enable RSC Support

Add to your Rails initializer, it makes the magic happen 🪄:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.enable_rsc_support = true
end
```

### 2. Update Webpack Configuration

Create RSC bundle and make it use the RSC loader:

```javascript
// config/webpack/rscWebpackConfig.mjs
const rscConfig = serverWebpackConfig();

// Configure RSC entry point
rscConfig.entry = {
  'rsc-bundle': rscConfig.entry['server-bundle'],
};

// Add RSC loader
rules.forEach((rule) => {
  if (Array.isArray(rule.use)) {
    const babelLoader = extractLoader(rule, 'babel-loader');
    if (babelLoader) {
      rule.use.push({
        loader: 'react-on-rails-rsc/WebpackLoader',
      });
    }
  }
});
```

### 3. Gradual Component Migration

#### 1. Mark Entry Points as Client Components

Adding the `'use client'` directive to entry points maintains existing functionality while allowing for incremental migration of individual components to server components.
This approach ensures a smooth transition without disrupting the application's current behavior.

```jsx
// app/components/App.jsx
'use client';

export default function App() {
  // Your existing component code
}
```

#### 2. Identify Server Component Candidates:

- Data fetching components
- Non-interactive UI
- Static content sections
- Layout components

#### 3. Progressive Migration Pattern (Top-Down Approach):

Start by converting layout and container components at the top of your component tree to server components, moving any interactive logic down to child components. This "top-down" approach maximizes the benefits of RSC.

```jsx
// app/components/Layout.jsx
// Remove 'use client' - This becomes a server component
// Move any state/effects to child components first
export default function Layout({ children }) {
  return (
    <div>
      <Header /> {/* Server component */}
      <Sidebar /> {/* Server component */}
      <main>
        {children} {/* Interactive components like InteractiveWidget remain nested inside */}
      </main>
      <Footer /> {/* Server component */}
    </div>
  );
}
```

```jsx
// app/components/InteractiveWidget.jsx
'use client'; // Keep client directive for interactive components

export default function InteractiveWidget() {
  const [state, setState] = useState();
  // Interactive component logic
}
```

#### 4. Convert Lazy-Loaded Entry Points:

```jsx
// app/components/LazyLoadedSection.jsx
// Remove lazy loading wrapper
// Convert to async server component
async function LazyLoadedSection() {
  const data = await fetchData();
  return (
    <div>
      <ServerContent data={data} />
      <ClientInteraction /> {/* Keeps 'use client' */}
    </div>
  );
}
```

This migration approach allows you to:

- Maintain existing functionality while migrating
- Incrementally improve performance
- Test changes in isolation
- Keep interactive components working as before
- Eliminate client-side lazy loading overhead
