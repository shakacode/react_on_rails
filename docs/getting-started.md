# Getting Started

Note, the best way to understand how to use ReactOnRails is to study a few simple examples. You can do a quick demo setup, either on your existing app or on a new Rails app.

This documentation assumes the usage of ReactOnRails with Shakapacker 7. For installation on Shakapacker 6, check [tips for usage with Shakapacker 6](./additional-details/tips-for-usage-with-sp6.md) first.

1. Do the quick [tutorial](./guides/tutorial.md).
2. Add React on Rails to an existing Rails app per [the instructions](./guides/installation-into-an-existing-rails-app.md).
3. Look at [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy), a simple, no DB example.
4. Look at [github.com/shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial); it's a full-featured example live at [www.reactrails.com](http://reactrails.com).

## Basic Installation

You need a Rails application with Shakapacker installed and configured on it. Check [Shakapacker documentation](https://github.com/shakacode/shakapacker) for more details but typically you need the following steps:

```bash
rails new PROJECT_NAME --skip-javascript
cd PROJECT_NAME
bundle add shakapacker --strict
rails shakapacker:install
```

You may need to check [the instructions for installing into an existing Rails app](./guides/installation-into-an-existing-rails-app.md) if you have an already working Rails application.

1. Add the `react_on_rails` gem to Gemfile:
   Please use [the latest version](https://rubygems.org/gems/react_on_rails) to ensure you get all the security patches and the best support.

   ```bash
   bundle add react_on_rails --version=14.0.4 --strict
   ```

   Commit this to git (or else you cannot run the generator in the next step unless you pass the option `--ignore-warnings`).

2. Run the install generator:

   ```bash
   rails generate react_on_rails:install
   ```

3. Start the app:

   - Run `./bin/dev` for HMR
   - Run `./bin/dev-static` for statically created bundles (no HMR)

4. Visit http://localhost:3000/hello_world.

### Turning on server rendering

With the code from running the React on Rails generator above:

1. Edit `app/views/hello_world/index.html.erb` and set the `prerender` option to `true`.

   You may need to use `Node` as your js runtime environment by setting `EXECJS_RUNTIME=Node` into your environment variables.

2. Refresh the page.

Below is the line where you turn server rendering on by setting `prerender` to true:

```erb
<%= react_component("HelloWorld", props: @hello_world_props, prerender: true) %>
```

Note, if you got an error in your console regarding "ReferenceError: window is not defined",
then you need to edit `config/shakapacker.yml` and set `hmr: false` and `inline: false`.
See [rails/webpacker PR 2644](https://github.com/rails/webpacker/pull/2644) for a fix for this
issue.

## Basic Usage

### Configuration

- Configure `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [docs/basics/configuration.md](./guides/configuration.md) for documentation of all configuration options.
- Configure `config/shakapacker.yml`. If you used the generator and the default Shakapacker setup, you don't need to touch this file. If you are customizing your setup, then consult the [spec/dummy/config/shakapacker.yml](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/shakapacker.yml) example or the official default [shakapacker.yml](https://github.com/shakacode/shakapacker/blob/master/lib/install/config/shakapacker.yml).
- Most apps should rely on the Shakapacker setup for Webpack. Shakapacker v6+ includes support for Webpack version 5.

## Including your React Component on your Rails Views

- React components are rendered via your Rails Views. Here's an ERB sample:

  ```erb
  <%= react_component("HelloWorld", props: @some_props) %>
  ```

- **Server-Side Rendering**: Your React component is first rendered into HTML on the server. Use the **prerender** option:

  ```erb
  <%= react_component("HelloWorld", props: @some_props, prerender: true) %>
  ```

- The `component_name` parameter is a string matching the name you used to expose your React component globally. So, in the above examples, if you had a React component named "HelloWorld", you would register it with the following lines:

  ```js
  import ReactOnRails from 'react-on-rails';
  import HelloWorld from './HelloWorld';
  ReactOnRails.register({ HelloWorld });
  ```

  Exposing your component in this way allows you to reference the component from a Rails view. You can expose as many components as you like, but their names must be unique. See below for the details of how you expose your components via the React on Rails Webpack configuration. You may call `ReactOnRails.register` many times.

- `@some_props` can be either a hash or JSON string. This is an optional argument assuming you do not need to pass any options (if you want to pass options, such as `prerender: true`, but you do not want to pass any properties, simply pass an empty hash `{}`). This will make the data available in your component:

  ```erb
    # Rails View
    <%= react_component("HelloWorld", props: { name: "Stranger" }) %>
  ```

- This is what your HelloWorld.js file might contain. The railsContext is always available for any parameters that you _always_ want available for your React components. It has _nothing_ to do with the concept of the [React Context](https://reactjs.org/docs/context.html). See [Render-Functions and the RailsContext](./guides/render-functions-and-railscontext.md) for more details on this topic.

  ```js
  import React from 'react';

  export default (props, railsContext) => {
    // Note wrap in a function to make this a React function component
    return () => (
      <div>
        Your locale is {railsContext.i18nLocale}.<br />
        Hello, {props.name}!
      </div>
    );
  };
  ```

See the [View Helpers API](./api/view-helpers-api.md) for more details on `react_component` and its sibling function `react_component_hash`.

## Globally Exposing Your React Components

For the React on Rails view helper `react_component` to use your React components, you will have to **register** them in your JavaScript code.

Use modules just as you would when using Webpack and React without Rails. The difference is that instead of mounting React components directly to an element using `React.render`, you **register your components to ReactOnRails and then mount them with helpers inside of your Rails views**.

This is how to expose a component to the `react_component` view helper.

```javascript
// app/javascript/packs/hello-world-bundle.js
import HelloWorld from '../components/HelloWorld';
import ReactOnRails from 'react-on-rails';
ReactOnRails.register({ HelloWorld });
```

#### Different Server-Side Rendering Code (and a Server-Specific Bundle)

You may want different code for your server-rendered components running on the server side versus the client side. For example, if you have an animation that runs when a component is displayed, you might need to turn that off when server rendering. One way to handle this is conditional code like `if (typeof window !== 'undefined') { doClientOnlyCode() }`.

Another way is to use a separate Webpack configuration file that can use a different server-side entry file, like 'serverRegistration.js' as opposed to 'clientRegistration.js.' That would set up different code for server rendering.

For details on techniques to use different code for client and server rendering, see: [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352). (_Requires creating a free account._)

## Specifying Your React Components: Register directly or use render-functions

You have two ways to specify your React components. You can either register the React component (either function or class component) directly, or you can create a function that returns a React component, which we using the name of a "render-function". Creating a render-function allows you to:

1. Access to the `railsContext`. See the [documentation for the railsContext](./guides/render-functions-and-railscontext.md) in terms of why you might need it. You **need** a Render-Function to access the `railsContext`.
2. Use the passed-in props to initialize a redux store or set up `react-router`.
3. Return different components depending on what's in the props.

Note, the return value of a **Render-Function** should be either a React Function or Class Component or an object representing server rendering results.

**Do not return a React Element (JSX).**

ReactOnRails will automatically detect a registered Render-Function by the fact that the function takes
more than 1 parameter. In other words, if you want the ability to provide a function that returns the
React component, then you need to specify at least a second parameter. This is the `railsContext`.
If you're not using this parameter, declare your function with the unused param:

```js
const MyComponentGenerator = (props, _railsContext) => {
  if (props.print) {
    // This is a React FunctionComponent because it is wrapped in a function.
    return () => <H1>{JSON.stringify(props)}</H1>;
  }
};
```

Thus, there is no difference between registering a React Function Component or class Component versus a "Render-Function." Just call `ReactOnRails.register`.

## react_component_hash for Render-Functions

Another reason to use a Render-Function is that sometimes in server rendering, specifically with React Router, you need to return the result of calling ReactDOMServer.renderToString(element). You can do this by returning an object with the following shape: `{ renderedHtml, redirectLocation, error }`. Make sure you use this function with `react_component_hash`.

For server rendering, if you wish to return multiple HTML strings from a Render-Function, you may return an Object from your Render-Function with a single top-level property of `renderedHtml`. Inside this Object, place a key called `componentHtml`, along with any other needed keys. An example scenario of this is when you are using side effects libraries like [React Helmet](https://github.com/nfl/react-helmet). Your Ruby code will get this Object as a Hash containing keys `componentHtml` and any other custom keys that you added:

```js
{
  renderedHtml: {
    componentHtml,
    customKey1,
    customKey2,
  },
}
```

For details on using react_component_hash with react-helmet, see [our react-helmet documentation](./javascript/react-helmet.md).

## Error Handling

- All errors from ReactOnRails will be of type ReactOnRails::Error.
- Prerendering (server rendering) errors get context information for HoneyBadger and Sentry for easier debugging.

## I18n

React on Rails provides an option for automatic conversions of Rails `*.yml` locale files into `*.json` or `*.js`.
See the [How to add I18n](./guides/i18n.md) for a summary of adding I18n.
