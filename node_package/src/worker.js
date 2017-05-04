const cluster = require('cluster');
const express = require('express');
const bodyParser = require('body-parser');
const { runInVM } = require('./worker/vm');
const configBuilder = require('./worker/configBuilder');
const bundleWatcher = require('./worker/bundleWatcher');

exports.run = function run() {
  const { bundlePath, bundleFileName, port } = configBuilder();
  bundleWatcher(bundlePath, bundleFileName);

  const app = express();
  app.use(bodyParser.urlencoded({ extended: true }));
  app.use(bodyParser.json());

  app.post('/', (req, res) => {
    const result = runInVM(req.body.code);
    res.send(result);
  });

  app.listen(port, () => {
    console.log(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
  });
}
