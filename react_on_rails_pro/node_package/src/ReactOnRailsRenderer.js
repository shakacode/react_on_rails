const bodyParser = require('body-parser');
const express = require('express');
const cluster = require('cluster');
const configBuilder = require('./configBuilder');
const bundleWatcher = require('./bundleWatcher');

if (cluster.isMaster) {
  // Count available CPUs for worker processes:
  const workerCpuCount = require('os').cpus().length - 1 || 1;

  // Create a worker for each CPU except one that used for master process:
  for (let i = 0; i < workerCpuCount; i += 1) {
    cluster.fork();
  }

  // Listen for dying workers:
  cluster.on('exit', (worker) => {
    // Replace the dead worker:
    console.log('Worker %d died :(', worker.id);
    cluster.fork();
  });
} else {
  const { buildVM, runInVM } = require('./context');

  const { bundlePath, bundleFileName, port } = configBuilder();
  bundleWatcher(bundlePath, bundleFileName);
  buildVM(bundlePath, bundleFileName);

  const app = express();
  app.use(bodyParser.urlencoded({ extended: true }));
  app.use(bodyParser.json());

  app.post('/', (req, res) => {
    //console.log(req.body.code)
    //console.log('zzzzzzzzzzzzzz', vm.run('module.exports = 1'));
    const result = runInVM(req.body.code);
    res.send(result);
  });

  app.listen(port, () => {
    console.log(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
  });
}
