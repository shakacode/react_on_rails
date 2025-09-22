# How React on Rails Works (with Shakapacker)

*Note, older versions of React on Rails pushed the Webpack bundles through the Asset Pipeline. This older method has *many* disadvantages, such as broken sourcemaps, performance issues, etc. If you need help migrating to the current way of bypassing the Asset Pipeline, [email Justin](mailto:justin@shakacode.com).*

Webpack is used to generate JavaScript and CSS "bundles" directly to your `/public` directory. [Shakapacker](https://github.com/shakacode/shakapacker) provides view helpers to access the Webpack-generated (and fingerprinted) JS and CSS. These files totally skip the Rails asset pipeline. You are responsible for properly configuring your Webpack output. You will either use the standard Webpack configuration (_recommended_) or the `shakapacker` setup for Webpack.

Ensure these generated bundle files are in your `.gitignore`, as you never want to add the large compiled bundles to Git.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails. You can pass props directly to the React component helper.

Optionally, you can also initialize a Redux store with the view or controller helper `redux_store` so that the Redux store can be shared amongst multiple React components.

## Client-Side Rendering vs. Server-Side Rendering

In most cases, you should use the `prerender: false` (default behavior) with the provided `react_component` helper method to render the React component from your Rails views. In some cases, such as when SEO is vital, or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript. The default is to use [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. If you want to maximize the performance of your server rendering, then you want to use React on Rails Pro which uses NodeJS to do the server rendering. See the [docs for React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki).

## HTML Source Code

If you open the HTML source of any web page using React on Rails, you'll see the 3 parts of React on Rails rendering:

1. The wrapper div `<div id="HelloWorld-react-component-0">` specifies the div where to place the React rendering. It encloses the server-rendered HTML for the React component. If server rendering is not used (prerender: false), then the major difference is that the HTML rendered for the React component only contains the outer div: `<div id="HelloWorld-react-component-0"/>`. The first specification of the React component is just the same.
1. A script tag containing the properties of the React component, such as the registered name and any props. A JavaScript function runs after the page loads, using this data to build and initialize your React components.
1. Additional JavaScript is placed to console-log any messages, such as server rendering errors. Note: these server-side logs can be configured only to be sent to the server logs.

You can see all this on the source for [reactrails.com](https://reactrails.com/)

## Building the Bundles

Each time you change your client code, you will need to re-generate the bundles (the Webpack-created JavaScript files included in `application.js`). The included example Foreman `Procfile.dev` files will take care of this for you by starting a Webpack process with the watch flag. This will watch your JavaScript code files for changes. Alternatively, the `shakapacker` library also can ensure that your bundles are built.

For example, you might create a [Procfile.dev](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/Procfile.dev).

On production deployments that use asset precompilation, such as Heroku deployments, `shakapacker`, by default, will automatically run Webpack to build your JavaScript bundles, running the command `bin/shakapacker` in your app.

However, if you want to run a custom command to run Webpack to build your bundles, then you will:

1. Define `config.build_production_command` in your [config/initializers/react_on_rails.rb](./configuration.md)

Then React on Rails modifies the `assets:precompile` task to run your `build_production_command`.

If you have used the provided generator, these bundles will automatically be added to your `.gitignore` to prevent extraneous noise from re-generated code in your pull requests. You will want to do this manually if you do not use the provided generator.

You can stop React on Rails from modifying or creating the `assets:precompile` task, by setting a `REACT_ON_RAILS_PRECOMPILE` environment variable to `no`, `false`, `n` or `f`.
