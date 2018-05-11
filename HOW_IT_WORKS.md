## How It Works

The generator installs your webpack files in the `client` folder. Foreman uses webpack to compile your code and output the bundled results to `app/assets/webpack`, which are then loaded by sprockets. These generated bundle files have been added to your `.gitignore` for your convenience.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails. You can pass props directly to the react component helper. You can also initialize a Redux store with view or controller helper `redux_store` so that the store can be shared amongst multiple React components. See the docs for `redux_store` below and scan the code inside of the [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy) sample app.

### Client-Side Rendering vs. Server-Side Rendering

In most cases, you should use the `prerender: false` (default behavior) with the provided helper method to render the React component from your Rails views. In some cases, such as when SEO is vital, or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript using [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. We recommend using [mini_racer](https://github.com/discourse/mini_racer) as ExecJS's runtime. The generator will automatically add it to your Gemfile for you (once we complete [#501](https://github.com/shakacode/react_on_rails/issues/501)).

If you open the HTML source of any web page using React on Rails, you'll see the 3 parts of React on Rails rendering:

1. A script tag containing the properties of the React component, such as the registered name and any props. A JavaScript function runs after the page loads, using this data to build and initialize your React components.
2. The wrapper div `<div id="HelloWorld-react-component-0">` specifies the div where to place the React rendering. It encloses the server-rendered HTML for the React component.
3. Additional JavaScript is placed to console-log any messages, such as server rendering errors. Note: these server side logs can be configured only to be sent to the server logs.

**Note**:

- If server rendering is not used (prerender: false), then the major difference is that the HTML rendered for the React component only contains the outer div: `<div id="HelloWorld-react-component-0"/>`. The first specification of the React component is just the same.

### Building the Bundles

Each time you change your client code, you will need to re-generate the bundles (the webpack-created JavaScript files included in application.js). The included Foreman `Procfile.dev` will take care of this for you by starting a webpack process with the watch flag. This will watch your JavaScript code files for changes. Simply run `foreman start -f Procfile.dev`.

On production deployments that use asset precompilation, such as Heroku deployments, React on Rails, by default, will automatically run webpack to build your JavaScript bundles. You can see the source code for what gets added to your precompilation [here](https://github.com/shakacode/react_on_rails/tree/master/lib/tasks/assets.rake). For more information on this topic, see [the doc on Heroku deployment](docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).

If you have used the provided generator, these bundles will automatically be added to your `.gitignore` to prevent extraneous noise from re-generated code in your pull requests. You will want to do this manually if you do not use the provided generator.

### Generator Functions

You have 2 ways to specify your React components. You can either register the React component directly, or you can create a function that returns a React component. Creating a function has the following benefits:

1. You have access to the `railsContext`. See documentation for the railsContext in terms of why you might need it. You **need** a generator function to access the `railsContext`.
2. You can use the passed-in props to initialize a redux store or set up react-router.
3. You can return different components depending on what's in the props.

ReactOnRails will automatically detect a registered generator function. Thus, there is no difference between registering a React Component versus a "generator function."

#### react_component_hash for Generator Functions

Another reason to use a generator function is that sometimes in server rendering, specifically with React Router, you need to return the result of calling ReactDOMServer.renderToString(element). You can do this by returning an object with the following shape: { renderedHtml, redirectLocation, error }. Make sure you use this function with `react_component_hash`. 

For server rendering, if you wish to return multiple HTML strings from a generator function, you may return an Object from your generator function with a single top level property of `renderedHtml`. Inside this Object, place a key called `componentHtml`, along with any other needed keys. An example scenario of this is when you are using side effects libraries like [React Helmet](https://github.com/nfl/react-helmet). Your Ruby code will get this Object as a Hash containing keys componentHtml and any other custom keys that you added:

```js
{ renderedHtml: { componentHtml, customKey1, customKey2} }
```

For details on using react_component_hash with react-helmet, see the docs below for the helper API and [docs/additional-reading/react-helmet.md](docs/additional-reading/react-helmet.md).

### Rails Context and Generator Functions

When you use a "generator function" to create react components (or renderedHtml on the server), or you used shared redux stores, you get two params passed to your function that creates a React component:

1. `props`: Props that you pass in the view helper of either `react_component` or `redux_store`
2. `railsContext`: Rails contextual information, such as the current pathname. You can customize this in your config file. **Note**: The `railsContext` is not related to the concept of a ["context" for React components](https://facebook.github.io/react/docs/context.html#how-to-use-context).

This parameters (`props` and `railsContext`) will be the same regardless of either client or server side rendering, except for the key `serverSide` based on whether or not you are server rendering.

While you could manually configure your Rails code to pass the "`railsContext` information" with the rest of your "props", the `railsContext` is a convenience because it's passed consistently to all invocations of generator functions.

For example, suppose you create a "generator function" called MyAppComponent.

```js
import React from 'react';
const MyAppComponent = (props, railsContext) => (
  <div>
    <p>props are: {JSON.stringify(props)}</p>
    <p>railsContext is: {JSON.stringify(railsContext)}
    </p>
  </div>
);
export default MyAppComponent;
```

*Note: you will get a React browser console warning if you try to serverRender this since the value of `serverSide` will be different for server rendering.*

So if you register your generator function `MyAppComponent`, it will get called like:

```js
reactComponent = MyAppComponent(props, railsContext);
```

and, similarly, any redux store always initialized with 2 parameters:

```js
reduxStore = MyReduxStore(props, railsContext);
```

Note: you never make these calls. React on Rails makes these calls when it does either client or server rendering. You will define functions that take these 2 params and return a React component or a Redux Store. Naturally, you do not have to use second parameter of the railsContext if you do not need it.

(Note: see below [section](#multiple-react-components-on-a-page-with-one-store) on how to setup redux stores that allow multiple components to talk to the same store.)

The `railsContext` has: (see implementation in file [react_on_rails_helper.rb](https://github.com/shakacode/react_on_rails/tree/master/app/helpers/react_on_rails_helper.rb), method `rails_context` for the definitive list).

```ruby
  {
    railsEnv: Rails.env
    # URL settings
    href: request.original_url,
    location: "#{uri.path}#{uri.query.present? ? "?#{uri.query}": ""}",
    scheme: uri.scheme, # http
    host: uri.host, # foo.com
    port: uri.port,
    pathname: uri.path, # /posts
    search: uri.query, # id=30&limit=5

    # Other
    serverSide: boolean # Are we being called on the server or client? Note: if you conditionally
     # render something different on the server than the client, then React will only show the
     # server version!
  }
```

#### Why the railsContext is only passed to generator functions

There's no reason that the railsContext would ever get passed to your React component unless the value is explicitly put into the props used for rendering. If you create a react component, rather than a generator function, for use by React on Rails, then you get whatever props are passed in from the view helper, which **does not include the Rails Context**. It's trivial to wrap your component in a "generator function" to return a new component that takes both:

```js
import React from 'react';
import AppComponent from './AppComponent';
const AppComponentWithRailsContext = (props, railsContext) => (
  <AppComponent {...{...props, railsContext}}/>
)
export default AppComponentWithRailsContext;
```

Consider this line in depth:

```js
  <AppComponent {...{ ...props, railsContext }}/>
```

The outer `{...` is for the [JSX spread operator for attributes](https://facebook.github.io/react/docs/jsx-in-depth.html#spread-attributes) and the innner `{...` is for the [Spread in object literals](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator#Spread_in_object_literals).

#### Use Cases

##### Heroku Preboot Considerations

[Heroku Preboot](https://devcenter.heroku.com/articles/preboot) is a feature on Heroku that allows for faster deploy times. When you promote your staging app to production, Preboot simply switches the production server to point at the staging app's container. This means it can deploy much faster since it doesn't have to rebuild anything. However, this means that if you use the [Define Plugin](https://github.com/webpack/docs/wiki/list-of-plugins#defineplugin) to provide the rails environment to your client code as a variable, that variable will erroneously still have a value of `Staging` instead of `Production`. The `Rails.env` provided at runtime in the railsContext is, however, accurate.

##### Needing the current URL path for server rendering

Suppose you want to display a nav bar with the current navigation link highlighted by the URL. When you server-render the code, your code will need to know the current URL/path. The new `railsContext` has this information. Your application will apply something like an "active" class on the server rendering.

##### Configuring different code for server side rendering

Suppose you want to turn off animation when doing server side rendering. The `serverSide` value is just what you need.

#### Customization of the rails_context

You can customize the values passed in the `railsContext` in your `config/initializers/react_on_rails.rb`. Here's how.

Set the config value for the `rendering_extension`:

```ruby
  config.rendering_extension = RenderingExtension
```

Implement it like this above in the same file. Create a class method on the module called `custom_context` that takes the `view_context` for a param.

See [spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb) for a detailed example.

```ruby
module RenderingExtension

  # Return a Hash that contains custom values from the view context that will get merged with
  # the standard rails_context values and passed to all calls to generator functions used by the
  # react_component and redux_store view helpers
  def self.custom_context(view_context)
    {
     somethingUseful: view_context.session[:something_useful]
    }
  end
end
```

In this case, a prop and value for `somethingUseful` will go into the railsContext passed to all react_component and redux_store calls. You may set any values available in the view rendering context.

### Globally Exposing Your React Components

Place your JavaScript code inside of the default `app/javascript` folder. Use modules just as you would when using webpack alone. The difference here is that instead of mounting React components directly to an element using `React.render`, you **register your components to ReactOnRails and then mount them with helpers inside of your Rails views**.

This is how to expose a component to the `react_component` view helper.

```javascript
  // app/javascript/packs/hello-world-bundle.js
  import HelloWorld from '../components/HelloWorld';
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register({ HelloWorld });
```

#### Different Server-Side Rendering Code (and a Server Specific Bundle)

You may want different initialization for your server-rendered components. For example, if you have an animation that runs when a component is displayed, you might need to turn that off when server rendering. However, the `railsContext` will tell you if your JavaScript code is running client side or server side. So code that required a different server bundle previously may no longer require this. Note, check if `window` is defined has a similar effect.

If you want different code to run, you'd set up a separate webpack compilation file and you'd specify a different, server side entry file. ex. 'serverHelloWorld.jsx'. Note: you might be initializing HelloWorld with version specialized for server rendering.

#### Renderer Functions

A renderer function is a generator function that accepts three arguments: `(props, railsContext, domNodeId) => { ... }`. Instead of returning a React component, a renderer is responsible for calling `ReactDOM.render` to render a React component into the dom. Why would you want to call `ReactDOM.render` yourself? One possible use case is [code splitting](docs/additional-reading/code-splitting.md).

Renderer functions are not meant to be used on the server since there's no DOM on the server. Instead, use a generator function. Attempting to server render with a renderer function will cause an error.
