# React on Rails Render-Functions: Usage Guide

This guide explains how render-functions work in React on Rails and how to use them with Ruby helper methods.

## Types of Render-Functions and Their Return Values

Render-functions take two parameters:

1. `props`: The props passed from the Ruby helper methods (via the `props:` parameter), which become available in your JavaScript.
2. `railsContext`: Rails contextual information like current pathname, locale, etc. See the [Render-Functions and the Rails Context](../core-concepts/render-functions-and-railscontext.md) documentation for more details.

### Identifying Render-Functions

React on Rails needs to identify which functions are render-functions (as opposed to regular React components). There are two ways to mark a function as a render function:

1. Accept two parameters in your function definition: `(props, railsContext)` - React on Rails will detect this signature (the parameter names don't matter).
2. Add a `renderFunction = true` property to your function - This is useful when your function doesn't need the railsContext.

```jsx
// Method 1: Use signature with two parameters
const MyComponent = (props, railsContext) => {
  return () => (
    <div>
      Hello {props.name} from {railsContext.pathname}
    </div>
  );
};

// Method 2: Use renderFunction property
const MyOtherComponent = (props) => {
  return () => <div>Hello {props.name}</div>;
};
MyOtherComponent.renderFunction = true;

ReactOnRails.register({ MyComponent, MyOtherComponent });
```

Render-functions can return several types of values:

### 1. React Components

```jsx
const MyComponent = (props, _railsContext) => {
  // The `props` parameter here is identical to the `props` passed from the Ruby helper methods (via the `props:` parameter).
  // Both `props` and `reactProps` refer to the same object.
  return (reactProps) => <div>Hello {props.name}</div>;
};
```

> [!NOTE]
> Ensure to return a React component (a function or class) and not a React element (the result of calling `React.createElement` or JSX).

### 2. Objects with `renderedHtml` string property

```jsx
const MyComponent = (props, _railsContext) => {
  return {
    renderedHtml: `<div>Hello ${props.name}</div>`,
  };
};
```

### 3. Objects with `renderedHtml` as a React element

> **React 19 Alternative:** For metadata use cases (titles, meta tags), consider using [React 19 Native Metadata](../building-features/react-19-native-metadata.md) instead of this pattern. React 19 hoists `<title>`, `<meta>`, and `<link>` to `<head>` automatically, eliminating the need for server-side hash render-functions.

```jsx
const MyComponent = (props, _railsContext) => {
  return {
    renderedHtml: <div>Hello {props.name}</div>,
  };
};
```

### 4. Objects with `renderedHtml` as a server-side hash (`componentHtml` + optional keys)

```jsx
const MyComponent = (props, _railsContext) => {
  const componentHtml = renderToString(<div>Hello {props.name}</div>);

  return {
    renderedHtml: {
      componentHtml,
      title: `<title>${props.title}</title>`,
      metaTags: `<meta name="description" content="${props.description}" />`,
    },
  };
};
```

### 5. Promises of Strings

This and other promise options below are only available in React on Rails Pro with the Node renderer.

```jsx
const MyComponent = async (props, _railsContext) => {
  const data = await fetchData();
  return `<div>Hello ${data.name}</div>`;
};
```

### 6. Promises of server-side hash

```jsx
const MyComponent = async (props, _railsContext) => {
  const data = await fetchData();
  return {
    componentHtml: `<div>Hello ${data.name}</div>`,
    title: `<title>${data.title}</title>`,
    metaTags: `<meta name="description" content="${data.description}" />`,
  };
};
```

### 7. Promises of React Components

```jsx
const MyComponent = async (props, _railsContext) => {
  const data = await fetchData();
  return () => <div>Hello {data.name}</div>;
};
```

### 8. Redirect Information (Legacy)

> [!NOTE]
> **`redirectLocation` and `routeError` have significant limitations.** These fields originated from React Router v3/v4 integrations but are still supported at the runtime level. Be aware of:
>
> - `redirectLocation` does **not** trigger an actual server-side redirect — Rails still returns the same response with an empty `<div>`. The redirect only takes effect once the client-side router renders.
> - `routeError` only triggers `raise_on_prerender_error` behavior (if enabled) — it does not produce a user-facing error page.
> - Modern React Router v6 Declarative Mode (`StaticRouter`) has no mechanism to produce these values.
> - React Router v6 Data Mode (`createStaticHandler`) handles redirects via `Response` objects, not these fields.
>
> **Modern alternatives:**
>
> - For redirects during SSR, handle them in your Rails controller (e.g., check auth before rendering).
> - For client-side redirects, use `<Navigate to="/path" />` (note: this is a [no-op during SSR](../building-features/react-router.md#navigate-component-ssr-behavior)).
> - For route errors, use React Router's `errorElement` or an `ErrorBoundary`.

```jsx
// Legacy pattern — prefer modern alternatives above
const MyComponent = (props, _railsContext) => {
  return {
    redirectLocation: { pathname: '/new-path', search: '' },
    routeError: null,
  };
};
```

## Important Rendering Behavior

Take a look at [serverRenderReactComponent.test.ts](https://github.com/shakacode/react_on_rails/blob/main/packages/react-on-rails/tests/serverRenderReactComponent.test.ts):

1. **Direct String Returns Don't Work** - Returning a raw HTML string directly from a render function causes an error. Always wrap HTML strings in `{ renderedHtml: '...' }`.

2. **Objects Require Specific Properties** - Non-promise objects must include a `renderedHtml` property to be valid when used with `react_component`.

3. **Async Functions Require the Pro Node Renderer** - Async render-functions (returning Promises) only work with the React on Rails Pro Node renderer. With ExecJS, an async render function silently returns `'{}'` with only a `console.error` — the empty result can be confusing to debug.

4. **`clientProps` are merged back into hydration props** - If a server render result includes `clientProps`, React on Rails merges those keys into the client hydration props generated by `react_component`.
   - Use this to pass server-only computed hydration data (for example router dehydrated state).
   - Merge order is `original_props.merge(clientProps)`, so keys from `clientProps` override matching original keys.
   - This merge requires your original `props:` to be a Ruby `Hash` or a JSON string representing an object.
   - The merge handles symbol vs. string key coexistence: if `clientProps` contains a string key `"foo"` and the original props contain a symbol key `:foo`, the merge updates the existing symbol key rather than creating a duplicate. An error is raised if both string and symbol versions of the same key exist in the original props.

5. **Server render result detection is broad** - React on Rails treats any object containing a `renderedHtml`, `redirectLocation`, `routeError`, or `error` key as a server render result (not a React component). This means returning an object with an `error` key from a render function triggers server-render-hash processing rather than being treated as a React component. Note that `error` is only used for detection — it is not itself treated as an exception descriptor. Only `routeError` sets the error flag during processing. This may be surprising if you intended `error` as a regular data field.

6. **Don't return JSX directly from render functions** - Render functions should return a React component (function or class), not a React element (JSX). Returning JSX directly causes React Hooks to break silently. A deprecation warning is logged but the code currently still works for backward compatibility.

## Ruby Helper Functions

### 1. react_component

The `react_component` helper renders a single React component in your view.

```ruby
<%= react_component("MyComponent", props: { name: "John" }) %>
```

This helper accepts render-functions that return React components, objects with a `renderedHtml` property, or promises that resolve to React components, strings, or server-side hash objects.

If your render-function returns `clientProps`, this helper also injects those values into the generated client hydration payload.

#### When to use

- When you need to render a single component
- When you're rendering client-side only
- When your render function returns a single HTML string

#### Not suitable for

- When your render function returns an object with multiple HTML strings
- When you need to insert content in different parts of the page, such as meta tags & style tags

### 2. react_component_hash

The `react_component_hash` helper is used when your render function returns an object with multiple HTML strings. It allows you to place different parts of the rendered output in different parts of your layout.

> [!IMPORTANT]
> `react_component_hash` **always forces `prerender: true`**, even if you explicitly pass `prerender: false`. This is because the helper only makes sense for server rendering — it needs the server to produce the hash of HTML strings. Passing `prerender: false` will be silently overwritten.

```ruby
# With a render function that returns an object with multiple HTML properties
<% helmet_data = react_component_hash("HelmetComponent", props: {
  title: "My Page",
  description: "Page description"
}) %>

<% content_for :head do %>
  <%= helmet_data["title"] %>
  <%= helmet_data["metaTags"] %>
<% end %>

<div class="main-content">
  <%= helmet_data["componentHtml"] %>
</div>
```

This helper accepts render-functions that return objects with a `renderedHtml` property containing `componentHtml` and any other necessary properties. It also supports promises that resolve to a server-side hash.

#### When to use

- When your render function returns multiple HTML strings in an object
- When you need to insert rendered content in different parts of your page
- For SEO-related rendering like meta tags and title tags
- When working with libraries like React Helmet

#### Not suitable for

- Simple component rendering
- Client-side only rendering (always forces server rendering)
- Renderer functions (3-parameter functions) — these are client-only

#### Requirements

- The render function MUST return an object with a `renderedHtml` property
- The `renderedHtml` object MUST include a `componentHtml` key
- All other keys in the `renderedHtml` object are optional and can be accessed in your Rails view
- Cannot be used with renderer functions (3-parameter functions that call `ReactDOM.render` directly)

## Compatibility Matrix

This table shows which component/return types are valid with each Ruby helper:

| Return Type                                                  | `react_component`      | `react_component_hash`                                            | `stream_react_component` (Pro)                        |
| ------------------------------------------------------------ | ---------------------- | ----------------------------------------------------------------- | ----------------------------------------------------- |
| React component (function/class)                             | ✅                     | ❌                                                                | ✅                                                    |
| Render function → React component                            | ✅                     | ❌                                                                | ✅                                                    |
| Render function → `{ renderedHtml: string }`                 | ✅                     | ❌                                                                | ❌                                                    |
| Render function → `{ renderedHtml: ReactElement }`           | ✅ (prerender only)    | ❌                                                                | ❌                                                    |
| Render function → `{ renderedHtml: { componentHtml, ... } }` | ❌                     | ✅                                                                | ❌                                                    |
| Render function → Promise (compatible return shape)          | ✅ (Pro Node renderer) | ✅ (Pro Node renderer, must resolve to hash with `componentHtml`) | ✅ (Pro Node renderer, must resolve to React element) |
| Renderer function (3 params)                                 | ✅ (client-only)       | ❌                                                                | ❌                                                    |

> **Note:** ❌ marks an unsupported combination. Some mismatches raise a `ReactOnRails::Error` directly in Ruby (e.g., `react_component` with a hash result raises `"Use react_component_hash (not react_component)..."`, and `react_component_hash` with a non-hash result raises `"Render-Function... expected to return an Object"`). Others (renderer functions used in server rendering, Pro Node renderer mismatches) throw a JavaScript error that becomes `ReactOnRails::PrerenderError` when `raise_on_prerender_error` is enabled, or is embedded as an error comment in the HTML when it is not. Either way, these combinations are not silent data failures — they will surface as errors or visible error output.

**Key constraints:**

- **`react_component_hash`** always forces `prerender: true` — it cannot be used for client-only rendering.
- **`stream_react_component`** (Pro) always forces `prerender: true`. The `immediate_hydration` option is no longer supported and will be ignored with a warning if passed.
- **Renderer functions** (3 parameters) are client-only — they call `ReactDOM.render`/`hydrate` directly, so server rendering with them throws an error.
- **Async render functions** (returning Promises) require the Pro Node renderer. With ExecJS, they silently return `'{}'`.

## Examples with Appropriate Helper Methods

### Return Type 1: React Component

```jsx
const SimpleComponent = (props, _railsContext) => () => <div>Hello {props.name}</div>;
ReactOnRails.register({ SimpleComponent });
```

```erb
<%# Ruby %>
<%= react_component("SimpleComponent", props: { name: "John" }) %>
```

### Return Type 2: Object with renderedHtml

```jsx
const RenderedHtmlComponent = (props, _railsContext) => {
  return { renderedHtml: `<div>Hello ${props.name}</div>` };
};
ReactOnRails.register({ RenderedHtmlComponent });
```

```erb
<%# Ruby %>
<%= react_component("RenderedHtmlComponent", props: { name: "John" }) %>
```

### Return Type 3: Object with `renderedHtml` React element

```jsx
const ElementHtmlComponent = (props, _railsContext) => {
  return {
    renderedHtml: <div>Hello {props.name}</div>,
  };
};
ElementHtmlComponent.renderFunction = true;
ReactOnRails.register({ ElementHtmlComponent });
```

```erb
<%# Ruby %>
<%= react_component("ElementHtmlComponent", props: { name: "John" }, prerender: true) %>
```

### Return Type 4: Object with server-side hash

```jsx
const HelmetComponent = (props) => {
  const componentHtml = renderToString(<div>Hello {props.name}</div>);

  return {
    renderedHtml: {
      componentHtml,
      title: `<title>${props.title}</title>`,
      metaTags: `<meta name="description" content="${props.description}" />`,
    },
  };
};
// The render function should either:
// 1. Accept two arguments: (props, railsContext)
// 2. Have a property `renderFunction` set to true
HelmetComponent.renderFunction = true;
ReactOnRails.register({ HelmetComponent });
```

```erb
<%# Ruby - MUST use react_component_hash %>
<% helmet_data = react_component_hash("HelmetComponent",
                                      props: { name: "John", title: "My Page", description: "Page description" }) %>

<% content_for :head do %>
  <%= helmet_data["title"] %>
  <%= helmet_data["metaTags"] %>
<% end %>

<div class="content">
  <%= helmet_data["componentHtml"] %>
</div>
```

### Return Type 5: Promise of String

```jsx
const AsyncStringComponent = async (props) => {
  const data = await fetchData();
  return `<div>Hello ${data.name}</div>`;
};
AsyncStringComponent.renderFunction = true;
ReactOnRails.register({ AsyncStringComponent });
```

```erb
<%# Ruby %>
<%= react_component("AsyncStringComponent", props: { dataUrl: "/api/data" }) %>
```

### Return Type 6: Promise of server-side hash

```jsx
const AsyncObjectComponent = async (props) => {
  const data = await fetchData();
  return {
    componentHtml: `<div>Hello ${data.name}</div>`,
    title: `<title>${data.title}</title>`,
    metaTags: `<meta name="description" content="${data.description}" />`,
  };
};
AsyncObjectComponent.renderFunction = true;
ReactOnRails.register({ AsyncObjectComponent });
```

```erb
<%# Ruby - MUST use react_component_hash %>
<% helmet_data = react_component_hash("AsyncObjectComponent", props: { dataUrl: "/api/data" }) %>

<% content_for :head do %>
  <%= helmet_data["title"] %>
  <%= helmet_data["metaTags"] %>
<% end %>

<div class="content">
  <%= helmet_data["componentHtml"] %>
</div>
```

### Return Type 7: Promise of React Component

```jsx
const AsyncReactComponent = async (props) => {
  const data = await fetchData();
  return () => <div>Hello {data.name}</div>;
};
AsyncReactComponent.renderFunction = true;
ReactOnRails.register({ AsyncReactComponent });
```

```erb
<%# Ruby %>
<%= react_component("AsyncReactComponent", props: { dataUrl: "/api/data" }) %>
```

### Return Type 8: Redirect Object (Legacy)

> [!WARNING]
> This is a legacy pattern from React Router v3/v4. See [8. Redirect Information (Legacy)](#8-redirect-information-legacy) for modern alternatives. The `redirectLocation` does not trigger an actual server-side redirect — Rails returns an empty `<div>` and the redirect only fires on the client.

```jsx
// Legacy pattern — prefer handling redirects in your Rails controller
const RedirectComponent = (props, railsContext) => {
  if (!railsContext.currentUser) {
    return {
      redirectLocation: { pathname: '/login', search: '' },
    };
  }
  return {
    renderedHtml: <div>Welcome {railsContext.currentUser.name}</div>,
  };
};
RedirectComponent.renderFunction = true;
ReactOnRails.register({ RedirectComponent });
```

```erb
<%# Ruby %>
<%= react_component("RedirectComponent") %>
```

### Return Type 9: Server-rendered `clientProps` for hydration

```jsx
const RouterShell = (props, railsContext) => {
  const componentHtml = renderToString(<App initialUrl={railsContext.location} />);
  return {
    renderedHtml: componentHtml,
    clientProps: {
      routerDehydratedState: { url: railsContext.location },
    },
  };
};
RouterShell.renderFunction = true;
ReactOnRails.register({ RouterShell });
```

```erb
<%# Ruby: pass a Hash or a JSON object string so clientProps can merge correctly %>
<%= react_component("RouterShell", props: { locale: I18n.locale }, prerender: true) %>
```

By understanding these return types and which helper to use with each, you can create sophisticated server-rendered React components that fully integrate with your Rails views.
