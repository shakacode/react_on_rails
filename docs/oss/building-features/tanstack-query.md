# Using TanStack Query

[TanStack Query](https://tanstack.com/query) (formerly React Query) manages **server state in the browser**: caching, request deduplication, background refetching, retries, and cache invalidation. Rails is excellent at server-side data; TanStack Query gives the React side a disciplined way to consume that data without hand-rolling loading flags, retry logic, and ad-hoc caches.

It is the recommended client-side server-state layer for Rails-backed React apps. Rails keeps owning data, routes, auth, sessions, CSRF, validations, mailers, and jobs. TanStack Query does not replace any of that; it consumes the JSON Rails already knows how to produce.

## Support Model

- **Client-side TanStack Query works in open-source React on Rails** with no special integration. It is a standard React library; register a component that mounts `QueryClientProvider` and you are done.
- **First-paint data seeding** (rendering useful rows in the server HTML, then letting the client reuse them) needs nothing more than React on Rails passing the first screen's data as props. The client adopts it through `useQuery({ initialData })`. This works in OSS and Pro alike.
- **Full TanStack Router SSR** (server-rendering the route tree and hydrating it) **requires React on Rails Pro**. See [Using TanStack Router](./tanstack-router.md). TanStack Query composes with that boundary but does not depend on it.

This guide mirrors the official [React on Rails + TanStack starter](https://github.com/shakacode/react-on-rails-starter-tanstack) ([live demo](https://starter.reactonrails.com)). Every snippet below is drawn from that app.

## Install

```bash
pnpm add @tanstack/react-query
```

## Rails Stays the Source of Truth

A normal Rails controller returns explicit JSON, never raw Active Record:

```ruby
# app/controllers/api/projects_controller.rb
module Api
  class ProjectsController < BaseController
    def index
      result = ProjectsQuery.from_params(Current.user.projects, params).result

      render json: {
        projects: result[:records].map { |project| ProjectSerializer.one(project) },
        meta: result[:meta]
      }
    end
  end
end
```

Filtering, sorting, pagination, and authorization stay in Rails. The React side never reaches past this boundary.

## One CSRF-Aware Fetch Helper

Put the same-origin and CSRF handling in exactly one place so every query and mutation goes through it:

```ts
// app/javascript/lib/apiFetch.ts
import { getCsrfToken } from './getCsrfToken';

type ApiFetchOptions = RequestInit & { json?: unknown };

export async function apiFetch<T>(path: string, options: ApiFetchOptions = {}): Promise<T> {
  const headers = new Headers(options.headers);
  headers.set('Accept', 'application/json');
  if (options.json !== undefined) headers.set('Content-Type', 'application/json');

  const csrfToken = getCsrfToken(); // reads <meta name="csrf-token">
  if (csrfToken) headers.set('X-CSRF-Token', csrfToken);

  const response = await fetch(path, {
    ...options,
    headers,
    credentials: 'same-origin',
    body: options.json === undefined ? options.body : JSON.stringify(options.json),
  });

  // ...parse JSON, throw ApiError on !response.ok
  return body as T;
}
```

`getCsrfToken()` reads the token Rails already renders into the page via `csrf_meta_tags`. Because requests are same-origin with the CSRF header, Rails session auth keeps working.

## Shared QueryClient Defaults

Create the `QueryClient` from a single factory so SSR and client use identical defaults:

```ts
// app/javascript/lib/queryClient.ts
import { QueryClient } from '@tanstack/react-query';

export const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        retry: 1,
        refetchOnWindowFocus: false,
      },
    },
  });
```

Mount the provider once, and keep the client stable across renders with `useMemo` (or `useState`). Creating `new QueryClient()` inline on every render throws the cache away on each render. See [Mistake 5 in the RSC context & state guide](../migrating/rsc-context-and-state.md#mistake-5-creating-new-queryclient-on-every-render) for the failure mode.

```tsx
const queryClient = useMemo(() => createQueryClient(), []);

return (
  <QueryClientProvider client={queryClient}>
    {children}
    {showDevtools ? <ReactQueryDevtools initialIsOpen={false} /> : null}
  </QueryClientProvider>
);
```

## Reading Server State With Stable Query Keys

Every server-side input belongs in the query key, so the cache entry is unique per filter/sort/page and refetches when any of them change:

```tsx
const projectsQuery = useQuery({
  queryKey: ['projects', status, sort, dir, page],
  queryFn: () => {
    const params = new URLSearchParams({ sort, dir, page: String(page), per_page: '8' });
    if (status) params.set('status', status);
    return apiFetch<ProjectsResponse>(`${api.projectsPath}?${params}`);
  },
});
```

The same query key identifies the same data on the server and the client. That is what lets the server-rendered cache and the client cache line up.

## First Paint Without Spinners

The common failure mode is rendering useful HTML on the server, then immediately showing a spinner and refetching everything on the client. Avoid it by seeding the first screen's data from Rails.

**Rails renders the first page into props** (only on the route that shows the table, using the same query object as the JSON API so the seed equals a later refetch):

```ruby
# app/controllers/dashboard_controller.rb
def show
  @dashboard_props = {
    api: { projectsPath: api_projects_path },
    initialProjects: projects_table_initial_load? ? initial_projects : nil,
    # ...
  }
end

# Seed only on the initial full-page load of the table route. Seeding on other
# routes can let a pre-mount mutation leave a stale seed the table later adopts
# as fresh (staleTime: 30s). See starter PR #174.
def projects_table_initial_load?
  request.path == projects_path
end
```

```erb
<%# app/views/dashboard/show.html.erb %>
<%= react_component("DashboardApp", props: @dashboard_props, prerender: !Rails.env.test?) %>
```

**The client adopts the seed as `initialData`** only when its params match the active query key, so the rows render in the initial HTML with no spinner and TanStack Query owns freshness from there:

```tsx
const { initialProjects } = useDashboardProps();

const initialData =
  initialProjects &&
  initialProjects.params.status === status &&
  initialProjects.params.sort === sort &&
  initialProjects.params.dir === dir &&
  initialProjects.params.page === page
    ? initialProjects.response
    : undefined;

const projectsQuery = useQuery({
  queryKey: ['projects', status, sort, dir, page],
  queryFn: () => apiFetch<ProjectsResponse>(/* ... */),
  initialData, // first page seeded from Rails; any other filter/sort/page fetches normally
});
```

Because the seed is passed as `initialData` without `initialDataUpdatedAt`, TanStack Query timestamps it at `0`, so the table does one background refetch on mount to confirm freshness — the rows still paint immediately, with no spinner. To treat the seed as fresh for `staleTime` and skip that first refetch, also pass `initialDataUpdatedAt` set to the server's render time.

> **`initialData` vs `dehydrate`/`HydrationBoundary`.** TanStack Query also ships a server-prefetch pattern: build a `QueryClient`, `prefetchQuery`, `dehydrate` it into the HTML, and wrap the client tree in `HydrationBoundary`. See the [TanStack Query SSR guide](https://tanstack.com/query/latest/docs/framework/react/guides/ssr). The starter uses the simpler props-to-`initialData` seed because Rails already renders the first page; reach for `dehydrate`/`HydrationBoundary` when you need to seed many queries at once.

## Mutations and Cache Invalidation

Mutations write through the same `apiFetch` helper, then invalidate or directly update the affected cache entries so the table and metrics refresh once:

```tsx
const queryClient = useQueryClient();

const mutation = useMutation({
  mutationFn: (values: ProjectFormValues) =>
    apiFetch<ProjectResponse>(api.projectsPath, { method: 'POST', json: { project: values } }),
  onSuccess: ({ project }) => {
    queryClient.setQueryData(['project', String(project.id)], { project });
    queryClient.invalidateQueries({ queryKey: ['projects'] });
    queryClient.invalidateQueries({ queryKey: ['metrics'] });
  },
});
```

This is cleaner than threading "reload this section" callbacks through many components: the cache is the single place that knows what is stale.

## TanStack Query and React Server Components

With React on Rails Pro's [React Server Components](../../pro/react-server-components/index.md), the two split the work:

- **RSC** fetches data for server-rendered, non-interactive pieces. A server component can query a Rails model directly and stream HTML, with no `/api` round-trip and no serializer for that piece.
- **TanStack Query** owns the interactive "live app" islands: refetching, mutations, optimistic updates, pagination, infinite scroll, background refresh, and cache invalidation.

If you are migrating an existing React Query setup into an RSC app, see [Migrating from React Query / TanStack Query](../migrating/rsc-data-fetching.md#migrating-from-react-query--tanstack-query).

## Why This Fits Rails Apps

- **Less frontend state boilerplate.** Server state ("current user," "projects," "messages," search results) belongs in the query cache, not in Redux or a hand-rolled global store.
- **Better perceived performance.** The page ships with useful data already present, then stays fresh on the client. You keep the SEO and first-load benefits of server rendering.
- **Gradual modernization.** Adopt it one React island or one page at a time. No single-page-app rewrite, no framework swap.

## Working Example

The [React on Rails + TanStack starter](https://github.com/shakacode/react-on-rails-starter-tanstack) (Rails 8 + React 19 + React on Rails Pro) implements every pattern above. The relevant files, each marked with a `REFERENCE PATTERN` comment:

- Shared fetch + client: `app/javascript/lib/apiFetch.ts`, `app/javascript/lib/getCsrfToken.ts`, `app/javascript/lib/queryClient.ts`
- Queries, mutations, provider: `app/javascript/src/Dashboard/ror_components/DashboardApp.tsx`
- Rails JSON API: `app/controllers/api/projects_controller.rb`
- SSR seed: `app/controllers/dashboard_controller.rb`, `app/views/dashboard/show.html.erb`

Try it live at [starter.reactonrails.com](https://starter.reactonrails.com).

## References

- [Using TanStack Router](./tanstack-router.md) (the Pro SSR boundary this pairs with)
- [Migrating from React Query / TanStack Query](../migrating/rsc-data-fetching.md#migrating-from-react-query--tanstack-query)
- [RSC Context & State](../migrating/rsc-context-and-state.md)
- [TanStack Query docs](https://tanstack.com/query/latest)
- [TanStack Query SSR guide](https://tanstack.com/query/latest/docs/framework/react/guides/ssr)
