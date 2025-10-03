# View and Controller Helpers

## View Helpers API

Once the bundled files have been generated in your `app/assets/webpack` folder, and you have registered your components, you will want to render these components on your Rails views using the included helper method, [`react_component`](#react_component).

---

### react_component

```ruby
react_component(component_name,
                props: {},
                prerender: nil)
                html_options: {})
```

Uncommonly used options:

```
  trace: nil,
  replay_console: nil,
  raise_on_prerender_error: nil,
  id: nil,
```

- **component_name:** Can be a React component, created using a React Function Component, an ES6 class or a Render-Function that returns a React component (or, only on the server side, an object with shape `{ redirectLocation, error, renderedHtml }`), or a "renderer function" that manually renders a React component to the dom (client side only). Note, a "renderer function" is a special type of "Render-Function." A "renderer function" takes a 3rd param of a DOM ID.
  All options except `props, id, html_options` will inherit from your `react_on_rails.rb` initializer, as described [here](../guides/configuration.md).
- **general options:**
  - **props:** Ruby Hash which contains the properties to pass to the React object, or a JSON string. If you pass a string, we'll escape it for you.
  - **prerender:** enable server-side rendering of a component. Set to false when debugging!
  - **auto_load_bundle:** will automatically load the bundle for component by calling `append_javascript_pack_tag` and `append_stylesheet_pack_tag` under the hood.
  - **id:** Id for the div, will be used to attach the React component. This will get assigned automatically if you do not provide an id. Must be unique.
  - **html_options:** Any other HTML options get placed on the added div for the component. For example, you can set a class (or inline style) on the outer div so that it behaves like a span, with the styling of `display:inline-block`. You may also use an option of `tag: "span"` to replace the use of the default DIV tag to be a SPAN tag.
  - **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise. Only on the **client side** will you will see the `railsContext` and your props.
  - **random_dom_id:** True to automatically generate random dom ids when using multiple instances of the same React component on one Rails view.
- **options if prerender (server rendering) is true:**
  - **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the configuration of `logging_on_server` set to true, you'll still see the errors on the server.
  - **logging_on_server:** Default is true. True will log JS console messages and errors to the server.
  - **raise_on_prerender_error:** Default is false. True will throw an error on the server side rendering. Your controller will have to handle the error.

---

### react_component_hash

`react_component_hash` is used to return multiple HTML strings for server rendering, such as for
adding meta-tags to a page. It is exactly like react_component except for the following:

1. `prerender: true` is automatically added to options, as this method doesn't make sense for
   client only rendering.
2. Your JavaScript Render-Function for server rendering must return an Object rather than a React Component.
3. Your view code must expect an object and not a string.

Here is an example of ERB view code:

```erb
  <% react_helmet_app = react_component_hash("ReactHelmetApp", prerender: true,
                                             props: { helloWorldData: { name: "Mr. Server Side Rendering"}},
                                             id: "react-helmet-0", trace: true) %>
  <% content_for :title do %>
    <%= react_helmet_app['title'] %>
  <% end %>
  <%= react_helmet_app["componentHtml"] %>
```

And here is the JavaScript code:

```js
export default (props, _railsContext) => {
  const componentHtml = renderToString(<ReactHelmet {...props} />);
  const helmet = Helmet.renderStatic();

  const renderedHtml = {
    componentHtml,
    title: helmet.title.toString(),
  };
  return { renderedHtml };
};
```

---

### cached_react_component and cached_react_component_hash

Fragment caching is a [React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki) feature. The API is the same as the above, but for 2 differences:

1. The `cache_key` takes the same parameters as any Rails `cache` view helper.
1. The **props** are passed via a block so that evaluation of the props is not done unless the cache is broken. Suppose you put your props calculation into some method called `some_slow_method_that_returns_props`:

```erb
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end %>
```

---

### rails_context

You can call `rails_context` or `rails_context(server_side: true|false)` from your controller or view to see what values are in the Rails Context. Pass true or false depending on whether you want to see the server-side or the client-side `rails_context`. Typically, for computing cache keys, you should leave `server_side` as the default true. When calling this from a controller method, use `helpers.rails_context`.

---

### Renderer Functions (function that will call ReactDOM.render or ReactDOM.hydrate)

A "renderer function" is a Render-Function that accepts three arguments (rather than 2): `(props, railsContext, domNodeId) => { ... }`. Instead of returning a React component, a renderer is responsible for installing a callback that will call `ReactDOM.render` (in React 16+, `ReactDOM.hydrate`) to render a React component into the DOM. The "renderer function" is called at the same time the document ready event would instantiate the React components into the DOM.

Why would you want to call `ReactDOM.hydrate` yourself? One possible use case is [code splitting](../javascript/code-splitting.md). In a nutshell, you don't want to load the React component on the DOM node yet. So you want to install some handler that will call `ReactDOM.hydrate` at a later time. In the case of code splitting with server rendering, the server rendered code has any async code loaded and used to server render. Thus, the client code must also fully load any asynch code before server rendering. Otherwise, the client code would first render partially, not matching the server rendering, and then a second later, the full code would render, resulting in an unpleasant flashing on the screen.

Renderer functions are not meant to be used on the server since there's no DOM on the server. Instead, use a Render-Function. Attempting to server render with a renderer function will throw an error.

---

### React Router

[React Router](https://reactrouter.com/) is supported, including server-side rendering! See:

1. [React on Rails docs for React Router](../javascript/react-router.md)
2. Examples in [spec/dummy/app/views/react_router](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/react_router) and follow to the JavaScript code in the [spec/dummy/client/app/startup/RouterApp.server.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/startup/RouterApp.server.jsx).
3. [Code Splitting docs](../javascript/code-splitting.md) for information about how to set up code splitting for server rendered routes.

---

## server_render_js

`server_render_js(js_expression, options = {})`

- js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught, and console messages will be handled properly
- Currently, the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

---

# More details

See the [lib/react_on_rails/helper.rb](https://github.com/shakacode/react_on_rails/tree/master/lib/react_on_rails/helper.rb) source.
