var net = require('net');
var fs = require('fs');

var bundlePath = '../../app/assets/webpack';
var bundleFileName = 'server-bundle.js';

var currentArg;
process.argv.forEach((val) => {
  if (val[0] == '-') {
    currentArg = val.slice(1);
    return;
  }

  if (currentArg == 'b') {
    bundleFileName = val;
  }

});

if (!fs.existsSync(bundlePath)) {
  fs.mkdirSync(bundlePath);
}

fs.watch(bundlePath, (event, filename) => {
  if (filename === bundleFileName) {
    require(bundlePath + '/' + bundleFileName);
  }
});

var unixServer = net.createServer(function (connection) {
  connection.setEncoding('utf8');
  connection.on('data', (data)=> {
    var result = eval(data);
    connection.write(result);
  });
});

unixServer.listen('node.sock');

process.on('SIGINT', () => {
  unixServer.close();
  process.exit();
});
