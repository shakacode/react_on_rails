/**
 * Perform all workers restart with provided delay.
 *
 * Uses a "fork-first" strategy: a replacement worker is forked and confirmed
 * listening before the old worker is shut down. This guarantees the pool never
 * drops below its configured size during a rolling restart. If a replacement
 * fails to start after all retry attempts, the restart cycle aborts to
 * preserve the remaining healthy workers.
 *
 * Note: the pool is transiently one worker above its configured size while
 * the old worker is draining its active requests. This is by design — the
 * brief memory overhead is preferable to dropping below capacity.
 *
 * @module master/restartWorkers
 */

import cluster from 'cluster';
import type { Worker } from 'cluster';
import { once } from 'events';
import log from '../shared/log.js';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils.js';

const MILLISECONDS_IN_MINUTE = 60000;
const MILLISECONDS_IN_SECOND = 1000;
const DEFAULT_REPLACEMENT_LISTEN_TIMEOUT_MS = 30000;
const MAX_REPLACEMENT_RETRIES = 2;

declare module 'cluster' {
  interface Worker {
    isScheduledRestart?: boolean;
    /**
     * Set on replacement workers forked by the rolling restart loop.
     * Prevents the exit handler in master.ts from auto-forking when a
     * replacement crashes during bootstrap — the restart loop handles
     * retries itself.
     */
    isRollingRestartReplacement?: boolean;
  }
}

/**
 * Fork a replacement worker and wait for it to start listening.
 * Returns the replacement Worker on success, or null if it failed to start
 * (crashed, errored, or timed out).
 */
async function forkAndWaitForListening(timeoutMs: number): Promise<Worker | null> {
  const replacement = cluster.fork();
  replacement.isRollingRestartReplacement = true;
  const replacementId = replacement.id;
  log.debug('Forked replacement worker #%d, waiting for it to start listening', replacementId);

  let timeoutHandle: NodeJS.Timeout | undefined;

  let result: 'ready' | 'crashed' | 'timeout';
  try {
    result = await Promise.race([
      once(replacement, 'listening').then(() => 'ready' as const),
      once(replacement, 'exit').then(() => 'crashed' as const),
      new Promise<'timeout'>((resolve) => {
        timeoutHandle = setTimeout(() => resolve('timeout'), timeoutMs);
      }),
    ]);
  } catch {
    // events.once() rejects if the emitter fires an 'error' event before the
    // awaited event. Treat this the same as a crash.
    result = 'crashed';
  }

  clearTimeout(timeoutHandle);

  if (result === 'ready') {
    replacement.isRollingRestartReplacement = false;
    log.info('Replacement worker #%d is listening', replacementId);
    return replacement;
  }

  if (result === 'crashed') {
    log.error('Replacement worker #%d crashed before it started listening', replacementId);
  } else {
    log.error('Replacement worker #%d timed out waiting to start listening', replacementId);
    replacement.destroy();
  }

  return null;
}

/**
 * Wait for a worker to exit after sending it a shutdown message.
 * If the worker does not exit within the timeout, force-kill it.
 *
 * When gracefulTimeoutSeconds is undefined or 0, there is no force-kill
 * backstop — the promise resolves only when the worker exits on its own.
 * Callers should verify the worker is still alive before calling this to
 * avoid waiting on a worker that already exited.
 */
function waitForWorkerExit(worker: Worker, gracefulTimeoutSeconds: number | undefined): Promise<void> {
  return new Promise<void>((resolve) => {
    let timeout: NodeJS.Timeout;

    const onExit = () => {
      clearTimeout(timeout);
      resolve();
    };
    worker.once('exit', onExit);

    if (gracefulTimeoutSeconds != null && gracefulTimeoutSeconds > 0) {
      timeout = setTimeout(() => {
        log.debug('Worker #%d timed out during graceful shutdown, force-killing', worker.id);
        worker.destroy();
        worker.off('exit', onExit);
        resolve();
      }, gracefulTimeoutSeconds * MILLISECONDS_IN_SECOND);
    }
  });
}

export default async function restartWorkers(
  delayBetweenIndividualWorkerRestarts: number,
  gracefulWorkerRestartTimeout: number | undefined,
  replacementWorkerListenTimeout: number | undefined,
) {
  log.info('Started scheduled restart of workers');

  if (!cluster.workers) {
    throw new Error('No workers to restart');
  }

  // Snapshot the current workers so that replacements forked during the loop
  // are not included in the iteration.
  const workersToRestart = Object.values(cluster.workers).filter((w): w is Worker => !!w);

  // Convert seconds to milliseconds, falling back to the default if not configured.
  const replacementListenTimeoutMs =
    replacementWorkerListenTimeout != null && replacementWorkerListenTimeout > 0
      ? replacementWorkerListenTimeout * MILLISECONDS_IN_SECOND
      : DEFAULT_REPLACEMENT_LISTEN_TIMEOUT_MS;

  for (const worker of workersToRestart) {
    // Skip workers that exited unexpectedly before their turn in the loop.
    if (!cluster.workers?.[worker.id]) {
      log.warn('Worker #%d already exited before its scheduled restart turn, skipping', worker.id);
      // eslint-disable-next-line no-continue
      continue;
    }

    log.debug('Restarting worker #%d', worker.id);

    // Fork replacement first, retrying up to MAX_REPLACEMENT_RETRIES times.
    let replacement: Worker | null = null;
    for (let attempt = 1; attempt <= MAX_REPLACEMENT_RETRIES + 1; attempt += 1) {
      if (attempt > 1) {
        log.warn(
          'Retry %d/%d: forking replacement for worker #%d',
          attempt - 1,
          MAX_REPLACEMENT_RETRIES,
          worker.id,
        );
      }

      // eslint-disable-next-line no-await-in-loop
      replacement = await forkAndWaitForListening(replacementListenTimeoutMs);
      if (replacement) {
        break;
      }
    }

    if (!replacement) {
      log.error(
        'All %d attempts to fork a replacement for worker #%d failed. Aborting rolling restart to preserve remaining healthy workers.',
        MAX_REPLACEMENT_RETRIES + 1,
        worker.id,
      );
      break;
    }

    // Re-check liveness: the old worker may have died while we were waiting
    // for the replacement. If so, skip the shutdown — it's already gone,
    // and the replacement we just forked covers the slot.
    if (!cluster.workers?.[worker.id]) {
      log.warn('Worker #%d exited while forking its replacement, skipping shutdown', worker.id);
      // eslint-disable-next-line no-continue
      continue;
    }

    // Replacement is confirmed listening — now safe to shut down the old worker.
    worker.isScheduledRestart = true;
    worker.send(SHUTDOWN_WORKER_MESSAGE);

    // eslint-disable-next-line no-await-in-loop
    await waitForWorkerExit(worker, gracefulWorkerRestartTimeout);

    // eslint-disable-next-line no-await-in-loop
    await new Promise((resolve) => {
      setTimeout(resolve, delayBetweenIndividualWorkerRestarts * MILLISECONDS_IN_MINUTE);
    });
  }

  log.info('Finished scheduled restart of workers');
}
