import lockfile, { Options } from 'lockfile';
import { promisify } from 'util';

import debug from './debug.js';
import log from './log.js';
import { delay, workerIdLabel } from './utils.js';

const lockfileLockAsync = promisify<string, Options>(lockfile.lock);
const lockfileUnlockAsync = promisify(lockfile.unlock);

const TEST_LOCKFILE_THREADING = false;

// See definitions here: https://github.com/npm/lockfile/blob/master/README.md#options
/*
 * A number of milliseconds to wait for locks to expire before giving up. Only used by
 * lockFile.lock. Poll for opts.wait ms. If the lock is not cleared by the time the wait expires,
 * then it returns with the original error.
 */
const LOCKFILE_WAIT = 3000;

/*
 * When using opts.wait, this is the period in ms in which it polls to check if the lock has
 * expired. Defaults to 100.
 */
const LOCKFILE_POLL_PERIOD = 300; // defaults to 100

/*
 * A number of milliseconds before locks are considered to have expired.
 */
const LOCKFILE_STALE = 20000;

/*
 * Used by lock and lockSync. Retry n number of times before giving up.
 */
const LOCKFILE_RETRIES = 45;

/*
 * Used by lock. Wait n milliseconds before retrying.
 */
const LOCKFILE_RETRY_WAIT = 300;

const lockfileOptions = {
  wait: LOCKFILE_WAIT,
  retryWait: LOCKFILE_RETRY_WAIT,
  retries: LOCKFILE_RETRIES,
  stale: LOCKFILE_STALE,
  pollPeriod: LOCKFILE_POLL_PERIOD,
};

export async function unlock(lockfileName: string) {
  debug('Worker %s: About to unlock %s', workerIdLabel(), lockfileName);
  log.info('Worker %s: About to unlock %s', workerIdLabel(), lockfileName);

  await lockfileUnlockAsync(lockfileName);
}

type LockResult = {
  lockfileName: string;
} & (
  | {
      wasLockAcquired: true;
      errorMessage: null;
    }
  | {
      wasLockAcquired: false;
      errorMessage: Error;
    }
);

export async function lock(filename: string): Promise<LockResult> {
  const lockfileName = `${filename}.lock`;
  const workerId = workerIdLabel();

  try {
    debug('Worker %s: About to request lock %s', workerId, lockfileName);
    log.info('Worker %s: About to request lock %s', workerId, lockfileName);
    await lockfileLockAsync(lockfileName, lockfileOptions);

    if (TEST_LOCKFILE_THREADING) {
      debug('Worker %i: handleNewBundleProvided sleeping 5s', workerId);
      await delay(5000);
      debug('Worker %i: handleNewBundleProvided done sleeping 5s', workerId);
    }
    debug('After acquired lock in pid', lockfileName);
  } catch (error) {
    log.info('Worker %s: Failed to acquire lock %s, error %s', workerId, lockfileName, error);
    return { lockfileName, wasLockAcquired: false, errorMessage: error as Error };
  }
  return { lockfileName, wasLockAcquired: true, errorMessage: null };
}
