/**
 * Perform all workers restart with provided delay
 * @module master/restartWorkers
 */

import cluster from 'cluster';
import log from '../shared/log';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils';

const MILLISECONDS_IN_MINUTE = 60000;

declare module 'cluster' {
  interface Worker {
    isScheduledRestart?: boolean;
  }
}

export = async function restartWorkers(delayBetweenIndividualWorkerRestarts: number) {
  log.info('Started scheduled restart of workers');

  if (!cluster.workers) {
    throw new Error('No workers to restart');
  }
  for (const worker of Object.values(cluster.workers)) {
    if (!worker) return;
    log.debug('Kill worker #%d', worker.id);
    worker.isScheduledRestart = true;

    worker.send(SHUTDOWN_WORKER_MESSAGE);

    // It's inteded to restart worker in sequence, it shouldn't happens in parallel
    // eslint-disable-next-line no-await-in-loop
    await new Promise<void>((resolve) => {
      let timeout: NodeJS.Timeout;

      const onExit = () => {
        clearTimeout(timeout);
        resolve();
      };
      worker.on('exit', onExit);

      timeout = setTimeout(() => {
        log.debug('Worker #%d timed out, forcing kill it', worker.id);
        worker.destroy();
        worker.off('exit', onExit);
        resolve();
      }, 100_000);
    });
    // eslint-disable-next-line no-await-in-loop
    await new Promise((resolve) => {
      setTimeout(resolve, delayBetweenIndividualWorkerRestarts * MILLISECONDS_IN_MINUTE);
    });
  }

  log.info('Finished scheduled restart of workers');
};
