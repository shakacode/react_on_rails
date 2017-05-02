const fs = require('fs');
var bodyParser = require('body-parser');
var express = require('express');
var path = require('path');


const bundlePath = path.resolve(__dirname, '../../spec/dummy/app/assets/webpack/');
let bundleFileName = 'server-bundle.js';
let currentArg;

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
  /* eslint-disable */
  require(bundlePath + '/' + bundleFileName);
  /* eslint-enable */
  console.log(`Loaded server bundle: ${bundlePath}${bundleFileName}`);
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

var app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.post('/', function (req, res) {
  const result = eval(req.body.code);
  res.send(result);
})

app.listen(3000, function () {
  console.log('Node renderer listening on port 3000!')
})

process.on('SIGINT', () => {
  unixServer.close();
  process.exit();
});
