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

If a component only displays data without mutations, polling, or optimistic updates, replace React Query with a Server Component that receives data from Rails:

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
// After: Server Component receives data from Rails as props
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
<%# Rails view %>
<%= stream_react_component("ProductList",
      props: { products: Product.all.as_json(only: [:id, :name, :price]) }) %>
```

Rails fetches the data in the controller layer and passes it as props. The component simply renders — no loading states, error handling, or client-side caching needed. For slow data that shouldn't block the initial render, use [async props](#data-fetching-in-react-on-rails-pro) to stream it in progressively.

### Pattern 2: Keep React Query for Client Features (initialData from Rails)

When you need React Query's client features (background refetching, mutations, optimistic updates), pass Rails-fetched data as `initialData` so the first render has data immediately:

```erb
<%# Rails view %>
<%= stream_react_component("ProductsPage",
      props: { products: Product.all.as_json(only: [:id, :name, :price]) }) %>
```

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
    staleTime: 60_000, // treat Rails-fetched data as fresh for 60 s
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

1. Rails controller fetches data and passes it as props
2. The Server Component passes the data to a Client Component as `initialData`
3. React Query uses this data for the first render -- no loading state
4. Subsequent refetches happen client-side as usual via the `queryFn`

## Migrating from SWR

SWR follows a similar pattern -- pass Rails-fetched data as `fallbackData`:

```erb
<%# Rails view %>
<%= stream_react_component("DashboardPage",
      props: { stats: DashboardStats.compute.as_json }) %>
```

```jsx
// DashboardPage.jsx -- Server Component
import DashboardStats from './DashboardStats';

export default function DashboardPage({ stats }) {
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

With async props, the most common performance pitfall is sequential data emission on the Ruby side. When each `emit.call` blocks until the previous computation finishes, you create a waterfall:

### The Problem: Sequential emit.call

```erb
<%# BAD: Each computation blocks the next %>
<%= stream_react_component_with_async_props("Dashboard",
      props: { title: "Dashboard" }) do |emit|
  user = User.find(user_id)                          # 200ms
  emit.call("user", user.as_json)

  stats = Stats.for_user(user.id)                    # 300ms (waits for user)
  emit.call("stats", stats.as_json)

  posts = Post.where(user_id: user.id).limit(10)     # 250ms (waits for stats)
  emit.call("posts", posts.as_json)
  # Total: 750ms (sequential)
end %>
```

Even though each async prop streams to the browser independently via Suspense, the Ruby block executes sequentially — `stats` doesn't start computing until `user` finishes, and `posts` waits for both.

### Solution 1: Suspense Boundaries for Progressive Rendering

Even with sequential `emit.call`, each async prop fills its Suspense boundary as soon as it arrives. The user sees progressive loading rather than a blank page:

```jsx
// Dashboard.jsx -- Server Component
import { Suspense } from 'react';

export default function Dashboard({ title, getReactOnRailsAsyncProp }) {
  return (
    <div>
      <h1>{title}</h1>
      <Suspense fallback={<UserSkeleton />}>
        <UserProfile userPromise={getReactOnRailsAsyncProp('user')} />
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel statsPromise={getReactOnRailsAsyncProp('stats')} />
      </Suspense>
      <Suspense fallback={<FeedSkeleton />}>
        <PostFeed postsPromise={getReactOnRailsAsyncProp('posts')} />
      </Suspense>
    </div>
  );
}

// Async Server Component -- awaits the streamed prop
async function UserProfile({ userPromise }) {
  const user = await userPromise;
  return (
    <div>
      {user.name} — {user.role}
    </div>
  );
}
```

The title renders immediately. User data fills in after 200ms, stats after 500ms, posts after 750ms. Each section appears independently.

### Solution 2: Parallel Execution in Ruby

If the data sources are independent (none depends on another's result), run them in parallel using threads:

```erb
<%# GOOD: Independent computations run in parallel %>
<%= stream_react_component_with_async_props("Dashboard",
      props: { title: "Dashboard" }) do |emit|
  threads = []
  threads << Thread.new { ActiveRecord::Base.connection_pool.with_connection { emit.call("user", User.find(user_id).as_json) } }
  threads << Thread.new { ActiveRecord::Base.connection_pool.with_connection { emit.call("stats", Stats.for_user(user_id).as_json) } }
  threads << Thread.new { ActiveRecord::Base.connection_pool.with_connection { emit.call("posts", Post.where(user_id: user_id).limit(10).as_json) } }
  threads.each(&:join)
  # Total: ~300ms (limited by slowest query)
end %>
```

Each async prop streams to the browser as its thread completes. Combined with Suspense boundaries on the React side, the user sees each section fill in as soon as its data is ready.

> **Note:** Ensure your database connection pool is large enough to handle concurrent queries. With Active Record, each thread needs its own connection. See `pool` in `config/database.yml`.

### Solution 3: Mix Sync and Async Props

Send critical data as sync props (renders immediately) and stream secondary data as async props:

```erb
<%= stream_react_component_with_async_props("ProductPage",
      props: { name: product.name, price: product.price }) do |emit|
  # name and price render immediately as sync props
  # Reviews and recommendations stream in as they complete
  emit.call("reviews", product.reviews.includes(:author).as_json)
  emit.call("recommendations", RecommendationService.for(product).as_json)
end %>
```

```jsx
// ProductPage.jsx -- Server Component
import { Suspense } from 'react';

export default function ProductPage({ name, price, getReactOnRailsAsyncProp }) {
  return (
    <div>
      <h1>{name}</h1>
      <p>${price}</p>
      <Suspense fallback={<ReviewsSkeleton />}>
        <ReviewsSection reviewsPromise={getReactOnRailsAsyncProp('reviews')} />
      </Suspense>
      <Suspense fallback={<RelatedSkeleton />}>
        <Recommendations itemsPromise={getReactOnRailsAsyncProp('recommendations')} />
      </Suspense>
    </div>
  );
}

async function ReviewsSection({ reviewsPromise }) {
  const reviews = await reviewsPromise;
  return <ReviewList reviews={reviews} />;
}

async function Recommendations({ itemsPromise }) {
  const items = await itemsPromise;
  return <RelatedProducts products={items} />;
}
```

The product name and price appear instantly. Reviews and recommendations stream in as each `emit.call` completes on the Ruby side.

## Streaming with the `use()` Hook

The `use()` hook lets Client Components resolve promises that were started on the server. In React on Rails, this is useful when an async prop needs to be consumed by a Client Component (for example, data that requires client-side interactivity after loading):

```erb
<%# Rails view %>
<%= stream_react_component_with_async_props("Page",
      props: { title: post.title, body: post.body }) do |emit|
  emit.call("comments", post.comments.includes(:author).as_json)
end %>
```

```jsx
// Page.jsx -- Server Component
import { Suspense } from 'react';
import Comments from './Comments';

export default function Page({ title, body, getReactOnRailsAsyncProp }) {
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
// Comments.jsx -- Client Component (needs interactivity, e.g., reply buttons)
'use client';

import { use } from 'react';

export default function Comments({ commentsPromise }) {
  const comments = use(commentsPromise); // Resolves the async prop promise
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

- The title and body render immediately (sync props)
- The promise comes from `getReactOnRailsAsyncProp`, which returns a stable cached reference
- `<Suspense>` shows the fallback until the async prop resolves
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

`React.cache()` ensures a function is called only once per request when multiple Server Components need the same data. However, **in React on Rails Pro, `getReactOnRailsAsyncProp` already returns a cached promise** — the same object on repeated calls with the same key. This makes `React.cache()` largely unnecessary for async props.

`React.cache()` may still be useful if you have Server Components that call shared utility functions outside the async props system (for example, performing a computation that multiple components need):

```jsx
// lib/data.js -- Define at module level
import { cache } from 'react';

export const formatUserDisplay = cache((userId, users) => {
  // Expensive computation shared by multiple components
  return computeDisplayData(userId, users);
});
```

**Key properties:**

- Cache is scoped to the **current request** -- no cross-request data leakage
- Uses `Object.is` for argument comparison (pass primitives, not objects)
- Must be defined at **module level**, not inside components
- Only works in Server Components

> **Note:** `React.cache()` is only available in React Server Component environments. It is not available in Client Components or non-RSC server rendering (e.g., `renderToString`).

For most React on Rails applications, you won't need `React.cache()` because data flows through Rails props and async props, both of which handle caching at their respective layers.

## Server Actions Are Not Supported in React on Rails

React on Rails **does not support Server Actions** (`'use server'`). Server Actions run on the Node renderer, which is a rendering-only process with no access to:

- Rails models or ActiveRecord
- Rails sessions and cookies
- CSRF protection
- Rails middleware (authentication, authorization)

**Use Rails controllers for all mutations.** React on Rails applications should handle form submissions and data mutations through standard Rails controller actions — either via traditional form posts, API endpoints, or `fetch` calls from Client Components:

```jsx
// CommentForm.jsx -- Client Component
'use client';

import { useState } from 'react';

export default function CommentForm({ postId }) {
  const [content, setContent] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    await fetch('/api/comments', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({ comment: { content, post_id: postId } }),
    });
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

Or use a standard HTML form that posts directly to a Rails controller:

```erb
<%= form_with(model: @comment, url: post_comments_path(@post)) do |f| %>
  <%= f.text_area :content %>
  <%= f.submit "Post Comment" %>
<% end %>
```

Both approaches leverage Rails' full controller/model layer, including authentication, authorization, CSRF protection, and validations.

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

### Hybrid Pattern: Server Data + Client Updates

For features that need server-fetched initial data with client-side updates (e.g., chat, live feeds):

```erb
<%# Rails view %>
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

Structure your page so critical content appears first and secondary content streams in. With async props, each `emit.call` on the Ruby side fills a corresponding Suspense boundary:

```erb
<%= stream_react_component_with_async_props("Page",
      props: { title: "My Page" }) do |emit|
  emit.call("mainContent", MainContent.compute.as_json)
  emit.call("recommendations", RecommendationService.compute.as_json)
  emit.call("comments", Comment.recent.as_json)
end %>
```

```jsx
export default function Page({ title, getReactOnRailsAsyncProp }) {
  return (
    <div>
      {/* Static shell renders immediately from sync props */}
      <Header />
      <h1>{title}</h1>
      <nav>
        <SideNav />
      </nav>

      <main>
        {/* Each async prop streams in as Rails emits it */}
        <Suspense fallback={<MainContentSkeleton />}>
          <MainContent contentPromise={getReactOnRailsAsyncProp('mainContent')} />
        </Suspense>

        <Suspense fallback={<RecommendationsSkeleton />}>
          <Recommendations itemsPromise={getReactOnRailsAsyncProp('recommendations')} />
        </Suspense>

        <Suspense fallback={<CommentsSkeleton />}>
          <Comments commentsPromise={getReactOnRailsAsyncProp('comments')} />
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

- Does it only display data? → Convert to Server Component, receive data as Rails controller props
- Does it need streaming? → Use [async props](#data-fetching-in-react-on-rails-pro) with `stream_react_component_with_async_props`
- Does it need polling/optimistic updates? → Keep React Query/SWR, pass Rails data as `initialData`/`fallbackData`
- Does it need real-time updates? → Keep client-side, pass initial data from server

### Step 2: Convert Simple Fetches

1. Remove the `'use client'` directive
2. Remove `useState` for data, loading, and error
3. Remove the `useEffect` data fetch
4. Receive data as props from the Rails controller
5. Remove the API route if it was only used by this component

### Step 3: Add Suspense Boundaries for Async Props

6. Use `stream_react_component_with_async_props` in ERB for data that should stream
7. Use `getReactOnRailsAsyncProp` in the component for each streamed prop
8. Wrap async sections in `<Suspense>` with skeleton components
9. Group related data sections in shared boundaries to avoid "popcorn UI"

### Step 4: Optimize

10. Send fast data as sync props, slow data as async props
11. Use Ruby-side parallelism (threads) for independent async prop computations
12. Pass async prop promises to Client Components with `use()` when interactivity is needed

## Next Steps

- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
