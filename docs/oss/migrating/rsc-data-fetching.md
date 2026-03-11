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

> **See also:** [`stream_react_component_with_async_props` API documentation](https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/tutorial/) for setup instructions and configuration options.

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

> **More details:** For setup instructions, configuration options, and the RSC payload variant (`rsc_payload_react_component_with_async_props`), see the [React on Rails Pro RSC documentation](https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/tutorial/).

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
// After: Server Component
import { getProducts } from '../lib/data';

async function ProductList() {
  const products = await getProducts();

  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

> **React on Rails Pro note:** If your data lives in Rails (ActiveRecord, etc.), use [async props](#data-fetching-in-react-on-rails-pro) instead of calling a data layer directly from the component. Async props stream Rails-fetched data to the component via Suspense, without bypassing Rails' authorization and caching layers.

### Pattern 2: Prefetch + Hydrate (Keep React Query for Client Features)

When you need React Query's client features (background refetching, mutations, optimistic updates), prefetch on the server and hydrate on the client:

```jsx
// ReactQueryProvider.jsx -- Client Component (provides QueryClient + hydration)
'use client';

import { QueryClient, QueryClientProvider, HydrationBoundary } from '@tanstack/react-query';
import { useState } from 'react';

export default function ReactQueryProvider({ children, dehydratedState }) {
  const [queryClient] = useState(() => new QueryClient());
  return (
    <QueryClientProvider client={queryClient}>
      <HydrationBoundary state={dehydratedState}>{children}</HydrationBoundary>
    </QueryClientProvider>
  );
}
```

```jsx
// ProductsPage.jsx -- Server Component
import { dehydrate, QueryClient } from '@tanstack/react-query';
import { getProducts } from '../lib/data';
import ReactQueryProvider from './ReactQueryProvider';
import ProductList from './ProductList';

export default async function ProductsPage() {
  const queryClient = new QueryClient();

  await queryClient.prefetchQuery({
    queryKey: ['products'],
    queryFn: getProducts,
  });

  return (
    <ReactQueryProvider dehydratedState={dehydrate(queryClient)}>
      <ProductList />
    </ReactQueryProvider>
  );
}
```

```jsx
// ProductList.jsx -- Client Component (uses React Query hooks)
'use client';

import { useQuery } from '@tanstack/react-query';

export default function ProductList() {
  const { data: products } = useQuery({
    queryKey: ['products'],
    queryFn: () => fetch('/api/products').then((res) => res.json()),
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

**How it works:**

1. Server Component creates a `QueryClient` and prefetches data
2. `dehydrate()` serializes the cache state
3. `ReactQueryProvider` wraps children with both `QueryClientProvider` (required for `useQuery`) and `HydrationBoundary` (seeds the cache)
4. Client-side `useQuery` picks up the prefetched data -- no loading state on first render
5. Subsequent refetches happen client-side as usual

## Migrating from SWR

SWR follows a similar pattern -- use the `fallback` prop to pass server-fetched data:

```jsx
// DashboardPage.jsx -- Server Component
import { getDashboardStats } from '../lib/data';
import DashboardStats from './DashboardStats';

export default async function DashboardPage() {
  const stats = await getDashboardStats();

  return <DashboardStats fallbackData={stats} />;
}
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

The most critical performance pitfall with Server Components is sequential data fetching. When one `await` blocks the next, you create a waterfall on the server:

### The Problem: Sequential Fetching

```jsx
// BAD: Each await blocks the next
async function Dashboard() {
  const user = await getUser(); // 200ms
  const stats = await getStats(user.id); // 300ms
  const posts = await getPosts(user.id); // 250ms (also waits for user)
  // Total: 750ms (sequential)

  return (
    <div>
      <UserProfile user={user} />
      <StatsPanel stats={stats} />
      <PostFeed posts={posts} />
    </div>
  );
}
```

### Solution 1: `Promise.all` for Independent Fetches

```jsx
// GOOD: Independent fetches run in parallel
async function Dashboard({ userId }) {
  const [user, stats, posts] = await Promise.all([
    getUser(userId), // 200ms
    getStats(userId), // 300ms ── all start simultaneously
    getPosts(userId), // 250ms
  ]);
  // Total: 300ms (limited by slowest)

  return (
    <div>
      <UserProfile user={user} />
      <StatsPanel stats={stats} />
      <PostFeed posts={posts} />
    </div>
  );
}
```

**Trade-off:** The page waits for the slowest fetch before rendering anything.

### Solution 2: Suspense Boundaries for Streaming

```jsx
// BEST: Each section renders independently as data arrives
async function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<UserSkeleton />}>
        <UserProfile /> {/* Fetches its own data */}
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel /> {/* Fetches its own data */}
      </Suspense>
      <Suspense fallback={<FeedSkeleton />}>
        <PostFeed /> {/* Fetches its own data */}
      </Suspense>
    </div>
  );
}
```

Each `<Suspense>` boundary lets React stream content progressively. The user sees each section as its data completes, rather than waiting for everything.

### Solution 3: Preload Pattern with `React.cache()`

Start a fetch early without awaiting, then consume the result in a child component:

```jsx
import { cache } from 'react';

const getComments = cache(async (postId) => {
  return await fetchComments(postId);
});

// Export a preload function for parent components
export const preloadComments = (id) => {
  void getComments(id); // Start fetch, don't await
};
```

```jsx
// Post.jsx -- Server Component
import { Suspense } from 'react';
import { preloadComments, getComments, getPost } from '../lib/data';

async function Post({ postId }) {
  preloadComments(postId); // Fire and forget

  const post = await getPost(postId); // This await doesn't block comments

  return (
    <>
      <PostContent post={post} />
      <Suspense fallback={<CommentsSkeleton />}>
        <Comments postId={postId} />
      </Suspense>
    </>
  );
}

async function Comments({ postId }) {
  const comments = await getComments(postId); // Uses preloaded/cached result
  return <CommentList comments={comments} />;
}
```

### Solution 4: Mixed Strategy (Await Critical, Stream Secondary)

```jsx
async function ProductPage({ productId }) {
  // Start secondary fetches immediately without awaiting
  const reviewsPromise = getReviews(productId);
  const relatedPromise = getRelatedProducts(productId);

  // Only await the critical data
  const product = await getProduct(productId);

  return (
    <div>
      <ProductDetail product={product} />
      <Suspense fallback={<ReviewsSkeleton />}>
        <ReviewsSection promise={reviewsPromise} />
      </Suspense>
      <Suspense fallback={<RelatedSkeleton />}>
        <RelatedSection promise={relatedPromise} />
      </Suspense>
    </div>
  );
}

// ReviewsSection.jsx -- Async Server Component
async function ReviewsSection({ promise }) {
  const reviews = await promise;
  return <ReviewList reviews={reviews} />;
}

async function RelatedSection({ promise }) {
  const related = await promise;
  return <RelatedProducts products={related} />;
}
```

## Streaming with the `use()` Hook

The `use()` hook lets Client Components resolve promises that were started on the server. This enables the "server-to-client promise handoff" pattern:

```jsx
// Page.jsx -- Server Component
import { Suspense } from 'react';
import { getPost, getComments } from '../lib/data';
import Comments from './Comments';

export default async function Page({ id }) {
  const post = await getPost(id); // Await critical data
  const commentsPromise = getComments(id); // Start but DON'T await

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.body}</p>
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

- The post renders immediately without waiting for comments
- The promise starts on the server (close to the data source), but resolves on the client
- `<Suspense>` shows the fallback until the promise resolves
- The Client Component receives the data without needing its own fetch logic

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
// CORRECT: Promise created in a Server Component, passed as a prop
// Page.jsx -- Server Component
import { Suspense } from 'react';

export default async function Page({ id }) {
  const commentsPromise = getComments(id); // Created once on the server
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
  const comments = use(commentsPromise); // Safe: stable reference from props
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

> **Rule:** Never create a raw promise for `use()` inside a Client Component. Either receive it from a Server Component as a prop, or use a Suspense-compatible library like TanStack Query or SWR.

## Request Deduplication with `React.cache()`

When multiple Server Components need the same data, `React.cache()` ensures the fetch happens only once per request:

```jsx
// lib/data.js -- Define at module level
import { cache } from 'react';

export const getUser = cache(async (id) => {
  return await fetchUserById(id);
});
```

```jsx
// Navbar.jsx -- Server Component
import { getUser } from '../lib/data';

async function Navbar({ userId }) {
  const user = await getUser(userId); // Fetches once
  return <nav>Welcome, {user.name}</nav>;
}
```

```jsx
// Sidebar.jsx -- Server Component
import { getUser } from '../lib/data';

async function Sidebar({ userId }) {
  const user = await getUser(userId); // Returns cached result, no duplicate fetch
  return <aside>Role: {user.role}</aside>;
}
```

**Key properties:**

- Cache is scoped to the **current request** -- no cross-request data leakage
- Uses `Object.is` for argument comparison (pass primitives, not objects)
- Must be defined at **module level**, not inside components
- Only works in Server Components

### Common `React.cache()` Mistakes

```jsx
// WRONG: Each file creates its own cache
// file-a.js
const getUser = cache(fetchUser);
// file-b.js
const getUser = cache(fetchUser); // Different cache instance!

// CORRECT: Export from a shared module
// lib/data.js
export const getUser = cache(fetchUser);
// Both files import from lib/data.js
```

```jsx
// WRONG: Creating cache inside a component
async function Profile({ userId }) {
  const getUser = cache(fetchUser); // New cache every render!
  const user = await getUser(userId);
}

// CORRECT: Define at module level
const getUser = cache(fetchUser);
async function Profile({ userId }) {
  const user = await getUser(userId);
}
```

```jsx
// WRONG: Passing objects as arguments
const result = cachedFn({ x: 1, y: 2 }); // Cache miss every time!

// CORRECT: Pass primitives
const result = cachedFn(1, 2);
```

## Server Actions for Mutations

Server Actions let you define server-side functions that can be called directly from forms and event handlers. In React on Rails, mutations are typically handled through Rails controllers, but Server Actions can be useful for lightweight operations:

```jsx
// actions.js
'use server';

export async function createComment(formData) {
  // Server Actions are public HTTP endpoints -- always authenticate and validate
  const session = await getSession();
  if (!session?.userId) throw new Error('Unauthorized');

  // Validate all input -- formData can contain arbitrary values from any client
  const content = String(formData.get('content') || '').trim();
  const postId = Number(formData.get('postId'));
  if (!content || content.length > 10000) throw new Error('Invalid content');
  if (!Number.isFinite(postId) || postId <= 0) throw new Error('Invalid postId');

  // In React on Rails, Server Actions run in Node.js and cannot access
  // Rails models directly. Call your Rails API endpoint instead:
  const response = await fetch('/api/comments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ content, postId, userId: session.userId }),
  });
  if (!response.ok) throw new Error('Failed to create comment');
}
```

```jsx
// CommentForm.jsx -- works without JavaScript (progressive enhancement)
import { createComment } from './actions';

export default function CommentForm({ postId }) {
  return (
    <form action={createComment}>
      <input type="hidden" name="postId" value={postId} />
      <textarea name="content" />
      <button type="submit">Post Comment</button>
    </form>
  );
}
```

**Security:** Server Actions are exposed as public POST endpoints that anyone can call -- they are not restricted to your own UI. Always verify authentication and authorization before performing mutations, and validate all input. See the [runtime validation example](#runtime-validation-for-server-actions) in the Troubleshooting guide.

**Note:** In React on Rails, most mutations flow through Rails controllers via standard forms or API endpoints. Server Actions are a React concept that can complement this when you need a direct server-side function call from the client.

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

### Hybrid Pattern: Server Fetch + Client Updates

For features that need server-fetched initial data with client-side updates:

```jsx
// ChatPage.jsx -- Server Component
import { getMessages } from '../lib/data';
import ChatWindow from './ChatWindow';

export default async function ChatPage({ channelId }) {
  const initialMessages = await getMessages(channelId);

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

Structure your page so critical content appears first and secondary content streams in:

```jsx
export default function Page() {
  return (
    <div>
      {/* Static shell renders immediately */}
      <Header />
      <nav>
        <SideNav />
      </nav>

      <main>
        {/* Critical content streams first */}
        <Suspense fallback={<MainContentSkeleton />}>
          <MainContent />
        </Suspense>

        {/* Secondary content streams as available */}
        <Suspense fallback={<RecommendationsSkeleton />}>
          <Recommendations />
        </Suspense>

        {/* Lowest priority streams last */}
        <Suspense fallback={<CommentsSkeleton />}>
          <Comments />
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
4. Make the component `async`
5. Add direct data fetching with `await`
6. Remove the API route if it was only used by this component

### Step 3: Add Suspense Boundaries

7. Wrap converted components in `<Suspense>` at the parent level
8. Create skeleton components that match content dimensions
9. Group related data sections in shared boundaries

### Step 4: Optimize

10. Use `React.cache()` to deduplicate shared data fetches
11. Use `Promise.all()` or the preload pattern to avoid waterfalls
12. Pass promises to Client Components with `use()` for non-critical data

## Next Steps

- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
