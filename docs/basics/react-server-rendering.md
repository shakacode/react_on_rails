# React Server Rendering

See also [Client vs. Server Rendering](./client-vs-server-rendering.md)

## What is Server Rendering?

Here's a [decent article to introduce you to server rendering](https://medium.freecodecamp.org/server-side-rendering-your-react-app-in-three-simple-steps-7a82b95db82e). Note, React on Rails takes care of calling the methods in [ReactDOMServer](https://reactjs.org/docs/react-dom-server.html).

During the Rails rendering of HTML per a browser request, the Rails server will execute some JavaScript to create a string of HTML used for React server rendering. This resulting HTML is placed with in your Rails view's output.

The default JavaScript interpretter is [ExecJS](https://github.com/rails/execjs). If you want to maximize the perfomance of your server rendering, then you want to use React on Rails Pro which uses NodeJS to do the server rendering. See the [docs for React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki).

See [this note](docs/outdated/how-react-on-rails-works.md#client-side-rendering-vs-server-side-rendering)


## How do you do Server Rendering with React on Rails?
1. The `react_component` view helper method provides the `prerender:` option to switch on or off server rendering.
1. Configure your Webpack setup to create a different server bundle per your needs. While you may reuse the same bundle as for client rendering, this is not common in larger apps for many reasons, such as as code splitting, handling CSS and images, different code paths for React Router on the server vs. client, etc.
1. You need to configure `config.server_bundle_js_file = "my-server-bundle.js"` in your `config/initializers/react_on_rails.rb`

## Do you need server rendering?

Server rendering is used for either SEO or performance reasons.

## Considerations for what code can run on in server rendering

1. Never access `window`. Animations, globals on window, etc. just don't make sense when you're trying to run some JavaScript code to output a string of HTML.
2. JavaScript calls to `setTimeout`, `setInterval`, and `clearInterval` similarly don't make sense when server rendering.
3. Promises don't work when server rendering. Anything to be done in a promise will never complete. This includes concepts such as asynchronous code loading and AJAX calls. If you want to do server rendering with asynchronous calls, [get in touch](mailto:justin@shakacode.com) as we're working on a Node renderer that handles asynchronous calls.
