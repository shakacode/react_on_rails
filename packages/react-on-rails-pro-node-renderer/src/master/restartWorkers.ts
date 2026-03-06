/**
 * Perform all workers restart with provided delay
 * @module master/restartWorkers
 */

import cluster from 'cluster';
import type { Worker } from 'cluster';
import log from '../shared/log.js';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils.js';

const MILLISECONDS_IN_MINUTE = 60000;
const REPLACEMENT_WORKER_LISTEN_TIMEOUT_MS = 30000;

declare module 'cluster' {
  interface Worker {
    isScheduledRestart?: boolean;
  }
}

function waitForReplacementWorkerListening(restartedWorkerId: number) {
  return new Promise<void>((resolve) => {
    let timeout: NodeJS.Timeout;
    let onListening: (replacementWorker: Worker) => void;

    function cleanup() {
      clearTimeout(timeout);
      cluster.off('listening', onListening);
    }

    onListening = (replacementWorker: Worker) => {
      cleanup();
      log.debug(
        'Replacement worker #%d is listening after restarting worker #%d',
        replacementWorker.id,
        restartedWorkerId,
      );
      resolve();
    };

    cluster.on('listening', onListening);
    timeout = setTimeout(() => {
      cleanup();
      log.warn('Timed out waiting for replacement worker after restarting worker #%d', restartedWorkerId);
      resolve();
    }, REPLACEMENT_WORKER_LISTEN_TIMEOUT_MS);
  });
}

export default async function restartWorkers(
  delayBetweenIndividualWorkerRestarts: number,
  gracefulWorkerRestartTimeout: number | undefined,
) {
  log.info('Started scheduled restart of workers');

  if (!cluster.workers) {
    throw new Error('No workers to restart');
  }
  for (const worker of Object.values(cluster.workers).filter((w) => !!w)) {
    log.debug('Kill worker #%d', worker.id);
    worker.isScheduledRestart = true;
    const replacementWorkerListening = waitForReplacementWorkerListening(worker.id);

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

      // Zero means no timeout
      if (gracefulWorkerRestartTimeout) {
        timeout = setTimeout(() => {
          log.debug('Worker #%d timed out, forcing kill it', worker.id);
          worker.destroy();
          worker.off('exit', onExit);
          resolve();
        }, gracefulWorkerRestartTimeout);
      }
    });
    // eslint-disable-next-line no-await-in-loop
    await replacementWorkerListening;
    // eslint-disable-next-line no-await-in-loop
    await new Promise((resolve) => {
      setTimeout(resolve, delayBetweenIndividualWorkerRestarts * MILLISECONDS_IN_MINUTE);
    });
  }

  log.info('Finished scheduled restart of workers');
}
