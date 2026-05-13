# RSC Migration: Data Fetching Patterns

This guide covers how to migrate your data fetching from client-side patterns (`useEffect` + `fetch`, React Query, SWR) to Server Component patterns. In React on Rails, data flows from Rails to your components as props — eliminating the need for loading states, error handling boilerplate, and client-side caching in many cases.

> **Part 4 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous: [Context and State Management](rsc-context-and-state.md) | Next: [HTTP Response Ownership](rsc-http-response-patterns.md)

## The Core Shift: From Client-Side Fetching to Server-Side Data

In the traditional React model, components fetch data on the client after mounting. In the RSC model, data arrives from the server as props — the component simply renders it.

### Before: Client-Side Fetching

```jsx
'use client';

import { useState, useEffect } from 'react';

export default function UserProfile({ userId }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then((res) => res.json())
      .then((data) => {
        setUser(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err);
        setLoading(false);
      });
  }, [userId]);

  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;

  return <div>{user.name}</div>;
}
```

### After: Server Component

```jsx
// UserProfile.jsx -- Server Component (no directive)

export default function UserProfile({ user }) {
  return <div>{user.name}</div>;
}
```

Rails prepares the data in the controller and passes it as props. The component no longer fetches, manages loading states, or handles errors — it just renders.

**What changed:**

- No `useState` for data, loading, or error
- No `useEffect` lifecycle management
- No `'use client'` directive
- Data comes from Rails as props — no client-side fetching
- No loading spinner needed in the component itself
- No JavaScript ships to the client for this component

For pages with multiple data sources, use [`stream_react_component`](#data-fetching-in-react-on-rails-pro) to
stream the rendered HTML to the browser as React renders the component tree. When slower data sources should resolve
independently behind Suspense boundaries, use `stream_react_component_with_async_props`.

## Data Fetching in React on Rails Pro

In React on Rails applications, Ruby on Rails is the backend. Rather than bypassing Rails to access the database directly from Server Components, React on Rails Pro provides **`stream_react_component`** -- a streaming view helper that uses React's `renderToPipeableStream` to stream rendered HTML to the browser as React processes the component tree.

For ordinary Rails-provided props, pass the data through the helper's `props:` option. For slow or independent props that should resolve behind Suspense boundaries, use the async-props helper variant, **`stream_react_component_with_async_props`**. The helper block receives an emitter; call `emit.call(prop_name, value)` as each async prop becomes available. The Server Component reads emitted values with the injected `getReactOnRailsAsyncProp` prop.

This is the recommended data fetching pattern for React on Rails because:

- It preserves Rails' controller/model/view architecture
- It leverages Rails' existing data access layers (ActiveRecord, authorization, caching)
- It supports streaming SSR — HTML streams to the browser as React renders
- Data passes through Rails-provided props or async props -- no client-side fetching needed

### How Streaming Works

**Rails view (ERB), synchronous props:**

```erb
<%= stream_react_component("ProductPage",
      props: { name: product.name,
               price: product.price,
               reviews: product.reviews
                          .as_json(only: [:id, :text, :rating]) }) %>
```

**Rails view (ERB), async props:**

```erb
<%= stream_react_component_with_async_props("ProductPage",
      props: { name: product.name, price: product.price }) do |emit|
  emit.call("reviews", product.reviews.as_json(only: [:id, :text, :rating]))
end %>
```

> **See also:** [React on Rails Pro streaming SSR](../../pro/streaming-ssr.md) for setup instructions and configuration options.

**React component for synchronous props (Server Component):**

Use this version with the `stream_react_component` ERB helper above. Rails resolves every prop before rendering begins, including `reviews`.

```tsx
type Review = {
  id: number;
  text: string;
  rating: number;
};

type ProductPageProps = {
  name: string;
  price: number;
  reviews: Review[];
};

export default function ProductPage({ name, price, reviews }: ProductPageProps) {
  return (
    <div>
      <h1>{name}</h1>
      <p>${price}</p>
      <ReviewList reviews={reviews} />
    </div>
  );
}

function ReviewList({ reviews }: { reviews: Review[] }) {
  return (
    <ul>
      {reviews.map((review) => (
        <li key={review.id}>
          {review.text} ({review.rating}/5)
        </li>
      ))}
    </ul>
  );
}
```

**React component for async props (Server Component):**

Use this version with the `stream_react_component_with_async_props` ERB helper above. Keep the registered component name as `ProductPage`; the props shape changes so `reviews` comes from `getReactOnRailsAsyncProp`. `WithAsyncProps<AsyncProps, SyncProps>` combines the props passed directly through `props:` with a typed accessor for the keys emitted from Rails.

```tsx
import { Suspense } from 'react';
import type { WithAsyncProps } from 'react-on-rails-pro';

type Review = {
  id: number;
  text: string;
  rating: number;
};

type SyncProps = {
  name: string;
  price: number;
};

type AsyncProps = {
  reviews: Review[];
};

type ProductPageProps = WithAsyncProps<AsyncProps, SyncProps>;

function ReviewList({ reviews }: { reviews: Review[] }) {
  return (
    <ul>
      {reviews.map((review) => (
        <li key={review.id}>
          {review.text} ({review.rating}/5)
        </li>
      ))}
    </ul>
  );
}

async function AsyncReviewList({ reviewsPromise }: { reviewsPromise: Promise<Review[]> }) {
  // This awaits a Promise injected by getReactOnRailsAsyncProp, not a direct data fetch.
  return <ReviewList reviews={await reviewsPromise} />;
}

export default function ProductPage({ name, price, getReactOnRailsAsyncProp }: ProductPageProps) {
  const reviewsPromise = getReactOnRailsAsyncProp('reviews');

  return (
    <div>
      <h1>{name}</h1>
      <p>${price}</p>
      <Suspense fallback={<p>Loading reviews...</p>}>
        <AsyncReviewList reviewsPromise={reviewsPromise} />
      </Suspense>
    </div>
  );
}
```

> [!IMPORTANT]
> `<Suspense>` is the loading boundary, not the error UI. If the async-props stream closes before a requested prop is emitted, `getReactOnRailsAsyncProp` rejects and follows the same RSC/streaming error path as other Server Component render errors. Use the page-level handling described in [Error Boundary Limitations](./rsc-troubleshooting.md#error-boundary-limitations) rather than treating the Suspense fallback as failure UI.

**How it works:**

1. Rails loads synchronous data and passes it as props to `stream_react_component`, or as immediate `props:` to `stream_react_component_with_async_props` when slower props are emitted from the block
2. The streaming helper uses React's `renderToPipeableStream` for streaming SSR
3. HTML streams to the browser as React renders the component tree
4. No client-side fetching or `useEffect`-based loading state needed
5. The component renders with zero JavaScript cost as a Server Component

With async props, `stream_react_component_with_async_props` starts rendering with the synchronous `props:` values, then the block emits slow values with `emit.call`. The Server Component uses `getReactOnRailsAsyncProp` to obtain those values as Promises and places them behind Suspense boundaries.

> **HTML streaming vs. progressive data streaming:** With synchronous props, all data is loaded in Rails before rendering begins. The streaming here is _HTML streaming_ — React sends rendered HTML to the browser as it processes the component tree, rather than waiting for the entire page to finish rendering. For progressive data streaming, use `stream_react_component_with_async_props` so slow data sources resolve independently via Suspense boundaries.
>
> **More details:** For setup instructions and configuration options, see the [React on Rails Pro RSC documentation](../../pro/react-server-components/tutorial.md).

## Migrating from React Query / TanStack Query

React Query remains valuable in the RSC world for features like polling, optimistic updates, and infinite scrolling. But for simple data display, Server Components replace it entirely.

### Pattern 1: Simple Replacement (No Client Cache Needed)

If a component only displays data without mutations, polling, or optimistic updates, replace React Query with a Server Component:

```jsx
// Before: React Query
'use client';

import { useQuery } from '@tanstack/react-query';

function ProductList() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['products'],
    queryFn: () => fetch('/api/products').then((res) => res.json()),
  });

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error.message} />;

  return (
    <ul>
      {data.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

```erb
<%# ERB view — Rails passes the data as props %>
<%= stream_react_component("ProductList",
      props: { products: Product.limit(50).as_json(only: [:id, :name]) }) %>
```

```jsx
// After: Server Component -- receives data from Rails controller props
function ProductList({ products }) {
  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

> **React on Rails note:** In React on Rails, the controller prepares the data and passes it as props -- no `async/await` in the component, no direct data layer calls. For data that's slow to compute, use [`stream_react_component_with_async_props`](#data-fetching-in-react-on-rails-pro) to stream it in progressively with Suspense. The generic `async function` + `await` pattern shown in other RSC frameworks bypasses Rails' authorization and caching layers and is not recommended.

### Pattern 2: Rails Props as Initial Data (Keep React Query for Client Features)

When you need React Query's client features (background refetching, mutations, optimistic updates), pass Rails controller props as `initialData` so the component renders instantly with server data, then React Query takes over for client-side updates:

```jsx
// ReactQueryProvider.jsx -- Client Component (provides QueryClient)
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';

export default function ReactQueryProvider({ children }) {
  const [queryClient] = useState(() => new QueryClient());
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
```

```jsx
// ProductsPage.jsx -- Server Component (receives data from Rails controller props)
import ReactQueryProvider from './ReactQueryProvider';
import ProductList from './ProductList';

export default function ProductsPage({ products }) {
  return (
    <ReactQueryProvider>
      <ProductList initialProducts={products} />
    </ReactQueryProvider>
  );
}
```

```jsx
// ProductList.jsx -- Client Component (uses React Query hooks)
'use client';

import { useQuery } from '@tanstack/react-query';

export default function ProductList({ initialProducts }) {
  const { data: products } = useQuery({
    queryKey: ['products'],
    queryFn: () => fetch('/api/products').then((res) => res.json()),
    initialData: initialProducts,
    initialDataUpdatedAt: Date.now(), // Marks the data as fresh as of client render time
    staleTime: 5 * 60 * 1000, // Treat Rails-fetched data as fresh for 5 min
  });

  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>
          {p.name} - ${p.price}
        </li>
      ))}
    </ul>
  );
}
```

```erb
<%# ERB view — Rails passes the data as props %>
<%= stream_react_component("ProductsPage",
      props: { products: Product.limit(50).as_json }) %>
```

**How it works:**

1. Rails controller fetches products and passes them as props
2. Server Component passes the data to the Client Component as `initialProducts`
3. React Query uses `initialData` to populate the cache with no loading state on first render
4. Subsequent refetches happen client-side as usual

> **Note:** `initialDataUpdatedAt` and `staleTime` work together to prevent React Query from treating the Rails data as immediately stale on mount. `Date.now()` uses the client render timestamp, not the actual Rails fetch time — this is close enough for most apps. For precise control, pass a timestamp from your Rails controller (e.g., `(Time.now.to_f * 1000).to_i`) as a prop and use that instead. If you don't need timed refetching at all, use `staleTime: Infinity` to prevent automatic refetches entirely.

> **Alternative:** For complex cases with many queries, you can use TanStack Query's `dehydrate`/`HydrationBoundary` pattern to prefetch and seed the entire QueryClient cache on the server. See the [TanStack Query SSR docs](https://tanstack.com/query/latest/docs/framework/react/guides/ssr) for details.

## Migrating from SWR

SWR follows a similar pattern -- pass Rails controller props as `fallbackData` so the component renders instantly with server data:

```jsx
// DashboardPage.jsx -- Server Component (receives data from Rails controller props)
import DashboardStats from './DashboardStats';

export default function DashboardPage({ stats }) {
  return <DashboardStats fallbackData={stats} />;
}
```

```erb
<%# ERB view — Rails passes the data as props %>
<%= stream_react_component("DashboardPage",
      props: { stats: DashboardStats.compute.as_json }) %>
```

```jsx
// DashboardStats.jsx -- Client Component
'use client';

import useSWR from 'swr';

const fetcher = (url) => fetch(url).then((res) => res.json());

export default function DashboardStats({ fallbackData }) {
  const { data: stats } = useSWR('/api/dashboard/stats', fetcher, {
    fallbackData,
  });

  return (
    <div>
      <span>Revenue: {stats.revenue}</span>
      <span>Users: {stats.users}</span>
    </div>
  );
}
```

## Avoiding Server-Side Waterfalls

> **React on Rails note:** In React on Rails, the primary way to handle parallel data loading is [`stream_react_component_with_async_props`](#data-fetching-in-react-on-rails-pro) -- Rails emits each prop independently, and Suspense boundaries stream them to the browser as they resolve. The patterns below apply when you have async Server Components that fetch data directly (outside the async props flow).

The most critical performance pitfall with Server Components is sequential data fetching. When one `await` blocks the next, you create a waterfall on the server:

### The Problem: Sequential Queries

```ruby
# BAD: Each query blocks the next (750ms total)
def show
  @user = User.find(params[:user_id])          # 200ms
  @stats = DashboardStats.for(@user)           # 300ms (waits for user)
  @posts = @user.posts.recent                  # 250ms (sequential)
  stream_view_containing_react_components(template: "dashboard/show")
end
```

### Solution 1: Parallelize Independent Queries

When data sources are independent, use Ruby threads to fetch in parallel:

```ruby
# GOOD: Fetch in parallel (300ms -- limited by slowest)
def show
  user_id = params[:user_id]
  results = {}
  threads = []
  threads << Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      results[:user] = User.find(user_id).as_json
    end
  end
  threads << Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      results[:stats] = DashboardStats.compute.as_json
    end
  end
  threads << Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      results[:posts] = Post.recent.as_json
    end
  end
  threads.each(&:join)
  @dashboard_props = { title: "My Dashboard" }.merge(results)
  stream_view_containing_react_components(template: "dashboard/show")
end
```

```erb
<%# All data fetched in parallel, rendered with streaming SSR %>
<%= stream_react_component("Dashboard", props: @dashboard_props) %>
```

> **Note:** In production, wrap each thread body in a `rescue` to avoid incomplete results if a query fails. An unhandled exception in any thread will be re-raised by `join`.

### Solution 2: Separate Components for Independent Data

For data that is truly independent, render multiple `stream_react_component` calls. Each component renders as its data becomes available:

```erb
<%# Each component renders independently %>
<%= stream_react_component("DashboardHeader",
      props: { title: "My Dashboard" }) %>
<%= stream_react_component("UserProfile",
      props: { user: User.find(params[:user_id]).as_json(only: [:id, :name, :avatar_url]) }) %>
<%= stream_react_component("StatsPanel",
      props: { stats: DashboardStats.compute.as_json }) %>
<%= stream_react_component("PostFeed",
      props: { posts: Post.recent.as_json }) %>
```

```jsx
// Each component is a simple Server Component
function UserProfile({ user }) {
  return <div>{user.name}</div>;
}

function StatsPanel({ stats }) {
  return (
    <div>
      <span>Revenue: {stats.revenue}</span>
      <span>Users: {stats.users}</span>
    </div>
  );
}
function PostFeed({ posts }) {
  return (
    <ul>
      {posts.map((p) => (
        <li key={p.id}>{p.title}</li>
      ))}
    </ul>
  );
}
```

### Solution 3: Pass All Data as Props

Fetch all data in the controller and pass it as props. `stream_react_component` streams the rendered HTML to the browser via React's `renderToPipeableStream`:

```erb
<%= stream_react_component("ProductPage",
      props: { name: product.name,
               price: product.price,
               reviews: product.reviews
                          .as_json(only: [:id, :text, :rating]),
               related: product.recommended_products
                          .as_json(only: [:id, :name, :price]) }) %>
```

```jsx
export default function ProductPage({ name, price, reviews, related }) {
  return (
    <div>
      <h1>{name}</h1>
      <p>${price}</p>
      <ReviewList reviews={reviews} />
      <RelatedProducts products={related} />
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

function RelatedProducts({ products }) {
  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

All data is loaded in Rails before rendering begins. `stream_react_component` then streams the rendered HTML to the browser as React processes the component tree.

## The `use()` Hook for Client Components

The `use()` hook lets Client Components resolve promises. In React on Rails, data typically arrives as resolved props from Rails, so `use()` is most relevant when combining Server Components with client-side data fetching libraries.

### Common `use()` Mistakes in Client Components

Creating a promise inside a Client Component and passing it to `use()` triggers this runtime error:

> **"A component was suspended by an uncached promise. Creating promises inside a Client Component or hook is not yet supported, except via a Suspense-compatible library or framework."**

**Why it happens:** React tracks promises passed to `use()` by **object reference identity** across re-renders. On each render, it checks whether the promise is the same object as the previous render. When you create a promise inside a Client Component, every render produces a new promise instance -- React sees a different reference, cannot determine if the result is still valid, and throws.

```jsx
// WRONG: Creating a promise inline — new promise every render
'use client';
import { use } from 'react';

function Comments({ postId }) {
  const comments = use(fetch(`/api/comments/${postId}`).then((r) => r.json()));
  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}
```

```jsx
// WRONG: Variable doesn't help — still a new promise every render
'use client';
import { use } from 'react';

function Comments({ postId }) {
  const promise = getComments(postId); // New promise object each render
  const comments = use(promise);
  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}
```

```jsx
// WRONG: useMemo seems to work but is NOT reliable
'use client';
import { use, useMemo } from 'react';

function Comments({ postId }) {
  const promise = useMemo(() => getComments(postId), [postId]);
  const comments = use(promise);
  // React does NOT guarantee useMemo stability. From the docs:
  // "React may choose to 'forget' some previously memoized values
  //  and recalculate them on next render."
  // If React discards the memoized value, a new promise is created,
  // and use() throws the uncached promise error intermittently.
}
```

**The safe approach -- use a Suspense-compatible library:**

```jsx
// CORRECT: Suspense-compatible library (TanStack Query)
'use client';
import { useSuspenseQuery } from '@tanstack/react-query';

function Comments({ postId }) {
  const { data: comments } = useSuspenseQuery({
    queryKey: ['comments', postId],
    queryFn: () => getComments(postId), // client-side fetch wrapper
  });
  // The library manages promise identity internally —
  // same cache key returns the same promise reference.
  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}
```

> **Rule:** Never create a raw promise for `use()` inside a Client Component. Use a Suspense-compatible library like TanStack Query or SWR that manages promise identity internally.

## Request Deduplication with `React.cache()`

> **React on Rails note:** In most React on Rails applications, data flows through controller props or `stream_react_component_with_async_props`, so `React.cache()` is unnecessary. This section applies when Server Components call data-fetching functions directly (for example, from the Node renderer). If you are using `stream_react_component_with_async_props`, repeated calls within the same request already share the same deduped Promise.

When multiple Server Components need the same data, `React.cache()` ensures the fetch happens only once per request:

```jsx
// lib/data.js -- Define at module level
import { cache } from 'react';

export const getUser = cache(async (id) => {
  return await fetchUserById(id);
});
```

```jsx
// Navbar.jsx and Sidebar.jsx both import getUser.
// The first call fetches; the second returns the cached result.
async function Navbar({ userId }) {
  const user = await getUser(userId);
  return <nav>Welcome, {user.name}</nav>;
}
```

**Key properties:**

- Cache is scoped to the **current request** -- no cross-request data leakage
- Uses `Object.is` for argument comparison (pass primitives, not objects)
- Must be defined at **module level**, not inside components
- Only works in Server Components

> **Note:** `React.cache()` is only available in React Server Component environments. It is not available in Client Components or non-RSC server rendering (e.g., `renderToString`).

For most React on Rails applications, you won't need `React.cache()` because data flows through Rails controller props.

## Mutations: Rails Controllers, Not Server Actions

> **Important:** React on Rails does **not** support Server Actions (`'use server'`). Server Actions run on the Node renderer, which is a rendering server -- it has no access to Rails models, sessions, cookies, or CSRF protection. Do not use `'use server'` in React on Rails applications.

All mutations in React on Rails should go through Rails controllers via standard forms or API endpoints:

```jsx
// CommentForm.jsx -- Client Component
'use client';

import { useState } from 'react';
import ReactOnRails from 'react-on-rails';

export default function CommentForm({ postId }) {
  const [content, setContent] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    const response = await fetch('/api/comments', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': ReactOnRails.authenticityToken(),
      },
      body: JSON.stringify({ comment: { content, postId } }),
    });
    if (!response.ok) throw new Error(`Request failed: ${response.status}`);
    setContent('');
  }

  return (
    <form onSubmit={handleSubmit}>
      <textarea value={content} onChange={(e) => setContent(e.target.value)} />
      <button type="submit">Post Comment</button>
    </form>
  );
}
```

```erb
<%# ERB view %>
<%= stream_react_component("CommentForm",
      props: { postId: @post.id }) %>
```

> **Note:** `ReactOnRails.authenticityToken()` reads the CSRF token from the `<meta name="csrf-token">` tag, which is the standard Rails approach. This avoids duplicating the token in component props.

This preserves Rails' full controller/model layer -- authentication, authorization, CSRF protection, and validations all work as expected.

## When to Keep Client-Side Fetching

Not everything should move to the server. In React on Rails, most read-only data is already server-side -- Rails controller props deliver it to your components without any client-side fetching. The table below covers the cases where you should keep client-side fetching instead of relying on Rails controller props or [`stream_react_component_with_async_props`](#data-fetching-in-react-on-rails-pro):

| Use Case                        | Why Client-Side                            | Recommended Tool                    |
| ------------------------------- | ------------------------------------------ | ----------------------------------- |
| Real-time data (WebSocket, SSE) | Requires persistent connection             | Native WebSocket + `useState`       |
| Polling / auto-refresh          | Periodic updates after initial load        | React Query / SWR                   |
| Optimistic updates              | Instant UI feedback before server confirms | React Query mutations               |
| Infinite scrolling              | User-driven pagination                     | React Query / SWR                   |
| User-triggered searches         | Response to client interactions            | `useState` + `fetch` or React Query |
| Offline-first features          | Must work without server                   | Local state + sync                  |

### Hybrid Pattern: Rails Props + Client Updates

For features that need server-fetched initial data with client-side updates:

```erb
<%# ERB view — Rails passes initial data as props %>
<%= stream_react_component("ChatPage",
      props: { channelId: @channel.id,
               initialMessages: @channel.messages.recent.as_json }) %>
```

```jsx
// ChatPage.jsx -- Server Component
import ChatWindow from './ChatWindow';

export default function ChatPage({ channelId, initialMessages }) {
  return (
    <div>
      <ChannelHeader channelId={channelId} />
      <ChatWindow channelId={channelId} initialMessages={initialMessages} />
    </div>
  );
}
```

```jsx
// ChatWindow.jsx -- Client Component
'use client';

import { useState, useEffect } from 'react';

export default function ChatWindow({ channelId, initialMessages }) {
  const [messages, setMessages] = useState(initialMessages);

  useEffect(() => {
    const ws = new WebSocket(`wss://api.example.com/chat/${channelId}`);
    ws.onmessage = (event) => {
      setMessages((prev) => [...prev, JSON.parse(event.data)]);
    };
    return () => ws.close();
  }, [channelId]);

  return <MessageList messages={messages} />;
}
```

## Loading States and Suspense Boundaries

### Streaming HTML Delivery

With synchronous props, Rails loads all data before rendering begins. `stream_react_component` then streams the rendered HTML as React processes the component tree — the browser receives content as it's rendered rather than waiting for the entire page:

```erb
<%# ERB view — Rails passes all data as props %>
<%= stream_react_component("Page",
      props: { title: @page.title,
               main_content: @page.main_content.as_json,
               recommendations: RecommendationService.for(@page).as_json,
               comments: @page.comments.recent.as_json }) %>
```

```jsx
export default function Page({ title, main_content, recommendations, comments }) {
  return (
    <div>
      <Header />
      <h1>{title}</h1>
      <nav>
        <SideNav />
      </nav>

      <main>
        <MainContent content={main_content} />
        <Recommendations items={recommendations} />
        <Comments comments={comments} />
      </main>
    </div>
  );
}
```

### Avoiding "Popcorn UI"

When many Suspense boundaries resolve at different times, content pops in unpredictably. Group related content in a single boundary:

```jsx
// Bad: Each section pops in individually
<Suspense fallback={<Skeleton1 />}><Section1 /></Suspense>
<Suspense fallback={<Skeleton2 />}><Section2 /></Suspense>
<Suspense fallback={<Skeleton3 />}><Section3 /></Suspense>

// Better: Related sections appear together
<Suspense fallback={<CombinedSkeleton />}>
  <Section1 />
  <Section2 />
  <Section3 />
</Suspense>
```

### Dimension-Matched Skeletons

Use skeleton components that match the dimensions of the real content to prevent layout shift:

```jsx
function StatsSkeleton() {
  return (
    <div className="stats-panel" style={{ height: '200px' }}>
      <div className="skeleton-bar" />
      <div className="skeleton-bar" />
      <div className="skeleton-bar" />
    </div>
  );
}
```

## Common Mistakes

### Mistake 1: Sequential queries in the Rails controller

The most common performance regression after migrating to RSC. Since data now comes from the Rails controller (instead of parallel client-side fetches), sequential ActiveRecord queries block the entire page render:

```ruby
# BAD: 750ms total -- each query waits for the previous one
def show
  @user = User.find(params[:id])              # 200ms
  @stats = Stats.for_user(@user.id)          # 300ms
  @posts = Post.where(user_id: @user.id)     # 250ms
  stream_view_containing_react_components(template: "show")
end
```

**Fix:** Use Ruby threads for independent queries (see [Avoiding Server-Side Waterfalls](#avoiding-server-side-waterfalls)), use `stream_react_component_with_async_props` for slow props within one component, or split truly independent sections into multiple `stream_react_component` calls in the ERB view.

### Mistake 2: Using Server Actions (`'use server'`)

Server Actions are **not supported** in React on Rails in any environment. The Node renderer is a rendering server -- it has no access to Rails models, sessions, cookies, or CSRF protection.

```jsx
// BAD: Server Actions don't have access to Rails
'use server';
export async function createUser(name) {
  // The Node renderer is a render-only environment -- it has no database
  // connection, no ORM, and no access to Rails models or sessions.
  // This code will fail at runtime.
}
```

```jsx
// GOOD: Use a Client Component that submits to a Rails controller endpoint
'use client';

import { useState } from 'react';
import ReactOnRails from 'react-on-rails';

export default function CreateUserForm() {
  const [name, setName] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    await fetch('/api/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': ReactOnRails.authenticityToken(),
      },
      body: JSON.stringify({ user: { name } }),
    });
    setName('');
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={name} onChange={(e) => setName(e.target.value)} />
      <button type="submit">Create</button>
    </form>
  );
}
```

### Mistake 3: Forgetting CSRF tokens in fetch requests

Rails rejects POST/PUT/PATCH/DELETE requests without a valid CSRF token. This is easy to miss when migrating from forms that included the token automatically:

```jsx
// BAD: Missing CSRF token -- Rails returns 422 Unprocessable Entity
await fetch('/api/items', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(data),
});

// GOOD: Include the CSRF token
await fetch('/api/items', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': ReactOnRails.authenticityToken(),
  },
  body: JSON.stringify(data),
});
```

### Mistake 4: Removing loading states before adding streaming

If you remove `useEffect` + loading state but haven't set up streaming with Suspense boundaries, the page appears blank until all server data is ready:

**Fix:** Complete the streaming setup ([Preparing Your App](rsc-preparing-app.md#step-6-switch-to-streaming-rendering)) before converting data-fetching components. Use `stream_react_component_with_async_props` for Rails data that should resolve behind Suspense, and add Suspense boundaries around sections that should stream independently.

### Mistake 5: Over-serializing ActiveRecord objects

Calling `.as_json` without specifying `only:` or `include:` can serialize the entire object graph, including associations, timestamps, and internal fields. This bloats the RSC payload and can leak sensitive data:

```ruby
# BAD: Serializes everything, including potentially sensitive fields
props: { user: @user.as_json }

# GOOD: Whitelist exactly what the component needs
props: { user: @user.as_json(only: [:id, :name, :email]) }
```

## Migration Checklist

### Step 1: Identify Candidates

For each component that fetches data:

- Does it only display data? → Convert to Server Component (pass data as props via `stream_react_component`)
- Does it need polling/optimistic updates? → Keep React Query/SWR, add server prefetch
- Does it need real-time updates? → Keep client-side, pass initial data from server

### Step 2: Convert Simple Fetches

1. Remove the `'use client'` directive
2. Remove `useState` for data, loading, and error
3. Remove the `useEffect` data fetch
4. Accept data as props from Rails. For slow data, keep immediate values in `props:` and emit the slow values with [`stream_react_component_with_async_props`](#data-fetching-in-react-on-rails-pro).
5. Use the matching ERB helper to enable streaming SSR: `stream_react_component` for synchronous props, or `stream_react_component_with_async_props` for async props.
6. Remove the API route if it was only used by this component

### Step 3: Add Suspense Boundaries

7. Wrap converted components in `<Suspense>` at the parent level
8. Create skeleton components that match content dimensions
9. Group related data sections in shared boundaries

### Step 4: Optimize

10. Use `stream_react_component` for synchronous props and streaming HTML delivery via React's `renderToPipeableStream`
11. Use `stream_react_component_with_async_props` for slow Rails props, or parallelize independent Ruby queries with threads to avoid server-side waterfalls
12. For client-side updates after initial render, use React Query or SWR with `initialData`/`fallbackData`

## Next Steps

- [HTTP Response Ownership](rsc-http-response-patterns.md) -- status codes, redirects, and cache headers
- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
