## Rails View Helpers In-Depth
Once the bundled files have been generated in your `app/assets/javascripts/generated` folder and you have exposed your components globally, you will want to run your code in your Rails views using the included helper method.

This is how you actually render the React components you exposed to `window` inside of `clientRegistration` (and `global` inside of `serverRegistration` if you are server rendering).

### react_component
`react_component(component_name, options = {})`

+ **component_name:** Can be a React component, created using a ES6 class, or `React.createClass`, or a generator function that returns a React component.
+ **options:**
  + **props:** Ruby Hash which contains the properties to pass to the react object, or a JSON string. If you pass a string, we'll escape it for you.
  + **prerender:** enable server-side rendering of component. Set to false when debugging!
  + **router_redirect_callback:** Use this option if you want to provide a custom handler for redirects on server rendering. If you don't specify this, we'll simply change the rendered output to a script that sets window.location to the new route. Set this up exactly like a generator_function. Your function will take one parameter, containing all the values that react-router gives on a redirect request, such as pathname, search, etc.
  + **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise.
  + **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the default configuration of logging_on_server set to true, you'll still see the errors on the server.
  + **raise_on_prerender_error:** Default is false. True will throw an error on the server side rendering. Your controller will have to handle the error.
+ Any other options are passed to the content tag, including the id

### redux_store
`redux_store(store_name, props = {})`

+ **store_name:** A name for the store. You'll refer to this name in 2 places in your JavaScript:
  1. You'll call `ReactOnRails.registerStore({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
+ **props:**  ReactOnRails takes care of setting up the hydration of your store with props from the view.

### Generator Functions
Why would you create a function that returns a React compnent? For example, you may want the ability to use the passed-in props to initialize a redux store or setup react-router. Or you may want to return different components depending on what's in the props. ReactOnRails will automatically detect a registered generator function.

### server_render_js
`server_render_js(js_expression, options = {})`

+ js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught and console messages handled properly
+ Currently the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.