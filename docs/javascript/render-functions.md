# React on Rails Render Functions: Usage Guide

Based on the test file `serverRenderReactComponent.test.ts` and the existing documentation, I'll clarify how render functions work in React on Rails and how to use them with each Ruby helper method.

## Types of Render Functions and Their Return Values

Looking at the test file, render functions can return several types of values:

### 1. React Components (JSX)

```jsx
const MyComponent = (props, _railsContext) => {
  return <div>Hello {props.name}</div>;
};
```

### 2. Objects with renderedHtml Property

```jsx
const MyComponent = (props, _railsContext) => {
  return {
    renderedHtml: `<div>Hello ${props.name}</div>`,
  };
};
```

### 3. Objects with Multiple HTML Properties

```jsx
const MyComponent = (props, _railsContext) => {
  return {
    componentHtml: <div>Hello {props.name}</div>,
    title: `<title>${props.title}</title>`,
    metaTags: `<meta name="description" content="${props.description}" />`,
  };
};
```

### 4. Promises of Strings

```jsx
const MyComponent = async (props, _railsContext) => {
  const data = await fetchData();
  return `<div>Hello ${data.name}</div>`;
};
```

### 5. Promises of Objects

```jsx
const MyComponent = async (props, _railsContext) => {
  const data = await fetchData();
  return {
    componentHtml: `<div>Hello ${data.name}</div>`,
  };
};
```

### 6. Redirect Information

```jsx
const MyComponent = (props, _railsContext) => {
  return {
    redirectLocation: '/new-path',
    error: null,
    renderedHtml: null,
  };
};
```

## Important Limitations Observed in Tests

The test file reveals some important limitations:

1. **Direct String Returns Don't Work** - Returning a raw HTML string directly from a render function causes an error. The test `doesn't render html string returned directly from render function` demonstrates this.

2. **Non-Promise Objects Need renderedHtml** - Non-promise objects must include a `renderedHtml` property to be valid, as shown in the test `doesn't render object without renderedHtml property`.

3. **Async Functions Have Different Behavior** - Interestingly, the test `returns the object returned by async render function even if it doesn't have renderedHtml property` shows that Promise-returning functions can return objects without a `renderedHtml` property and they will still work.

## Ruby Helper Functions with Render Functions

### 1. react_component

The `react_component` helper is used for rendering a single React component. It accepts various return types from render functions:

```ruby
# Basic usage with a component
<%= react_component("MyComponent", props: { name: "John" }) %>

# With a render function that returns JSX
<%= react_component("MyRenderFunction", props: { name: "John" }) %>

# With a render function that returns an object with renderedHtml
<%= react_component("MyRenderFunction", props: { name: "John" }) %>

# With a render function that returns a Promise
<%= react_component("MyAsyncRenderFunction", props: { name: "John" }) %>
```

#### When to use:

- When you need to render a single component
- When you're rendering client-side only
- When your render function returns a single HTML string

#### Not suitable for:

- When your render function returns an object with multiple HTML strings
- When you need to insert content in different parts of the page

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

#### When to use:

- When your render function returns multiple HTML strings in an object
- When you need to insert rendered content in different parts of your page
- For SEO-related rendering like meta tags and title tags
- When working with libraries like React Helmet

#### Not suitable for:

- Simple component rendering
- Client-side only rendering (always uses server rendering)

#### Requirements:

- The render function MUST return an object
- The object MUST include a `componentHtml` key
- All other keys are optional and can be accessed in your Rails view

## Best Practices Based on the Tests

1. **Always Use Objects for Multiple HTML Parts**: If you need multiple HTML strings, return an object with named properties, and use `react_component_hash` to access them.

2. **Don't Return Raw HTML Strings**: Tests show that returning a raw HTML string directly causes errors - either use JSX or wrap in a `{ renderedHtml: '...' }` object.

3. **Async Functions Work with Objects**: For async render functions, you can return both strings and objects (with or without a `renderedHtml` property).

4. **Use Redirect Object Format**: For redirects, return an object with `{ redirectLocation, error, renderedHtml: null }`.

## Example: Different Return Types with Appropriate Helper Methods

### Return Type 1: React Component

```jsx
// JavaScript
const SimpleComponent = (props) => <div>Hello {props.name}</div>;
ReactOnRails.register({ SimpleComponent });
```

```erb
<%# Ruby - Either helper works %>
<%= react_component("SimpleComponent", props: { name: "John" }) %>
```

### Return Type 2: Object with renderedHtml

```jsx
// JavaScript
const RenderedHtmlComponent = (props) => {
  return { renderedHtml: `<div>Hello ${props.name}</div>` };
};
ReactOnRails.register({ RenderedHtmlComponent });
```

```erb
<%# Ruby - Either helper works %>
<%= react_component("RenderedHtmlComponent", props: { name: "John" }) %>
```

### Return Type 3: Object with Multiple HTML Properties

```jsx
// JavaScript
const HelmetComponent = (props) => {
  return {
    componentHtml: <div>Hello {props.name}</div>,
    title: `<title>${props.title}</title>`,
    metaTags: `<meta name="description" content="${props.description}" />`,
  };
};
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
// JavaScript
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

### Return Type 5: Promise of Object

```jsx
// JavaScript
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

### Return Type 6: Redirect Object

```jsx
const RedirectComponent = (props, railsContext) => {
  if (!railsContext.currentUser) {
    return {
      redirectLocation: { pathname: '/login', search: '' }, // Object with pathname and search
      error: null,
      renderedHtml: null, // Use renderedHtml for consistency
    };
  }
  return {
    renderedHtml: <div>Welcome {railsContext.currentUser.name}</div>, // Use renderedHtml for consistency
  };
};
RedirectComponent.renderFunction = true;
ReactOnRails.register({ RedirectComponent });
```

```erb
<%# Ruby - Either helper works %>
<%= react_component("RedirectComponent") %>
```

By understanding the different return types and which helper to use with each, you can create sophisticated server-rendered React components that fully integrate with your Rails views.
