/**
 * Entry point for master process that forks workers.
 * @module master
 */

'use strict';

const os = require('os');
const cluster = require('cluster');
const log = require('winston');
const path = require('path');

const { buildConfig, getConfig } = require('./shared/configBuilder');
const restartWorkers = require('./master/restartWorkers');
// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../package.json'));

const MILLISECONDS_IN_MINUTE = 60000;

exports.run = function run(config) {
  // Store config in app state. From now it can be loaded by any module using getConfig():
  buildConfig(config);
  const {
    logLevel,
    workersCount,
    allWorkersRestartInterval,
    delayBetweenIndividualWorkerRestarts,
  } = getConfig();

  // Turn on colorized log:
  log.remove(log.transports.Console);
  log.add(log.transports.Console, { colorize: true });

  // Set log level from config:
  log.level = logLevel;
  log.info(`Renderer v${packageJson.version}, protocol v${packageJson.protocolVersion}`);

  // Count available CPUs for worker processes:
  const workerCpuCount = workersCount || os.cpus().length - 1 || 1;

  // Create a worker for each CPU except one that used for master process:
  for (let i = 0; i < workerCpuCount; i += 1) {
    cluster.fork();
  }

  // Listen for dying workers:
  cluster.on('exit', worker => {
    if (worker.isScheduledRestart) log.debug('Restarting worker #%d on schedule', worker.id);
    else log.warn('Worker #%d died :(, restarting', worker.id);
    // Replace the dead worker:
    cluster.fork();
  });

  // Schedule regular restarts of workers
  if (allWorkersRestartInterval && delayBetweenIndividualWorkerRestarts) {
    log.info(
      'Scheduled workers restarts every %d minutes (%d minutes btw each)',
      allWorkersRestartInterval,
      delayBetweenIndividualWorkerRestarts,
    );
    setInterval(
      () => restartWorkers(delayBetweenIndividualWorkerRestarts),
      allWorkersRestartInterval * MILLISECONDS_IN_MINUTE,
    );
  } else if (allWorkersRestartInterval || delayBetweenIndividualWorkerRestarts) {
    log.error(
      "Misconfiguration, please provide both 'allWorkersRestartInterval' and " +
        "'delayBetweenIndividualWorkerRestarts' to enable scheduled worker restarts",
    );
    process.exit();
  } else {
    log.info('No schedule for workers restarts');
  }
};
