# React 19 Native Metadata: Replacing react-helmet and react_component_hash

React 19 introduces built-in support for rendering `<title>`, `<meta>`, and `<link>` tags anywhere in your component tree. React automatically hoists them into the document `<head>`. This eliminates the need for `react-helmet` and, for metadata use cases, `react_component_hash`.

## Why Migrate?

|                       | react-helmet + react_component_hash                        | React 19 Native Metadata                                     |
| --------------------- | ---------------------------------------------------------- | ------------------------------------------------------------ |
| **SSR approach**      | `renderToString` only                                      | Works with `renderToString`¹, streaming, and RSC             |
| **Streaming support** | Not compatible                                             | Fully compatible                                             |
| **Dependencies**      | `react-helmet` package                                     | None (built into React 19)                                   |
| **Server setup**      | Render-function returning object + `Helmet.renderStatic()` | Standard component                                           |
| **View helper**       | `react_component_hash` (returns Hash)                      | `react_component` or `stream_react_component` (returns HTML) |
| **Bundle complexity** | Separate server/client render-functions                    | Same component for both                                      |

¹ With `renderToString`, metadata tags initially appear in `<body>` (since React on Rails renders component fragments, not full documents). They are hoisted to `<head>` only after client hydration. Streaming and RSC do not have this limitation.

## What React 19 Hoists to `<head>`

React 19 automatically hoists these elements from anywhere in the component tree into the document `<head>`:

| Element                     | Hoisted? | Notes                                                     |
| --------------------------- | -------- | --------------------------------------------------------- |
| `<title>`                   | Yes      | Last rendered `<title>` wins                              |
| `<meta>`                    | Yes      | All variants (`name`, `property`, `httpEquiv`, `charSet`) |
| `<link rel="stylesheet">`   | Yes      | Must include `precedence` prop for ordering               |
| `<link rel="preload">`      | Yes      |                                                           |
| `<link rel="icon">`         | Yes      | And other `rel` types                                     |
| `<script async src="...">`  | Yes      | Only `async` scripts with `src`                           |
| `<style>` with `precedence` | Yes      | Inline styles with `precedence` prop                      |
| `<script>` (inline)         | **No**   | Stays where rendered in the tree                          |
| `<script defer>`            | **No**   | Not hoisted                                               |

> **Key limitation:** Inline `<script>` tags (including those with `dangerouslySetInnerHTML`) are **not** hoisted to `<head>`. They render where placed in the component tree. This matters for use cases like Apollo Client state serialization — see [What react_component_hash Is Still Needed For](#what-react_component_hash-is-still-needed-for).

## Migration Guide

### Step 1: Remove react-helmet

Uninstall the package:

```bash
yarn remove react-helmet
# or: npm uninstall react-helmet
# or: pnpm remove react-helmet
```

### Step 2: Replace Helmet Tags with Native Tags

**Before (react-helmet):**

```jsx
import { Helmet } from 'react-helmet';

const MyPage = ({ title, description }) => (
  <div>
    <Helmet>
      <title>{title}</title>
      <meta name="description" content={description} />
      <link rel="canonical" href="https://example.com/page" />
    </Helmet>
    <h1>{title}</h1>
    <p>Page content...</p>
  </div>
);
```

**After (React 19 native):**

```jsx
const MyPage = ({ title, description }) => (
  <div>
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="canonical" href="https://example.com/page" />
    <h1>{title}</h1>
    <p>Page content...</p>
  </div>
);
```

The metadata tags can be placed anywhere in the component tree — React 19 hoists them to `<head>` automatically. There is no need for a wrapper component.

### Step 3: Replace the Render-Function and View Helper

This is the key architectural change. With react-helmet, you needed a **render-function** returning an object and `react_component_hash` in your view. With React 19 native metadata, you use a standard component and `react_component` or `stream_react_component`.

**Before — Server render-function (react-helmet):**

```jsx
// MyPageServerApp.server.jsx
import { renderToString } from 'react-dom/server';
import { Helmet } from 'react-helmet';
import MyPage from './MyPage';

export default (props, _railsContext) => {
  const componentHtml = renderToString(<MyPage {...props} />);
  const helmet = Helmet.renderStatic();

  return {
    renderedHtml: {
      componentHtml,
      title: helmet.title.toString(),
      meta: helmet.meta.toString(),
      link: helmet.link.toString(),
    },
  };
};
```

**Before — Client component (react-helmet):**

```jsx
// MyPageClientApp.jsx
import MyPage from './MyPage';

export default (props) => () => <MyPage {...props} />;
```

**Before — ERB view (react-helmet):**

```erb
<% page_data = react_component_hash("MyPageApp",
    props: { title: "My Page", description: "..." },
    trace: true) %>

<% content_for :title do %>
  <%= page_data['title'] %>
<% end %>
<% content_for :head do %>
  <%= page_data['meta'] %>
  <%= page_data['link'] %>
<% end %>

<%= page_data["componentHtml"] %>
```

**After — Single component (React 19 native):**

```jsx
// MyPageApp.jsx
const MyPageApp = ({ title, description }) => (
  <div>
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="canonical" href="https://example.com/page" />
    <h1>{title}</h1>
    <p>Page content...</p>
  </div>
);

export default MyPageApp;
```

**After — ERB view (React 19 native, without streaming):**

```erb
<%= react_component("MyPageApp",
    props: { title: "My Page", description: "..." },
    prerender: true) %>
```

**After — ERB view (React 19 native, with streaming):**

```erb
<%= stream_react_component("MyPageApp",
    props: { title: "My Page", description: "..." },
    prerender: true) %>
```

No `content_for`, no separate server/client files, no render-function. React 19 handles the metadata hoisting automatically during both `renderToString` and `renderToPipeableStream`.

### Step 4: Remove Unused `content_for` Blocks

If your layout has `content_for` blocks that were only used for react-helmet output, you can remove them:

```erb
<!-- Before: needed for react-helmet output -->
<head>
  <%= yield(:title) if content_for?(:title) %>
  <%= yield(:head) if content_for?(:head) %>
</head>

<!-- After: React 19 hoists metadata directly to <head> -->
<head>
  <!-- React 19 automatically inserts <title>, <meta>, <link> here -->
</head>
```

> **Note:** Keep `content_for` blocks if other (non-React) parts of your app still use them.

## Streaming with Native Metadata

One of the biggest advantages of React 19 native metadata over react-helmet is **streaming compatibility**. With `stream_react_component`, metadata tags are included in the initial HTML shell and hoisted to `<head>` before the browser sees the content.

### Async Components with Dynamic Metadata

Metadata can be rendered inside async components within Suspense boundaries. When the async component resolves, React streams the metadata to the client and updates `<head>`:

```jsx
const UserProfile = async ({ userId }) => {
  const user = await fetchUser(userId);

  return (
    <>
      <title>{`${user.name}'s Profile | My App`}</title>
      <meta name="description" content={`Profile page for ${user.name}`} />
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
    </>
  );
};

const ProfilePage = ({ userId }) => (
  <div>
    {/* Initial metadata shown while loading */}
    <title>Loading Profile... | My App</title>
    <meta property="og:site_name" content="My App" />

    <Suspense fallback={<ProfileSkeleton />}>
      {/* Updated metadata streamed when resolved */}
      <UserProfile userId={userId} />
    </Suspense>
  </div>
);
```

The initial `<title>` ("Loading Profile...") appears immediately. When `UserProfile` resolves, React replaces it with the user-specific title.

### React Server Components (RSC) with Native Metadata

Native metadata works in React Server Components too. Since RSC components run exclusively on the server, metadata tags are always server-rendered — ideal for SEO:

```jsx
// NativeMetadataRSCApp.jsx (no 'use client' directive — this is a Server Component)
import React, { Suspense } from 'react';

const AsyncContent = async ({ slug }) => {
  const article = await fetchArticle(slug);

  return (
    <>
      <title>{article.title}</title>
      <meta name="description" content={article.excerpt} />
      <meta property="og:title" content={article.title} />
      <meta property="og:image" content={article.coverImage} />
      <article>{article.body}</article>
    </>
  );
};

const ArticlePage = ({ slug }) => (
  <div>
    <title>Loading...</title>
    <link rel="canonical" href={`https://example.com/articles/${slug}`} />
    <Suspense fallback={<ArticleSkeleton />}>
      <AsyncContent slug={slug} />
    </Suspense>
  </div>
);

export default ArticlePage;
```

## Hybrid Approach: Rails-Side + React-Side Metadata

For pages where some metadata is known at the Rails level (and doesn't need React), you can combine Rails-side metadata with React 19 native metadata for dynamic content:

```erb
<%# Static metadata set in Rails — no React needed %>
<% content_for :title, "My App — Dashboard" %>
<% content_for :head do %>
  <meta property="og:site_name" content="My App" />
  <link rel="canonical" href="<%= dashboard_url %>" />
<% end %>

<%# Dynamic content rendered by React — component handles its own metadata %>
<%= stream_react_component("DashboardApp",
    props: { user: @user },
    prerender: true) %>
```

This approach is useful when the page title and Open Graph tags are static, but the component needs to render additional metadata based on its internal state.

## What react_component_hash Is Still Needed For

React 19 native metadata replaces react-helmet for `<title>`, `<meta>`, and `<link>` tags. However, `react_component_hash` is still needed for use cases where **the render-function returns non-metadata HTML** that must be placed outside the component's DOM node:

### Apollo Client State Serialization

Apollo Client's SSR pattern requires extracting the cache state **after** rendering the entire component tree, then serializing it as a `<script>` tag in the page. This cannot be done with native metadata because:

1. `client.extract()` requires all queries to resolve first (full tree convergence)
2. Inline `<script>` tags are **not hoisted** by React 19
3. The state must be available before hydration begins

```jsx
// This pattern still requires react_component_hash
export default async (props, _railsContext) => {
  const client = createApolloClient();

  const componentHtml = await getMarkupFromTree({
    tree: <App {...props} client={client} />,
    renderFunction: renderToString,
  });

  const apolloState = client.extract();
  const apolloStateTag = `<script>window.__APOLLO_STATE__ = ${JSON.stringify(apolloState).replace(/</g, '\\u003c')};</script>`;

  return {
    renderedHtml: {
      componentHtml,
      apolloStateTag,
    },
  };
};
```

> **Security:** If you serialize JSON into an inline `<script>` tag, escape `<`, `>`, and `&` characters at minimum. Consider using a library like [`serialize-javascript`](https://github.com/yahoo/serialize-javascript) for comprehensive escaping, so user data cannot break out of the script block with `</script>` or inject HTML entities.

### Code-Splitting with @loadable/component

If you use `@loadable/component` with `ChunkExtractor` to collect code-split chunk tags, this still requires `react_component_hash`:

```jsx
export default (props, _railsContext) => {
  const extractor = new ChunkExtractor({ statsFile });
  const componentHtml = renderToString(extractor.collectChunks(<App {...props} />));

  return {
    renderedHtml: {
      componentHtml,
      linkTags: extractor.getLinkTags(),
      scriptTags: extractor.getScriptTags(),
      styleTags: extractor.getStyleTags(),
    },
  };
};
```

> **Modern alternative:** For streaming SSR, consider replacing `@loadable/component` with `React.lazy` + `Suspense`. React 19 hoists `<script async src="...">` and `<link rel="stylesheet" precedence="...">` automatically, which covers the same use case as `ChunkExtractor` without needing a render-function.

## Migration Decision Matrix

Use this matrix to decide which approach to use:

| Use Case                                   | Before                                    | After                                                        |
| ------------------------------------------ | ----------------------------------------- | ------------------------------------------------------------ |
| Page title and meta tags                   | `react-helmet` + `react_component_hash`   | React 19 native `<title>`, `<meta>`                          |
| Canonical URLs                             | `react-helmet` + `react_component_hash`   | React 19 native `<link rel="canonical">`                     |
| Open Graph tags                            | `react-helmet` + `react_component_hash`   | React 19 native `<meta property="og:...">`                   |
| Stylesheets                                | `react-helmet` or `ChunkExtractor`        | React 19 native `<link rel="stylesheet" precedence="...">`   |
| Async script loading                       | `ChunkExtractor` or manual                | React 19 native `<script async src="...">`                   |
| Apollo Client state                        | `react_component_hash`                    | **Keep** `react_component_hash` (no migration path)          |
| Inline scripts (`dangerouslySetInnerHTML`) | `react_component_hash`                    | **Keep** `react_component_hash` (inline scripts not hoisted) |
| `@loadable/component` chunks               | `react_component_hash` + `ChunkExtractor` | Consider `React.lazy` + `Suspense` with streaming            |

## Prerequisites

- **React 19** — native metadata hoisting is a React 19 feature
- **React on Rails 15+** — for basic `react_component` usage
- **React on Rails Pro 4+** — for `stream_react_component` and RSC support

## References

- [React 19 `<title>` documentation](https://react.dev/reference/react-dom/components/title)
- [React 19 `<meta>` documentation](https://react.dev/reference/react-dom/components/meta)
- [React 19 `<link>` documentation](https://react.dev/reference/react-dom/components/link)
- [React 19 `<script>` documentation](https://react.dev/reference/react-dom/components/script)
- [Streaming Server Rendering](streaming-server-rendering.md) — how to set up streaming SSR
- [View Helpers API](../api-reference/view-helpers-api.md) — `react_component`, `react_component_hash`, `stream_react_component`
- [Render-Functions](../core-concepts/render-functions.md) — how render-functions work with `react_component_hash`
- [Using React Helmet](react-helmet.md) — legacy react-helmet documentation
