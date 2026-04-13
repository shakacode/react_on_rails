# React on Rails Render-Functions: Usage Guide

This guide explains how render-functions work in React on Rails and how to use them with Ruby helper methods.

## Component types supported by React on Rails

Before diving into render-functions, it helps to know the three kinds of values you can register with `ReactOnRails.register`. React on Rails classifies each registered entry based on its shape, and the classification determines where it can run (server, client, or both) and which Ruby helpers can invoke it.

| Type | Signature | Server (SSR) | Client | Detection rule |
| --- | --- | --- | --- | --- |
| **React Component** | `(props) => JSX` or class component | Yes | Yes | `Function.length <= 1` and no `renderFunction` flag |
| **Render Function** | `(props, railsContext) => ...` | Yes | Yes | `Function.length >= 2` **or** `fn.renderFunction === true` |
| **Renderer Function** | `(props, railsContext, domNodeId) => void` | **No — throws** | Yes | `Function.length === 3` (render function with 3 params) |

A few important points about the detection:

- **The detection is based on `Function.length`** (the number of declared parameters). Destructured parameters count as 1 — `({ name }) => ...` has length 1.
- **Render functions return** a React component, a React element, a server-render hash object, or a promise that resolves to one of those. See [Types of Render-Functions and Their Return Values](#types-of-render-functions-and-their-return-values) below.
- **Renderer functions do not return anything meaningful.** They take control of mounting/hydration themselves by calling `ReactDOM.hydrateRoot` / `createRoot` against `domNodeId`. Because there is no DOM on the server, **registering a renderer function and then server-rendering it throws a descriptive error**. Renderer functions are strictly client-side.
- **`fn.renderFunction = true` is an escape hatch** for render functions that don't need `railsContext` but still want to be treated as render functions (e.g., so they can return a hash). Without the flag, a one-parameter function is classified as a regular React component.

```jsx
// Regular React Component — 0 or 1 params, renders normally
const HelloMessage = (props) => <div>Hello {props.name}</div>;

// Render Function — 2 params, returns a React component or a hash
const HelloWithContext = (props, railsContext) => {
  return () => (
    <div>
      Hello {props.name} from {railsContext.pathname}
    </div>
  );
};

// Render Function via the renderFunction flag — 1 param but still a render function
const HelloHash = (props) => {
  return { renderedHtml: { componentHtml: `<div>Hello ${props.name}</div>` } };
};
HelloHash.renderFunction = true;

// Renderer Function — 3 params, handles hydration itself, CLIENT ONLY
const LazyHydrate = (props, railsContext, domNodeId) => {
  // whenVisible is a hypothetical helper that resolves when the element scrolls into view
  whenVisible(domNodeId).then(() => {
    const root = document.getElementById(domNodeId);
    ReactDOM.hydrateRoot(root, <HelloMessage {...props} />);
  });
};

ReactOnRails.register({ HelloMessage, HelloWithContext, HelloHash, LazyHydrate });
```

The rest of this document focuses on **render functions** — the most flexible of the three types, with the richest set of return values. For renderer functions (client-side mounting control), see [Renderer Functions](../api-reference/view-helpers-api.md#renderer-functions-function-that-will-call-reactdomrender-or-reactdomhydrate) in the view helpers reference.

### Compatibility matrix: component types and Ruby helpers

The Ruby helper you use in your Rails view must be compatible with the component type you registered. Mismatches usually produce a clear server-side error, but it's faster to pick the right combination upfront:

| Component type | `react_component` | `react_component_hash` | `stream_react_component` (Pro) |
| --- | --- | --- | --- |
| **React Component** (plain function / class) | ✅ Works (client-side rendering or SSR) | ❌ Raises — the helper requires a hash return, not a component | ✅ Works (streaming SSR) |
| **Render Function returning a React component** | ✅ Works | ❌ Raises — must return a hash, not a component | ✅ Works |
| **Render Function returning `{ renderedHtml: string }`** | ✅ Works | ❌ Raises — string is not a hash with `componentHtml` | ❌ Raises — streaming does not support server render hashes |
| **Render Function returning `{ renderedHtml: ReactElement }`** | ✅ Works (calls `renderToString` on the element) | ❌ Raises — element is not a hash with `componentHtml` | ❌ Raises — streaming does not support server render hashes |
| **Render Function returning a server-render hash** (`{ renderedHtml: { componentHtml, ... } }`) | ⚠️ Raises — tells you to use `react_component_hash` | ✅ Works (the designed use case) | ❌ Raises — streaming does not support server render hashes |
| **Async Render Function** (returns a Promise) | ✅ Works with Pro Node renderer. ❌ ExecJS silently returns empty output — see [Async functions and ExecJS](#async-functions-and-execjs). | ✅ Same — Pro Node renderer only | ✅ Only if the promise resolves to a React component. Promises resolving to strings or server-render hashes are rejected — streaming does not support server render hashes. |
| **Renderer Function** (3 params) | ✅ Works with `prerender: false` (client-only). ❌ Throws with `prerender: true` — renderer functions cannot run on the server. | ❌ Raises — `react_component_hash` forces `prerender: true`, which is incompatible with renderer functions | ❌ Raises — streaming requires server rendering |

**Key takeaways:**

- `react_component_hash` is specifically for the "multiple HTML strings in one response" use case. If your render function returns a plain component, string, or React element, use `react_component` instead.
- Renderer functions are a client-only optimization. Any helper that prerenders (`prerender: true`, `react_component_hash`, or `stream_react_component`) will throw when used with a renderer function.
- Async render functions require the Pro Node renderer. On ExecJS, they fail silently — see the warning in the [Promises of Strings](#5-promises-of-strings) section.

## Types of Render-Functions and Their Return Values

Render-functions take two parameters:

1. `props`: The props passed from the Ruby helper methods (via the `props:` parameter), which become available in your JavaScript.
2. `railsContext`: Rails contextual information like current pathname, locale, etc. See the [Render-Functions and the Rails Context](../core-concepts/render-functions-and-railscontext.md) documentation for more details.

### Identifying Render-Functions

As shown in the [component types table](#component-types-supported-by-react-on-rails) above, React on Rails marks a function as a render function in two ways:

1. Accept two parameters in your function definition: `(props, railsContext)` — React on Rails will detect this signature (the parameter names don't matter).
2. Add a `renderFunction = true` property to your function — useful when your function doesn't need `railsContext`.

Render-functions can return several types of values:

### 1. React Components

```jsx
const MyComponent = (props, _railsContext) => {
  // The `props` parameter here is identical to the `props` passed from the Ruby helper methods (via the `props:` parameter).
  // Both `props` and `reactProps` refer to the same object.
  return (reactProps) => <div>Hello {props.name}</div>;
};
```

> [!IMPORTANT]
> **Return a React component (a function or class), not a React element.** That means `return MyComponent;` or `return () => <div>…</div>;`, **not** `return <MyComponent />;` or `return <div>…</div>;`. Returning a React element directly is deprecated: React on Rails currently logs a `console.error` and still renders the element, but **hooks silently don't work**, and the behavior may change in a future release. If you need to return JSX from a render function, wrap it in a server-render hash — see [Return Type 3](#3-objects-with-renderedhtml-as-a-react-element) below.

### 2. Objects with `renderedHtml` string property

```jsx
const MyComponent = (props, _railsContext) => {
  return {
    renderedHtml: `<div>Hello ${props.name}</div>`,
  };
};
```

### 3. Objects with `renderedHtml` as a React element

This is the supported way to return JSX from a render function: wrap it in `{ renderedHtml: ... }`. React on Rails will call `renderToString` on the element and use the result as the server-rendered HTML. Unlike [returning a React element directly](#1-react-components), this form is fully supported and hooks work correctly.

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

#### Async functions and ExecJS

> [!WARNING]
> Async render functions **only work with the React on Rails Pro Node renderer**. When a promise-returning render function is used on ExecJS (the OSS default SSR runtime), React on Rails logs a `console.error` and returns an empty JSON object (`'{}'`) as the server-rendered output. **The Rails view ends up with empty content and no visible exception**, which can be hard to diagnose. If you use async render functions, make sure your server runtime is the Pro Node renderer.
>
> The exact error message logged to `console.error` is: `Your render function returned a Promise, which is only supported by the React on Rails Pro Node renderer, not ExecJS.`

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
> React on Rails does not perform actual page redirections. Instead, it returns an empty component and relies on the front end to handle the redirection when the router is rendered. The `redirectLocation` property is logged in the console and ignored by the server renderer. If the `routeError` property is not null or undefined, it is logged and will cause Ruby to throw a `ReactOnRails::PrerenderError` if the `raise_on_prerender_error` configuration is enabled.

```jsx
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

3. **Which object keys trigger "server render hash" processing** — React on Rails treats a returned object as a server render hash if it contains **any** of these keys: `renderedHtml`, `redirectLocation`, `routeError`, or `error`. If none of those keys are present, the object is passed through unchanged (which typically fails validation elsewhere).
   > [!WARNING]
   > **The `error` key is a landmine.** If your render function accidentally returns `{ error: someError }` — for example from a `try/catch` block — the framework routes it through server-render-hash handling, which produces **empty HTML output** (because `renderedHtml` is missing). Note that `hasErrors` is *not* set — only `routeError` sets the error flag, so no `PrerenderError` is raised regardless of `raise_on_prerender_error`. If you want to signal failure, throw an error instead of returning one in a plain object.

4. **Async Functions Support Server Render Hashes** - When using the React on Rails Pro Node renderer, async render-functions can return React components, strings, or full server render hashes, including `clientProps`, `redirectLocation`, and `routeError`. See [8. Redirect Information (Legacy)](#8-redirect-information-legacy).

5. **`clientProps` are merged back into hydration props** - If a server render result includes `clientProps`, React on Rails merges those keys into the client hydration props generated by `react_component`.
   - Use this to pass server-only computed hydration data (for example router dehydrated state).
   - Merge order is `original_props.merge(clientProps)`, so keys from `clientProps` override matching original keys.
   - This merge requires your original `props:` to be a Ruby `Hash` or a JSON string representing an object. If you pass any other type (including `nil`), the helper raises an error with a message pointing to this requirement.
   - **Symbol vs string keys:** If your original props use a symbol key (`:locale`) and `clientProps` returns the same name as a string (`"locale"`), the merge writes to the existing symbol key to preserve its type. If your original props contain **both** forms of the same key (`:locale` and `"locale"`), the merge raises an error rather than guessing which one you meant.

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
- Client-side only rendering (always uses server rendering)
- Renderer functions (3-parameter functions) — these are client-only and incompatible with forced server rendering

#### Requirements

- The render function MUST return an object with shape `{ renderedHtml: { componentHtml, ...otherKeys } }`
- The `renderedHtml` object MUST include a `componentHtml` key — missing it raises `ReactOnRails::Error`
- All other keys inside `renderedHtml` are optional and can be accessed in your Rails view as `result["keyName"]`

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

```jsx
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
