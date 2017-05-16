/**
 * Entry point for master process that forks workers.
 * @module master
 */

const os = require('os');
const cluster = require('cluster');

exports.run = function run(config) {
  // Count available CPUs for worker processes:
  const workerCpuCount = config.workersCount || os.cpus().length - 1 || 1;

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
};
