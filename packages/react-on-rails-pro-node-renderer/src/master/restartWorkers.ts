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
const PRE_EXIT_REPLACEMENT_FORK_WINDOW_MS = 250;

type ReplacementWorkerWaitResult =
  | {
      status: 'ready';
      replacementWorkerId: number;
    }
  | {
      status: 'timed_out';
      reason: 'fork' | 'listening' | 'exit';
      replacementWorkerId?: number;
    };

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
  return new Promise<ReplacementWorkerWaitResult>((resolve) => {
    let timeout: NodeJS.Timeout;
    let onFork: (replacementWorker: Worker) => void;
    let onListening: (replacementWorker: Worker) => void;
    let replacementWorkerId: number | undefined;
    const preExitForkCandidates = new Map<number, number>();
    const earlyListeningWorkerIds = new Set<number>();
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
      resolve({
        status: 'ready',
        replacementWorkerId,
      });
    }

    function setReplacementWorkerId(candidateWorkerId: number) {
      replacementWorkerId = candidateWorkerId;
      if (earlyListeningWorkerIds.has(replacementWorkerId)) {
        replacementWorkerListening = true;
      }
      log.debug(
        'Observed replacement worker #%d after restarting worker #%d',
        replacementWorkerId,
        restartedWorkerId,
      );
    }

    function onRestartedWorkerExit() {
      restartedWorkerExited = true;

      if (replacementWorkerId === undefined && preExitForkCandidates.size > 0) {
        const now = Date.now();
        const recentCandidateIds = [...preExitForkCandidates.entries()]
          .filter(([, observedAtMs]) => now - observedAtMs <= PRE_EXIT_REPLACEMENT_FORK_WINDOW_MS)
          .map(([candidateWorkerId]) => candidateWorkerId);

        if (recentCandidateIds.length === 1) {
          const [candidateWorkerId] = recentCandidateIds;
          if (candidateWorkerId !== undefined) {
            setReplacementWorkerId(candidateWorkerId);
          }
        } else if (recentCandidateIds.length > 1) {
          log.warn(
            'Observed multiple replacement candidates while restarting worker #%d; waiting for a post-exit fork event',
            restartedWorkerId,
          );
        }
      }

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

      if (!restartedWorkerExited) {
        preExitForkCandidates.set(replacementWorker.id, Date.now());
        return;
      }

      setReplacementWorkerId(replacementWorker.id);

      resolveIfReady();
    };

    onListening = (replacementWorker: Worker) => {
      if (replacementWorkerId === undefined) {
        earlyListeningWorkerIds.add(replacementWorker.id);
        return;
      }
      if (replacementWorker.id !== replacementWorkerId) {
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
      let timeoutResult: ReplacementWorkerWaitResult;
      if (replacementWorkerId === undefined) {
        timeoutResult = {
          status: 'timed_out',
          reason: 'fork',
        };
      } else if (!replacementWorkerListening) {
        timeoutResult = {
          status: 'timed_out',
          reason: 'listening',
          replacementWorkerId,
        };
      } else {
        timeoutResult = {
          status: 'timed_out',
          reason: 'exit',
          replacementWorkerId,
        };
      }
      resolve(timeoutResult);
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
    const replacementWorkerWaitResult = await replacementWorkerListening;
    if (replacementWorkerWaitResult.status === 'timed_out') {
      if (replacementWorkerWaitResult.reason === 'fork') {
        log.warn('Timed out waiting for replacement worker fork after restarting worker #%d', worker.id);
      } else if (replacementWorkerWaitResult.reason === 'listening') {
        log.warn(
          'Timed out waiting for replacement worker #%d to listen after restarting worker #%d',
          replacementWorkerWaitResult.replacementWorkerId,
          worker.id,
        );
      } else {
        log.warn(
          'Timed out waiting for worker #%d exit after replacement worker #%d started listening',
          worker.id,
          replacementWorkerWaitResult.replacementWorkerId,
        );
      }
    }
    // eslint-disable-next-line no-await-in-loop
    await new Promise((resolve) => {
      setTimeout(resolve, delayBetweenIndividualWorkerRestarts * MILLISECONDS_IN_MINUTE);
    });
  }

  log.info('Finished scheduled restart of workers');
}
