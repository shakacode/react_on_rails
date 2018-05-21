# View Helpers API

Once the bundled files have been generated in your `app/assets/webpack` folder and you have registered your components, you will want to render these components on your Rails views using the included helper method, `react_component`.

## react_component

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

## react_component_hash

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

## redux_store

### Controller Extension

Include the module `ReactOnRails::Controller` in your controller, probably in ApplicationController. This will provide the following controller method, which you can call in your controller actions:

`redux_store(store_name, props: {})`

- **store_name:** A name for the store. You'll refer to this name in 2 places in your JavaScript:
  1. You'll call `ReactOnRails.registerStore({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
- **props:**  Named parameter `props`. ReactOnRails takes care of setting up the hydration of your store with props from the view.

For an example, see [spec/dummy/app/controllers/pages_controller.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/controllers/pages_controller.rb). Note: this is preferable to using the equivalent view_helper `redux_store` in that you can be assured that the store is initialized before your components.

### View Helper

`redux_store(store_name, props: {})`

This method has the same API as the controller extension. **HOWEVER**, we recommend the controller extension instead because the Rails executes the template code in the controller action's view file (`erb`, `haml`, `slim`, etc.) before the layout. So long as you call `redux_store` at the beginning of your action's view file, this will work. However, it's an easy mistake to put this call in the wrong place. Calling `redux_store` in the controller action ensures proper load order, regardless of where you call this in the controller action. Note: you won't know of this subtle ordering issue until you server render and you find that your store is not hydrated properly.

`redux_store_hydration_data`

Place this view helper (no parameters) at the end of your shared layout so ReactOnRails will render the redux store hydration data. Since we're going to be setting up the stores in the controllers, we need to know where on the view to put the client-side rendering of this hydration data, which is a hidden div with a matching class that contains a data props. For an example, see [spec/dummy/app/views/layouts/application.html.erb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/layouts/application.html.erb).

### Redux Store Notes

Note: you don't need to initialize your redux store. You can pass the props to your React component in a "generator function." However, consider using the `redux_store` helper for the two following use cases:

1. You want to have multiple React components accessing the same store at once.
2. You want to place the props to hydrate the client side stores at the very end of your HTML so that the browser can render all earlier HTML first. This is particularly useful if your props will be large.

## server_render_js

`server_render_js(js_expression, options = {})`

- js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught, and console messages will be handled properly
- Currently, the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.