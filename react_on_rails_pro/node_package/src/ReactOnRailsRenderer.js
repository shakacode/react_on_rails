const bodyParser = require('body-parser');
const express = require('express');
const path = require('path');
const cluster = require('cluster');
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

  bundleWatcher(bundlePath, bundleFileName);

  const app = express();
  app.use(bodyParser.urlencoded({ extended: true }));
  app.use(bodyParser.json());

  app.post('/', (req, res) => {
    const result = eval(req.body.code);
    res.send(result);
  })

  app.listen(3000, function () {
    console.log(`Node renderer worker #${cluster.worker.id} listening on port 3000!`);
  })
}
