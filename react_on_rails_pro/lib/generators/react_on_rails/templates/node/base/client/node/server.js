const net = require('net');
const fs = require('fs');

const bundlePath = '../../app/assets/webpack/';
let bundleFileName = 'server-bundle.js';

let currentArg;

class Handler {
  constructor() {
    this.queue = [];
    this.initialized = false;
  }

  initialize() {
    console.log(`Processing ${this.queue.length} pending requests`);
    let callback;

    // eslint-disable-next-line no-cond-assign
    while (callback = this.queue.pop()) {
      callback();
    }

    this.initialized = true;
  }

  handle(connection) {
    const callback = () => {
      const terminator = '\r\n\0';
      let request = '';
      connection.setEncoding('utf8');
      connection.on('data', (data) => {
        console.log(`Processing chunk: ${data}`);
        request += data;
        if (data.slice(-terminator.length) === terminator) {
          request = request.slice(0, -terminator.length);

          // eslint-disable-next-line no-eval
          const response = eval(request);
          connection.write(`${response}${terminator}`);
          request = '';
        }
      });
    };

    if (this.initialized) {
      callback();
    } else {
      this.queue.push(callback);
    }
  }
}

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

function loadBundle() {
  if (handler.initialized) {
    console.log('Reloading server bundle must be implemented by restarting the node process!');
    return;
  }

  /* eslint-disable */
  require(bundlePath + bundleFileName);
  /* eslint-enable */
  console.log(`Loaded server bundle: ${bundlePath}${bundleFileName}`);
  handler.initialize();
}

try {
  fs.mkdirSync(bundlePath);
} catch (e) {
  if (e.code !== 'EEXIST') {
    throw e;
  } else {
    loadBundle();
  }
}

fs.watchFile(bundlePath + bundleFileName, (curr) => {
  if (curr && curr.blocks && curr.blocks > 0) {
    loadBundle();
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
