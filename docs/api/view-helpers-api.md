# View and Controller Helpers
##  View Helpers API

Once the bundled files have been generated in your `app/assets/webpack` folder and you have registered your components, you will want to render these components on your Rails views using the included helper method, `react_component`.

### react_component

```ruby
react_component(component_name,
                props: {},
                prerender: nil,
                trace: nil,
                replay_console: nil,
                raise_on_prerender_error: nil,
                id: nil,
                html_options: {})
```

- **component_name:** Can be a React component, created using an ES6 class or a generator function that returns a React component (or, only on the server side, an object with shape { redirectLocation, error, renderedHtml }), or a "renderer function" that manually renders a React component to the dom (client side only).
  All options except `props, id, html_options` will inherit from your `react_on_rails.rb` initializer, as described [here](../../docs/basics/configuration.md).
- **general options:**
  - **props:** Ruby Hash which contains the properties to pass to the react object, or a JSON string. If you pass a string, we'll escape it for you.
  - **prerender:** enable server-side rendering of a component. Set to false when debugging!
  - **id:** Id for the div, will be used to attach the React component. This will get assigned automatically if you do not provide an id. Must be unique.
  - **html_options:** Any other HTML options get placed on the added div for the component. For example, you can set a class (or inline style) on the outer div so that it behaves like a span, with the styling of `display:inline-block`.
  - **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise. Only on the **client side** will you will see the `railsContext` and your props.
- **options if prerender (server rendering) is true:**
  - **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the configuration of `logging_on_server` set to true, you'll still see the errors on the server.
  - **logging_on_server:** Default is true. True will log JS console messages and errors to the server.
  - **raise_on_prerender_error:** Default is false. True will throw an error on the server side rendering. Your controller will have to handle the error.

### react_component_hash

`react_component_hash` is used to return multiple HTML strings for server rendering, such as for
adding meta-tags to a page. It is exactly like react_component except for the following:

1. `prerender: true` is automatically added to options, as this method doesn't make sense for 
   client only rendering.
2. Your JavaScript for server rendering must return an Object for the key `server_rendered_html`.
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

### Renderer Functions

A renderer function is a generator function that accepts three arguments: `(props, railsContext, domNodeId) => { ... }`. Instead of returning a React component, a renderer is responsible for calling `ReactDOM.render` to render a React component into the dom. Why would you want to call `ReactDOM.render` yourself? One possible use case is [code splitting](docs/additional-reading/code-splitting.md).

Renderer functions are not meant to be used on the server since there's no DOM on the server. Instead, use a generator function. Attempting to server render with a renderer function will throw an error.

### React Router

[React Router](https://github.com/reactjs/react-router) is supported, including server-side rendering! See:

1. [React on Rails docs for react-router](docs/additional-reading/react-router.md)
2. Examples in [spec/dummy/app/views/react_router](./spec/dummy/app/views/react_router) and follow to the JavaScript code in the [spec/dummy/client/app/startup/ServerRouterApp.jsx](spec/dummy/client/app/startup/ServerRouterApp.jsx).
3. [Code Splitting docs](docs/additional-reading/code-splitting.md) for information about how to set up code splitting for server rendered routes.

## server_render_js

`server_render_js(js_expression, options = {})`

- js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught, and console messages will be handled properly
- Currently, the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

# More details

See the [lib/react_on_rails/react_on_rails_helper.rb](../../lib/react_on_rails/react_on_rails_helper.rb) source.

