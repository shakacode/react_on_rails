const cluster = require('cluster');
const worker = require('./worker');

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
  worker.run();
}
