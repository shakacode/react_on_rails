# Node.js for Server Rendering

Node.js can be used as the backend for server-side rendering instead of [execJS](https://github.com/rails/execjs). Before you try this, consider the tradeoff of extra complexity with your deployments versus *potential* performance gains. We've found that using ExecJS with [mini_racer](https://github.com/discourse/mini_racer) to be "fast enough" so far. That being said, we've heard of other large websites using Node.js for better server rendering performance.

If you're serious about this comparing Node.js versus execJS/mini_racer, then [get in touch](mailto:justin@shakacode.com)! We can definitely collaborate with you on refining this solution. However, please try out these instructions first.

## Setup of React on Rails with Node.js Server Rendering
**Warning: this is an experimental feature.**

* Every time the webpack bundle changes, you have to restart the server yourself.

To do this you need to add a few files and then configure react_on_rails to use NodeJS. Here are the relevant files to add.

Node server rendering allows you to use separate NodeJS process as a renderer. The process loads your configured server_bundle_js file and then executes javascript to render the component inside its environment. The communication between rails and node occurs
via a socket (`client/node/node.sock`)

### Getting started

### Configuration

#### Update the React on Rails Initializer

To use node process just set `server_render_method = "NodeJS"` in `config/initializers/react_on_rails.rb`. To change back
to ExecJS set `server_render_method = "ExecJS"`

```ruby
# app/config/initializers/react_on_rails.rb
config.server_render_method = "NodeJS"
```

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

And in `client/node/package.json`

```javascript
// client/node/package.json
{
    "name": "react_on_rails_node",
    "version": "0.0.0",
    "private": true,
    "scripts": {
        "start": "node ./server.js -s webpack-bundle.js"
    },
    "dependencies": {
    }
}
```

And you'll need this file: `client/node/server.js`

```javascript
// client/node/server.js
var net = require('net');
var fs = require('fs');

var bundlePath = '../../app/assets/webpack/';
var bundleFileName = 'webpack-bundle.js';

var currentArg;

function Handler() {
  this.queue = [];
  this.initialized = false;
}

Handler.prototype.handle = function (connection) {
  var callback = function () {
    connection.setEncoding('utf8');
    connection.on('data', (data)=> {
      console.log('Processing request: ' + data);
      var result = eval(data);
      connection.write(result);
    });
  };

  if (this.initialized) {
    callback();
  } else {
    this.queue.push(callback);
  }
};

Handler.prototype.initialize = function () {
  console.log('Processing ' + this.queue.length + ' pending requests');
  var callback;
  while (callback = this.queue.pop()) {
    callback();
  }

  this.initialized = true;
};

var handler = new Handler();

process.argv.forEach((val) => {
  if (val[0] == '-') {
    currentArg = val.slice(1);
    return;
  }

  if (currentArg == 's') {
    bundleFileName = val;
  }
});

try {
  fs.mkdirSync(bundlePath);
} catch (e) {
  if (e.code != 'EEXIST') throw e;
}

fs.watchFile(bundlePath + bundleFileName, (curr) => {
  if (curr && curr.blocks && curr.blocks > 0) {
    if (handler.initialized) {
      console.log('Reloading server bundle must be implemented by restarting the node process!');
      return;
    }

    require(bundlePath + bundleFileName);
    console.log('Loaded server bundle: ' + bundlePath + bundleFileName);
    handler.initialize();
  }
});

var unixServer = net.createServer(function (connection) {
  handler.handle(connection);
});

unixServer.listen('node.sock');

process.on('SIGINT', () => {
  unixServer.close();
  process.exit();
});

```

