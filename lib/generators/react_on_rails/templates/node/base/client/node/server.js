const net = require('net');
const fs = require('fs');

const bundlePath = '../../app/assets/webpack/';
let bundleFileName = 'webpack-bundle.js';

let currentArg;

function Handler() {
  this.queue = [];
  this.initialized = false;
}

Handler.prototype.handle = (connection) => {
  const callback = () => {
    connection.setEncoding('utf8');
    connection.on('data', (data) => {
      console.log(`Processing request: ${data}`);

      // eslint-disable-next-line no-eval
      const result = eval(data);
      connection.write(result);
    });
  };

  if (this.initialized) {
    callback();
  } else {
    this.queue.push(callback);
  }
};

Handler.prototype.initialize = () => {
  console.log(`Processing ${this.queue.length} pending requests`);
  let callback;

  // eslint-disable-next-line no-cond-assign
  while (callback = this.queue.pop()) {
    callback();
  }

  this.initialized = true;
};

const handler = new Handler();

process.argv.forEach((val) => {
  if (val[0] === '-') {
    currentArg = val.slice(1);
    return;
  }

  if (currentArg === 's') {
    bundleFileName = val;
  }
});

try {
  fs.mkdirSync(bundlePath);
} catch (e) {
  if (e.code !== 'EEXIST') throw e;
}

fs.watchFile(bundlePath + bundleFileName, (curr) => {
  if (curr && curr.blocks && curr.blocks > 0) {
    if (handler.initialized) {
      console.log('Reloading server bundle must be implemented by restarting the node process!');
      return;
    }

    // eslint-disable-next-line global-require
    require(bundlePath + bundleFileName);
    console.log(`Loaded server bundle: ${bundlePath + bundleFileName}`);
    handler.initialize();
  }
});

const unixServer = net.createServer((connection) => {
  handler.handle(connection);
});

unixServer.listen('node.sock');

process.on('SIGINT', () => {
  unixServer.close();
  process.exit();
});
