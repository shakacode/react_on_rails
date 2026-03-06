/**
 * Perform all workers restart with provided delay
 * @module master/restartWorkers
 */

import cluster from 'cluster';
import type { Worker } from 'cluster';
import log from '../shared/log.js';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils.js';

const MILLISECONDS_IN_MINUTE = 60000;
const DEFAULT_REPLACEMENT_WORKER_LISTEN_TIMEOUT_MS = 30000;

declare module 'cluster' {
  interface Worker {
    isScheduledRestart?: boolean;
  }
}

function waitForReplacementWorkerListening(
  restartedWorker: Worker,
  knownWorkerIds: Set<number>,
  replacementWorkerListenTimeoutMs: number,
) {
  const restartedWorkerId = restartedWorker.id;
  return new Promise<void>((resolve) => {
    let timeout: NodeJS.Timeout;
    let onFork: (replacementWorker: Worker) => void;
    let onListening: (replacementWorker: Worker) => void;
    let replacementWorkerId: number | undefined;
    let replacementWorkerListening = false;
    let restartedWorkerExited = false;
    let resolved = false;
    let cleanup: () => void;

    function resolveIfReady() {
      if (resolved) {
        return;
      }

      if (!restartedWorkerExited || replacementWorkerId === undefined || !replacementWorkerListening) {
        return;
      }

      resolved = true;
      cleanup();
      log.debug(
        'Replacement worker #%d is listening after restarting worker #%d',
        replacementWorkerId,
        restartedWorkerId,
      );
      resolve();
    }

    function onRestartedWorkerExit() {
      restartedWorkerExited = true;
      resolveIfReady();
    }

    cleanup = () => {
      clearTimeout(timeout);
      cluster.off('fork', onFork);
      cluster.off('listening', onListening);
      restartedWorker.off('exit', onRestartedWorkerExit);
    };

    onFork = (replacementWorker: Worker) => {
      if (knownWorkerIds.has(replacementWorker.id)) {
        return;
      }

      if (replacementWorkerId !== undefined) {
        return;
      }

      replacementWorkerId = replacementWorker.id;
      log.debug(
        'Observed replacement worker #%d after restarting worker #%d',
        replacementWorkerId,
        restartedWorkerId,
      );

      resolveIfReady();
    };

    onListening = (replacementWorker: Worker) => {
      if (replacementWorkerId === undefined || replacementWorker.id !== replacementWorkerId) {
        return;
      }

      replacementWorkerListening = true;
      resolveIfReady();
    };

    restartedWorker.on('exit', onRestartedWorkerExit);
    cluster.on('fork', onFork);
    cluster.on('listening', onListening);
    timeout = setTimeout(() => {
      cleanup();
      if (replacementWorkerId === undefined) {
        log.warn(
          'Timed out waiting for replacement worker fork after restarting worker #%d',
          restartedWorkerId,
        );
      } else if (!replacementWorkerListening) {
        log.warn(
          'Timed out waiting for replacement worker #%d to listen after restarting worker #%d',
          replacementWorkerId,
          restartedWorkerId,
        );
      } else {
        log.warn(
          'Timed out waiting for worker #%d exit after replacement worker #%d started listening',
          restartedWorkerId,
          replacementWorkerId,
        );
      }
      resolve();
    }, replacementWorkerListenTimeoutMs);
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
    const replacementWorkerListenTimeoutMs = Math.max(
      DEFAULT_REPLACEMENT_WORKER_LISTEN_TIMEOUT_MS,
      gracefulWorkerRestartTimeout ?? 0,
    );
    const knownWorkerIds = new Set(
      Object.values(cluster.workers).flatMap((currentWorker) => (currentWorker ? [currentWorker.id] : [])),
    );
    const replacementWorkerListening = waitForReplacementWorkerListening(
      worker,
      knownWorkerIds,
      replacementWorkerListenTimeoutMs,
    );

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
