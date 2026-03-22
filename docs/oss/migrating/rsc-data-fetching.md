# RSC Migration: Data Fetching Patterns

This guide covers how to migrate your data fetching from client-side patterns (`useEffect` + `fetch`, React Query, SWR) to Server Component patterns. In React on Rails, data flows from Rails to your components as props — eliminating the need for loading states, error handling boilerplate, and client-side caching in many cases.

> **Part 4 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous: [Context and State Management](rsc-context-and-state.md) | Next: [Third-Party Library Compatibility](rsc-third-party-libs.md)

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

For pages with multiple data sources that should stream progressively, use [async props](#data-fetching-in-react-on-rails-pro) to receive data incrementally with Suspense.

## Data Fetching in React on Rails Pro

In React on Rails applications, Ruby on Rails is the backend. Rather than bypassing Rails to access the database directly from Server Components, React on Rails Pro provides **async props** -- a streaming mechanism where Rails sends props incrementally through its normal controller/view layers.

This is the recommended data fetching pattern for React on Rails because:

- It preserves Rails' controller/model/view architecture
- It leverages Rails' existing data access layers (ActiveRecord, authorization, caching)
- It supports streaming for progressive rendering with Suspense
- Sync props render immediately; async props stream in as they become available

### How Async Props Work

**Rails view (ERB):**

```erb
<%= stream_react_component_with_async_props("ProductPage",
      props: { name: product.name, price: product.price }) do |emit|
  # Sync props (name, price) are sent immediately and render right away.
  # Async props stream in when ready:
  emit.call("reviews", product.reviews.as_json)
  emit.call("recommendations", product.recommended_products.as_json)
end %>
```

> **See also:** [`stream_react_component_with_async_props` RSC tutorial](../../pro/react-server-components/tutorial.md) for setup instructions and configuration options.

**React component (Server Component):**

```tsx
import { Suspense } from 'react';
import type { WithAsyncProps } from 'react-on-rails-pro';

type SyncProps = { name: string; price: number };
type AsyncProps = { reviews: Review[]; recommendations: Product[] };
type Props = WithAsyncProps<AsyncProps, SyncProps>;

export default function ProductPage({ name, price, getReactOnRailsAsyncProp }: Props) {
  const reviewsPromise = getReactOnRailsAsyncProp('reviews');
  const recommendationsPromise = getReactOnRailsAsyncProp('recommendations');

  return (
    <div>
      <h1>{name}</h1>
      <p>${price}</p>

      <Suspense fallback={<p>Loading reviews...</p>}>
        <Reviews reviews={reviewsPromise} />
      </Suspense>
      <Suspense fallback={<p>Loading recommendations...</p>}>
        <Recommendations items={recommendationsPromise} />
      </Suspense>
    </div>
  );
}

// Async Server Component -- awaits the streamed prop
async function Reviews({ reviews }: { reviews: Promise<Review[]> }) {
  const resolved = await reviews;
  return (
    <ul>
      {resolved.map((r) => (
        <li key={r.id}>{r.text}</li>
      ))}
    </ul>
  );
}
```

**How it works:**

1. Sync props (`name`, `price`) render immediately -- the component shows content right away
2. `getReactOnRailsAsyncProp('reviews')` returns a promise that resolves when Rails calls `emit.call("reviews", ...)`
3. Each `<Suspense>` boundary shows its fallback until the corresponding async prop arrives
4. Rails can perform expensive operations (database queries, external API calls) between `emit.call` invocations
5. Content streams progressively to the browser as each async prop resolves

### Simulating Delayed Data

In development, you can add `sleep` calls to simulate slow data sources and see how streaming behaves:

```erb
<%= stream_react_component_with_async_props("Dashboard",
      props: { title: "My Dashboard" }) do |emit|
  sleep 1  # Simulate slow database query
  emit.call("stats", DashboardStats.compute.as_json)

  sleep 2  # Simulate external API call
  emit.call("notifications", Notification.recent.as_json)
end %>
```

The `title` prop renders instantly. After 1 second, stats stream in. After another 2 seconds, notifications appear. Each section fills in independently thanks to Suspense boundaries.

### TypeScript Typing

The `WithAsyncProps` type ensures type safety for both sync and async props:

```tsx
import type { WithAsyncProps } from 'react-on-rails-pro';

// Define sync and async prop shapes separately
type SyncProps = { title: string };
type AsyncProps = {
  users: User[];
  posts: Post[];
};

// WithAsyncProps<AsyncProps, SyncProps> produces:
// {
//   title: string;
//   getReactOnRailsAsyncProp: <K extends 'users' | 'posts'>(key: K) => Promise<AsyncProps[K]>;
// }
type Props = WithAsyncProps<AsyncProps, SyncProps>;
```

`getReactOnRailsAsyncProp` is fully typed -- calling `getReactOnRailsAsyncProp('users')` returns `Promise<User[]>`, and passing an invalid key is a compile-time error.

> **More details:** For setup instructions, configuration options, and the RSC payload variant (`rsc_payload_react_component_with_async_props`), see the [React on Rails Pro RSC documentation](../../pro/react-server-components/tutorial.md).

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

```jsx
// After: Server Component -- receives data as Rails props
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

```erb
<%# ERB view — Rails passes the data as props %>
<%= stream_react_component("ProductList",
      props: { products: Product.limit(50).as_json }) %>
```

In React on Rails, data comes from Rails as props. The component simply renders it — no fetching, no loading states. For data that should stream progressively, use [async props](#data-fetching-in-react-on-rails-pro).

### Pattern 2: Rails Props as `initialData` (Keep React Query for Client Features)

When you need React Query's client features (background refetching, mutations, optimistic updates), pass Rails props as `initialData` so the component renders immediately and React Query takes over for subsequent updates:

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
// ProductsPage.jsx -- Server Component
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
3. React Query uses `initialData` to populate the cache -- no loading state on first render
4. Subsequent refetches happen client-side as usual

> **Note:** `initialDataUpdatedAt: Date.now()` uses the client render timestamp, not the actual Rails fetch time. This is close enough for most apps. For precise control, pass a timestamp from your Rails controller (e.g., `(Time.now.to_f * 1000).to_i`) as a prop and use that instead. If you don't need timed refetching at all, use `staleTime: Infinity` to prevent automatic refetches entirely.

## Migrating from SWR

SWR follows a similar pattern -- pass Rails props as `fallbackData` so the component renders immediately and SWR takes over for revalidation:

```jsx
// DashboardPage.jsx -- Server Component
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

In React on Rails, the most critical performance pitfall is sequential data emission on the Ruby side. When one `emit.call` blocks the next because the preceding query hasn't finished, you create a waterfall:

### The Problem: Sequential Emission

```erb
<%# BAD: Each emit blocks the next %>
<%= stream_react_component_with_async_props("Dashboard",
      props: { title: "My Dashboard" }) do |emit|
  user = User.find(params[:user_id])          # 200ms
  emit.call("user", user.as_json)

  stats = DashboardStats.for(user)             # 300ms (waits for user)
  emit.call("stats", stats.as_json)

  posts = user.posts.recent                    # 250ms (waits because calls are sequential)
  emit.call("posts", posts.as_json)
  # Total: 750ms (sequential)
end %>
```

### Solution 1: Parallelize Independent Queries

When data sources are independent, use Ruby threads to fetch in parallel:

```erb
<%# GOOD: Fetch in parallel, then emit results serially %>
<%= stream_react_component_with_async_props("Dashboard",
      props: { title: "My Dashboard" }) do |emit|
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
  # Emit after all threads complete — avoids concurrent writes to the stream
  results.each { |key, val| emit.call(key.to_s, val) }
  # Total: 300ms (limited by slowest)
end %>
```

> **Note:** In production, wrap each thread body in a `rescue` to avoid incomplete streams if a query fails. An unhandled exception in any thread will be re-raised by `join`, skipping the remaining `emit.call` invocations.

### Solution 2: Progressive Streaming with Async Props

For the best user experience -- each async prop streams independently as it becomes ready, and Suspense boundaries let the UI fill in progressively. Total server time is the same as sequential, but _perceived_ performance improves because the user sees content as each prop resolves:

```erb
<%# PROGRESSIVE: Each prop streams to the browser as it resolves %>
<%= stream_react_component_with_async_props("Dashboard",
      props: { title: "My Dashboard" }) do |emit|
  emit.call("user", User.find(params[:user_id]).as_json)        # Streams at ~200ms
  emit.call("stats", DashboardStats.compute.as_json)             # Streams at ~500ms
  emit.call("posts", Post.recent.as_json)                        # Streams at ~750ms
end %>
```

```jsx
// Dashboard.jsx -- Server Component
import { Suspense } from 'react';

export default function Dashboard({ title, getReactOnRailsAsyncProp }) {
  const userPromise = getReactOnRailsAsyncProp('user');
  const statsPromise = getReactOnRailsAsyncProp('stats');
  const postsPromise = getReactOnRailsAsyncProp('posts');

  return (
    <div>
      <h1>{title}</h1>
      <Suspense fallback={<UserSkeleton />}>
        <UserProfile userPromise={userPromise} />
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel statsPromise={statsPromise} />
      </Suspense>
      <Suspense fallback={<FeedSkeleton />}>
        <PostFeed postsPromise={postsPromise} />
      </Suspense>
    </div>
  );
}

async function UserProfile({ userPromise }) {
  const user = await userPromise;
  return <div>{user.name}</div>;
}

async function StatsPanel({ statsPromise }) {
  const stats = await statsPromise;
  return (
    <div>
      <span>Revenue: {stats.revenue}</span>
      <span>Users: {stats.users}</span>
    </div>
  );
}

async function PostFeed({ postsPromise }) {
  const posts = await postsPromise;
  return (
    <ul>
      {posts.map((p) => (
        <li key={p.id}>{p.title}</li>
      ))}
    </ul>
  );
}
```

Each `<Suspense>` boundary lets React stream content progressively. The user sees each section as its async prop resolves, rather than waiting for everything.

### Solution 3: Mixed Strategy (Sync Critical + Stream Secondary)

Use sync props for critical data that the page shell needs immediately, and async props for secondary data:

```erb
<%= stream_react_component_with_async_props("ProductPage",
      props: { name: product.name, price: product.price }) do |emit|
  emit.call("reviews", product.reviews.as_json)
  emit.call("related", product.recommended_products.as_json)
end %>
```

```jsx
import { Suspense } from 'react';

export default function ProductPage({ name, price, getReactOnRailsAsyncProp }) {
  const reviewsPromise = getReactOnRailsAsyncProp('reviews');
  const relatedPromise = getReactOnRailsAsyncProp('related');

  return (
    <div>
      <h1>{name}</h1>
      <p>${price}</p>
      <Suspense fallback={<ReviewsSkeleton />}>
        <ReviewsSection reviewsPromise={reviewsPromise} />
      </Suspense>
      <Suspense fallback={<RelatedSkeleton />}>
        <RelatedSection relatedPromise={relatedPromise} />
      </Suspense>
    </div>
  );
}

async function ReviewsSection({ reviewsPromise }) {
  const reviews = await reviewsPromise;
  return <ReviewList reviews={reviews} />;
}

async function RelatedSection({ relatedPromise }) {
  const related = await relatedPromise;
  return <RelatedProducts products={related} />;
}
```

Sync props (`name`, `price`) render instantly -- no Suspense boundary needed. Async props stream in with individual fallbacks.

## Streaming with the `use()` Hook

The `use()` hook lets Client Components resolve promises that were started on the server. In React on Rails, this works with async props -- pass the promise from `getReactOnRailsAsyncProp` to a Client Component that resolves it with `use()`:

```erb
<%# ERB view %>
<%= stream_react_component_with_async_props("PostPage",
      props: { title: post.title, body: post.body }) do |emit|
  emit.call("comments", post.comments.includes(:author).as_json)
end %>
```

```jsx
// PostPage.jsx -- Server Component
import { Suspense } from 'react';
import Comments from './Comments';

export default function PostPage({ title, body, getReactOnRailsAsyncProp }) {
  const commentsPromise = getReactOnRailsAsyncProp('comments');

  return (
    <article>
      <h1>{title}</h1>
      <p>{body}</p>
      <Suspense fallback={<p>Loading comments...</p>}>
        <Comments commentsPromise={commentsPromise} />
      </Suspense>
    </article>
  );
}
```

```jsx
// Comments.jsx -- Client Component
'use client';

import { use } from 'react';

export default function Comments({ commentsPromise }) {
  const comments = use(commentsPromise); // Resolves the promise
  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}
```

**Benefits:**

- The post title and body render immediately as sync props
- `getReactOnRailsAsyncProp('comments')` returns a promise that resolves when Rails calls `emit.call("comments", ...)`
- `<Suspense>` shows the fallback until the async prop arrives
- The Client Component resolves the promise with `use()` -- no fetch logic needed

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

**The two safe approaches:**

```jsx
// CORRECT: Promise from getReactOnRailsAsyncProp, passed as a prop
// Page.jsx -- Server Component
import { Suspense } from 'react';

export default function Page({ getReactOnRailsAsyncProp }) {
  // getReactOnRailsAsyncProp returns a cached promise (same object on repeated calls)
  const commentsPromise = getReactOnRailsAsyncProp('comments');
  return (
    <Suspense fallback={<p>Loading...</p>}>
      <Comments commentsPromise={commentsPromise} />
    </Suspense>
  );
}

// Comments.jsx -- Client Component
'use client';
import { use } from 'react';

export default function Comments({ commentsPromise }) {
  const comments = use(commentsPromise); // Safe: stable reference from async props
  return <ul>{comments.map(c => <li key={c.id}>{c.text}</li>)}</ul>;
}
```

```jsx
// CORRECT: Suspense-compatible library (TanStack Query)
'use client';
import { useSuspenseQuery } from '@tanstack/react-query';

function Comments({ postId }) {
  const { data: comments } = useSuspenseQuery({
    queryKey: ['comments', postId],
    queryFn: () => getComments(postId), // client-side fetch wrapper — not the server-side function above
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

> **Rule:** Never create a raw promise for `use()` inside a Client Component. Either receive it from a Server Component as a prop (via `getReactOnRailsAsyncProp` or another stable source), or use a Suspense-compatible library like TanStack Query or SWR.

## Request Deduplication with `React.cache()`

> **React on Rails note:** If you use [async props](#data-fetching-in-react-on-rails-pro), `getReactOnRailsAsyncProp` already returns the **same promise object** on repeated calls with the same key. No `React.cache()` wiring is needed -- you can pass the promise to multiple children and each will receive the same cached result. The section below applies only when you bypass async props and call data-fetching functions directly from Server Components.

`React.cache()` ensures a function is called only once per request, even when multiple Server Components invoke it:

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

For most React on Rails applications, you won't need `React.cache()` because data flows through Rails props and async props, both of which handle caching at their respective layers.

## Mutations: Rails Controllers, Not Server Actions

> **Important:** React on Rails does **not** support Server Actions (`'use server'`). Server Actions run on the Node renderer, which is a rendering server -- it has no access to Rails models, sessions, cookies, or CSRF protection. Do not use `'use server'` in React on Rails applications.

All mutations in React on Rails should go through Rails controllers via standard forms or API endpoints:

```jsx
// CommentForm.jsx -- Client Component
'use client';

import { useState } from 'react';

export default function CommentForm({ postId, csrfToken }) {
  const [content, setContent] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    const response = await fetch('/api/comments', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
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
<%# ERB view — pass the CSRF token so the client component can make authenticated requests %>
<%= stream_react_component("CommentForm",
      props: { postId: @post.id,
               csrfToken: form_authenticity_token }) %>
```

This preserves Rails' full controller/model layer -- authentication, authorization, CSRF protection, and validations all work as expected.

## When to Keep Client-Side Fetching

Not everything should move to the server. Keep client-side data fetching for:

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

### Progressive Streaming Architecture

Structure your page so critical content appears first (as sync props) and secondary content streams in (as async props):

```erb
<%# ERB view — sync props render immediately, async props stream in %>
<%= stream_react_component_with_async_props("Page",
      props: { title: @page.title }) do |emit|
  emit.call("main_content", @page.main_content.as_json)
  emit.call("recommendations", RecommendationService.for(@page).as_json)
  emit.call("comments", @page.comments.recent.as_json)
end %>
```

```jsx
export default function Page({ title, getReactOnRailsAsyncProp }) {
  const mainPromise = getReactOnRailsAsyncProp('main_content');
  const recsPromise = getReactOnRailsAsyncProp('recommendations');
  const commentsPromise = getReactOnRailsAsyncProp('comments');

  return (
    <div>
      {/* Static shell renders immediately from sync props */}
      <Header />
      <h1>{title}</h1>
      <nav>
        <SideNav />
      </nav>

      <main>
        {/* Async props stream in with Suspense fallbacks */}
        <Suspense fallback={<MainContentSkeleton />}>
          <MainContent contentPromise={mainPromise} />
        </Suspense>

        <Suspense fallback={<RecommendationsSkeleton />}>
          <Recommendations recsPromise={recsPromise} />
        </Suspense>

        <Suspense fallback={<CommentsSkeleton />}>
          <Comments commentsPromise={commentsPromise} />
        </Suspense>
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

## Migration Checklist

### Step 1: Identify Candidates

For each component that fetches data:

- Does it only display data? → Convert to Server Component (or use [async props](#data-fetching-in-react-on-rails-pro) in React on Rails)
- Does it need polling/optimistic updates? → Keep React Query/SWR, add server prefetch
- Does it need real-time updates? → Keep client-side, pass initial data from server

### Step 2: Convert Simple Fetches

1. Remove the `'use client'` directive
2. Remove `useState` for data, loading, and error
3. Remove the `useEffect` data fetch
4. Receive data as props from Rails (controller and/or ERB view helper props)
5. For streaming data, use `getReactOnRailsAsyncProp` with `stream_react_component_with_async_props` in the ERB view
6. Remove API routes that were only used for client-side fetching by this component

### Step 3: Add Suspense Boundaries

7. Wrap converted components in `<Suspense>` at the parent level
8. Create skeleton components that match content dimensions
9. Group related data sections in shared boundaries

### Step 4: Optimize

10. Use async props with `stream_react_component_with_async_props` for progressive streaming
11. Parallelize independent Ruby queries with threads to avoid server-side waterfalls
12. Pass async prop promises to Client Components with `use()` for non-critical data

## Next Steps

- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
