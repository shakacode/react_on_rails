## Node Server Rendering

### Warning: this is an experimental feature

The default server rendering exploits ExecJS to render react components.
Node server rendering allows you to use separate NodeJS process as a renderer. The process loads webpack-bundle.js and
then executes javascript to render the component inside its environment. The communication between rails and node occurs
via socket (`client/node/node.sock`)
 
### Getting started

To use node process just set `server_render_method = "NodeJS"` in `config/initializers/react_on_rails.rb`. To change back
to ExecJS set `server_render_method = "ExecJS"`

### Configuration

To change the name of server bundle adjust npm start script in `client/node/package.json`
