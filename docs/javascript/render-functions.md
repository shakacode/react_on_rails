# React on Rails Render-Functions: Usage Guide

This guide explains how render-functions work in React on Rails and how to use them with Ruby helper methods.

## Types of Render-Functions and Their Return Values

Render-functions take two parameters:

1. `props`: The props passed from the Ruby helper methods (via the `props:` parameter), which become available in your JavaScript.
2. `railsContext`: Rails contextual information like current pathname, locale, etc. See the [Render-Functions and the Rails Context](../guides/render-functions-and-railscontext.md) documentation for more details.

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

### 3. Objects with `renderedHtml` as object containing `componentHtml` and other properties if needed (server-side hash)

```jsx
const MyComponent = (props, _railsContext) => {
  return {
    renderedHtml: {
      componentHtml: <div>Hello {props.name}</div>,
      title: `<title>${props.title}</title>`,
      metaTags: `<meta name="description" content="${props.description}" />`,
    },
  };
};
```

### 4. Promises of Strings

This and other promise options below are only available in React on Rails Pro with the Node renderer.

```jsx
const MyComponent = async (props, _railsContext) => {
  const data = await fetchData();
  return `<div>Hello ${data.name}</div>`;
};
```

### 5. Promises of server-side hash

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

### 6. Promises of React Components

```jsx
const MyComponent = async (props, _railsContext) => {
  const data = await fetchData();
  return () => <div>Hello {data.name}</div>;
};
```

### 7. Redirect Information

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

Take a look at [serverRenderReactComponent.test.ts](https://github.com/shakacode/react_on_rails/blob/master/node_package/tests/serverRenderReactComponent.test.ts):

1. **Direct String Returns Don't Work** - Returning a raw HTML string directly from a render function causes an error. Always wrap HTML strings in `{ renderedHtml: '...' }`.

2. **Objects Require Specific Properties** - Non-promise objects must include a `renderedHtml` property to be valid when used with `react_component`.

3. **Async Functions Support All Return Types** - Async functions can return React components, strings, or objects with any property structure due to special handling in the server renderer, but it doesn't support properties like `redirectLocation` and `routeError` that can be returned by sync render function. See [7. Redirect Information](#7-redirect-information).

## Ruby Helper Functions

### 1. react_component

The `react_component` helper renders a single React component in your view.

```ruby
<%= react_component("MyComponent", props: { name: "John" }) %>
```

This helper accepts render-functions that return React components, objects with a `renderedHtml` property, or promises that resolve to React components, or strings.

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

#### Requirements

- The render function MUST return an object
- The object MUST include a `componentHtml` key
- All other keys are optional and can be accessed in your Rails view

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

### Return Type 3: Object with server-side hash

```jsx
const HelmetComponent = (props) => {
  return {
    renderedHtml: {
      componentHtml: <div>Hello {props.name}</div>,
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

### Return Type 4: Promise of String

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

### Return Type 5: Promise of server-side hash

```jsx
const AsyncObjectComponent = async (props) => {
  const data = await fetchData();
  return {
    componentHtml: <div>Hello {data.name}</div>,
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

### Return Type 6: Promise of React Component

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

### Return Type 7: Redirect Object

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

By understanding these return types and which helper to use with each, you can create sophisticated server-rendered React components that fully integrate with your Rails views.
