# RSC Migration: Data Fetching Patterns

This guide covers how to migrate your data fetching from client-side patterns (`useEffect` + `fetch`, React Query, SWR) to Server Component patterns. Server Components can fetch data directly using `async`/`await`, eliminating the need for loading states, error handling boilerplate, and client-side caching in many cases.

> **Part 3 of the [RSC Migration Series](migrating-to-rsc.md)**

## The Core Shift: From `useEffect` to `async` Components

In the traditional React model, components fetch data on the client after mounting. In the RSC model, components fetch data on the server before sending HTML to the browser.

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
      .then(res => res.json())
      .then(data => {
        setUser(data);
        setLoading(false);
      })
      .catch(err => {
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

export default async function UserProfile({ userId }) {
  const user = await fetch(`https://api.example.com/users/${userId}`)
    .then(res => res.json());

  return <div>{user.name}</div>;
}
```

**What changed:**

- No `useState` for data, loading, or error
- No `useEffect` lifecycle management
- No `'use client'` directive
- The component is `async` and uses `await` directly
- Data fetching happens on the server, close to the data source
- No loading spinner needed in the component itself (handled by `<Suspense>` at the parent level)

### Direct Database Access

Server Components can access your database directly -- no API route needed:

```jsx
// UserProfile.jsx -- Server Component
import { db } from '../lib/database';

export default async function UserProfile({ userId }) {
  const user = await db.users.findUnique({ where: { id: userId } });

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

This eliminates the entire API layer for read-only data display. The database client, query logic, and ORM dependencies never ship to the client bundle.

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
    queryFn: () => fetch('/api/products').then(res => res.json()),
  });

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error.message} />;

  return (
    <ul>
      {data.map(p => <li key={p.id}>{p.name}</li>)}
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
      {products.map(p => <li key={p.id}>{p.name}</li>)}
    </ul>
  );
}
```

### Pattern 2: Prefetch + Hydrate (Keep React Query for Client Features)

When you need React Query's client features (background refetching, mutations, optimistic updates), prefetch on the server and hydrate on the client:

```jsx
// app/products/page.jsx -- Server Component
import { dehydrate, HydrationBoundary, QueryClient } from '@tanstack/react-query';
import { getProducts } from '../lib/data';
import ProductList from './ProductList';

export default async function ProductsPage() {
  const queryClient = new QueryClient();

  await queryClient.prefetchQuery({
    queryKey: ['products'],
    queryFn: getProducts,
  });

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <ProductList />
    </HydrationBoundary>
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
    queryFn: () => fetch('/api/products').then(res => res.json()),
  });

  return (
    <ul>
      {products.map(p => <li key={p.id}>{p.name} - ${p.price}</li>)}
    </ul>
  );
}
```

**How it works:**

1. Server Component creates a `QueryClient` and prefetches data
2. `dehydrate()` serializes the cache state
3. `HydrationBoundary` passes the cache to the client
4. Client-side `useQuery` picks up the prefetched data -- no loading state on first render
5. Subsequent refetches happen client-side as usual

## Migrating from SWR

SWR follows a similar pattern -- use the `fallback` prop to pass server-fetched data:

```jsx
// app/dashboard/page.jsx -- Server Component
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

const fetcher = (url) => fetch(url).then(res => res.json());

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
  const user = await getUser();           // 200ms
  const stats = await getStats(user.id);  // 300ms
  const posts = await getPosts(user.id);  // 250ms
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
    getUser(userId),       // 200ms
    getStats(userId),      // 300ms ── all start simultaneously
    getPosts(userId),      // 250ms
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
        <UserProfile />     {/* Fetches its own data */}
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />      {/* Fetches its own data */}
      </Suspense>
      <Suspense fallback={<FeedSkeleton />}>
        <PostFeed />        {/* Fetches its own data */}
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
  return await db.comments.findMany({ where: { postId } });
});

// Export a preload function for parent components
export const preloadComments = (id) => {
  void getComments(id); // Start fetch, don't await
};
```

```jsx
// Post.jsx -- Server Component
import { preloadComments, getComments } from '../lib/data';

async function Post({ postId }) {
  preloadComments(postId); // Fire and forget

  const post = await getPost(postId);  // This await doesn't block comments

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
```

## Streaming with the `use()` Hook

The `use()` hook lets Client Components resolve promises that were started on the server. This enables the "server-to-client promise handoff" pattern:

```jsx
// Page.jsx -- Server Component
import { Suspense } from 'react';
import Comments from './Comments';

export default async function Page({ id }) {
  const post = await getPost(id);              // Await critical data
  const commentsPromise = getComments(id);     // Start but DON'T await

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
  const comments = use(commentsPromise);  // Resolves the promise
  return (
    <ul>
      {comments.map(c => <li key={c.id}>{c.text}</li>)}
    </ul>
  );
}
```

**Benefits:**

- The post renders immediately without waiting for comments
- The promise starts on the server (close to the data source), but resolves on the client
- `<Suspense>` shows the fallback until the promise resolves
- The Client Component receives the data without needing its own fetch logic

## Request Deduplication with `React.cache()`

When multiple Server Components need the same data, `React.cache()` ensures the fetch happens only once per request:

```jsx
// lib/data.js -- Define at module level
import { cache } from 'react';

export const getUser = cache(async (id) => {
  const res = await fetch(`https://api.example.com/users/${id}`);
  return res.json();
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
function Profile({ userId }) {
  const getUser = cache(fetchUser); // New cache every render!
  const user = await getUser(userId);
}

// CORRECT: Define at module level
const getUser = cache(fetchUser);
function Profile({ userId }) {
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

Server Actions replace API routes for data mutations. They work with forms and event handlers:

```jsx
// actions.js
'use server';

import { revalidatePath } from 'next/cache';

export async function createComment(formData) {
  const content = formData.get('content');
  const postId = formData.get('postId');

  await db.comments.create({ data: { content, postId } });
  revalidatePath(`/posts/${postId}`); // Triggers re-render with fresh data
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

**Important:** Server Actions are designed for mutations, not data fetching. For reading data, use Server Components with direct `async`/`await`.

## When to Keep Client-Side Fetching

Not everything should move to the server. Keep client-side data fetching for:

| Use Case | Why Client-Side | Recommended Tool |
|----------|----------------|-----------------|
| Real-time data (WebSocket, SSE) | Requires persistent connection | Native WebSocket + `useState` |
| Polling / auto-refresh | Periodic updates after initial load | React Query / SWR |
| Optimistic updates | Instant UI feedback before server confirms | React Query mutations |
| Infinite scrolling | User-driven pagination | React Query / SWR |
| User-triggered searches | Response to client interactions | `useState` + `fetch` or React Query |
| Offline-first features | Must work without server | Local state + sync |

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
      <ChatWindow
        channelId={channelId}
        initialMessages={initialMessages}
      />
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
      setMessages(prev => [...prev, JSON.parse(event.data)]);
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
      <nav><SideNav /></nav>

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
- Does it only display data? → Convert to Server Component
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
