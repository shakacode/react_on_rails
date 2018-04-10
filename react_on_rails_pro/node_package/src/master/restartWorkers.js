'use strict';

const cluster = require('cluster');
const log = require('winston');

module.exports = function restartWorkers(delayBetweenIndividualWorkersRestarts) {
  log.debug('Started scheduled restart of workers');

  let delay = 0;
  for (const id in cluster.workers) {
    const worker = cluster.workers[id];

    const killWorker = () => {
      log.debug('Kill worker #%d', worker.id);
      worker.isScheduledRestart = true;
      worker.destroy();
    };

    setTimeout(killWorker, delay);

    delay += delayBetweenIndividualWorkersRestarts * 60000;
  }

  setTimeout(() => log.debug('Finished scheduled restart of workers'), delay);
};
