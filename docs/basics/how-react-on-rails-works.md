# How React on Rails Works (with rails/webpacker)

*Note, older versions of React on Rails pushed the Webpack bundles through the Asset Pipeline. This older method has *many* disadvantages, such as broken sourcemaps, performance issues, etc. If you need help migrating to the current way of bypassing the Asset Pipeline, [email Justin](mailto:justin@shakacode.com).* 

Webpack is used to generate JavaScript and CSS "bundles" directly to your `/public` directory. [rails/webpacker](https://github.com/rails/webpacker) provides view helpers to access the Webpack generated (and fingerprinted) JS and CSS. These files totally skip the Rails asset pipeline. You are responsible for properly configuring your Webpack output. You will either use the standard Webpack configuration (*recommended*) or the `rails/webpacker` setup for Webpack. 

Ensure these generated bundle files are in your `.gitignore`, as you never want to add the large compiled bundles to git.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails. You can pass props directly to the react component helper. 

Optionally, you can also initialize a Redux store with the view or controller helper `redux_store` so that the redux store can be shared amongst multiple React components. 

## Client-Side Rendering vs. Server-Side Rendering

In most cases, you should use the `prerender: false` (default behavior) with the provided `react_component` helper method to render the React component from your Rails views. In some cases, such as when SEO is vital, or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript. The default is to use [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. If you want to maximize the perfomance of your server rendering, then you want to use React on Rails Pro which uses NodeJS to do the server rendering. See the [docs for React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki).
 
## HTML Source Code

If you open the HTML source of any web page using React on Rails, you'll see the 3 parts of React on Rails rendering:

2. The wrapper div `<div id="HelloWorld-react-component-0">` specifies the div where to place the React rendering. It encloses the server-rendered HTML for the React component. If server rendering is not used (prerender: false), then the major difference is that the HTML rendered for the React component only contains the outer div: `<div id="HelloWorld-react-component-0"/>`. The first specification of the React component is just the same.
1. A script tag containing the properties of the React component, such as the registered name and any props. A JavaScript function runs after the page loads, using this data to build and initialize your React components.
3. Additional JavaScript is placed to console-log any messages, such as server rendering errors. Note: these server side logs can be configured only to be sent to the server logs.

You can see all this on the source for [reactrails.com](https://www.reactrails.com/)

## Building the Bundles

Each time you change your client code, you will need to re-generate the bundles (the webpack-created JavaScript files included in application.js). The included example Foreman `Procfile.dev` files will take care of this for you by starting a webpack process with the watch flag. This will watch your JavaScript code files for changes. Simply run `foreman start -f Procfile.dev`. [Example](spec/dummy/Procfile.static).

On production deployments that use asset precompilation, such as Heroku deployments, React on Rails, by default, will automatically run webpack to build your JavaScript bundles. You configure the command used as `config.build_production_command` in your [config/initializers/react_on_rails.rb](./configuration.md).

You can see the source code for what gets added to your precompilation [here](https://github.com/shakacode/react_on_rails/tree/master/lib/tasks/assets.rake). For more information on this topic, see [the doc on Heroku deployment](docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).

If you have used the provided generator, these bundles will automatically be added to your `.gitignore` to prevent extraneous noise from re-generated code in your pull requests. You will want to do this manually if you do not use the provided generator.

