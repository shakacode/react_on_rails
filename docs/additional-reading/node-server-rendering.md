## Node Server Rendering

### Warning: this is an experimental feature

The default server rendering exploits ExecJS to render react components.
Node server rendering allows you to use separate NodeJS process as a renderer. The process loads your configured server_bundle_js file and
then executes javascript to render the component inside its environment. The communication between rails and node occurs
via socket (`client/node/node.sock`)

### Getting started

To use node process just set `server_render_method = "NodeJS"` in `config/initializers/react_on_rails.rb`. To change back
to ExecJS set `server_render_method = "ExecJS"`

### Configuration

You need to configure the name of the server bundle in two places:

1. JavaScript: Change the name of server bundle adjust npm start script in `client/node/package.json`
2. Ruby: The configured server bundle file is defined in `config/react_on_rails.rb`, and you'll have a webpack file that creates this. You maybe using the same file for client rendering.

```ruby
  # This is the file used for server rendering of React when using `(prerender: true)`
  # If you are never using server rendering, you may set this to "".
  # If you are using the same file for client and server rendering, having this set probably does
  # not affect performance.
  config.server_bundle_js_file = "webpack-bundle.js"
``` 
 

