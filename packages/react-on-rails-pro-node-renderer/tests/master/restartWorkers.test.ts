import { EventEmitter } from 'events';
import cluster from 'cluster';
import restartWorkers from '../../src/master/restartWorkers';
import log from '../../src/shared/log';
import { SHUTDOWN_WORKER_MESSAGE } from '../../src/shared/utils';

jest.mock('cluster', () => {
  const { EventEmitter } = require('events');
  const mockedCluster = new EventEmitter();
  mockedCluster.workers = {};
  mockedCluster.fork = jest.fn();
  return {
    __esModule: true,
    default: mockedCluster,
  };
});

jest.mock('../../src/shared/log', () => ({
  __esModule: true,
  default: {
    info: jest.fn(),
    debug: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

class MockWorker extends EventEmitter {
  id: number;

  isScheduledRestart?: boolean;

  send = jest.fn();

  destroy = jest.fn();

  constructor(id: number) {
    super();
    this.id = id;
  }
}

const mockedCluster = cluster as unknown as EventEmitter & {
  workers: Record<string, MockWorker>;
  fork: jest.Mock;
};

describe('restartWorkers', () => {
  let nextWorkerId: number;

  beforeEach(() => {
    mockedCluster.workers = {};
    nextWorkerId = 10;
    jest.clearAllMocks();
  });

  /** Create a mock worker that auto-exits when it receives the shutdown message. */
  function autoExitOnShutdown(worker: MockWorker) {
    worker.send.mockImplementation((msg: string) => {
      if (msg === SHUTDOWN_WORKER_MESSAGE) {
        process.nextTick(() => worker.emit('exit'));
      }
    });
  }

  /** Configure cluster.fork to return workers that auto-emit 'listening'. */
  function forkAlwaysSucceeds() {
    mockedCluster.fork.mockImplementation(() => {
      const replacement = new MockWorker(nextWorkerId++);
      process.nextTick(() => replacement.emit('listening'));
      return replacement;
    });
  }

  /** Configure cluster.fork to return workers that always crash. */
  function forkAlwaysCrashes() {
    mockedCluster.fork.mockImplementation(() => {
      const replacement = new MockWorker(nextWorkerId++);
      process.nextTick(() => replacement.emit('exit', 1, null));
      return replacement;
    });
  }

  test('forks replacement before shutting down old worker (fork-first strategy)', async () => {
    const worker1 = new MockWorker(1);
    const worker2 = new MockWorker(2);
    autoExitOnShutdown(worker1);
    autoExitOnShutdown(worker2);
    mockedCluster.workers = { '1': worker1, '2': worker2 };

    forkAlwaysSucceeds();

    await restartWorkers(0, undefined, undefined);

    // Both workers were shut down
    expect(worker1.send).toHaveBeenCalledWith(SHUTDOWN_WORKER_MESSAGE);
    expect(worker2.send).toHaveBeenCalledWith(SHUTDOWN_WORKER_MESSAGE);
    // Both were marked as scheduled restart
    expect(worker1.isScheduledRestart).toBe(true);
    expect(worker2.isScheduledRestart).toBe(true);
    // Two replacements were forked (one per worker)
    expect(mockedCluster.fork).toHaveBeenCalledTimes(2);
    // No warnings or errors
    expect(log.warn).not.toHaveBeenCalled();
    expect(log.error).not.toHaveBeenCalled();
  });

  test('replacement is forked before old worker receives shutdown', async () => {
    const worker1 = new MockWorker(1);
    mockedCluster.workers = { '1': worker1 };

    const shutdownOrder: string[] = [];

    mockedCluster.fork.mockImplementation(() => {
      shutdownOrder.push('fork');
      const replacement = new MockWorker(nextWorkerId++);
      process.nextTick(() => replacement.emit('listening'));
      return replacement;
    });

    worker1.send.mockImplementation((msg: string) => {
      if (msg === SHUTDOWN_WORKER_MESSAGE) {
        shutdownOrder.push('shutdown');
        process.nextTick(() => worker1.emit('exit'));
      }
    });

    await restartWorkers(0, undefined, undefined);

    // Fork must happen before shutdown
    expect(shutdownOrder).toEqual(['fork', 'shutdown']);
  });

  test('retries forking replacement when it crashes before listening', async () => {
    const worker1 = new MockWorker(1);
    autoExitOnShutdown(worker1);
    mockedCluster.workers = { '1': worker1 };

    let forkAttempt = 0;
    mockedCluster.fork.mockImplementation(() => {
      forkAttempt += 1;
      const replacement = new MockWorker(nextWorkerId++);
      if (forkAttempt === 1) {
        // First attempt crashes
        process.nextTick(() => replacement.emit('exit', 1, null));
      } else {
        // Second attempt succeeds
        process.nextTick(() => replacement.emit('listening'));
      }
      return replacement;
    });

    await restartWorkers(0, undefined, undefined);

    // Two fork attempts (1 failed + 1 succeeded)
    expect(mockedCluster.fork).toHaveBeenCalledTimes(2);
    // Old worker was eventually shut down
    expect(worker1.send).toHaveBeenCalledWith(SHUTDOWN_WORKER_MESSAGE);
    // Retry was logged
    expect(log.warn).toHaveBeenCalledWith('Retry %d/%d: forking replacement for worker #%d', 1, 2, 1);
  });

  test('aborts rolling restart after all retry attempts fail', async () => {
    const worker1 = new MockWorker(1);
    const worker2 = new MockWorker(2);
    mockedCluster.workers = { '1': worker1, '2': worker2 };

    forkAlwaysCrashes();

    await restartWorkers(0, undefined, undefined);

    // 3 fork attempts for worker #1 (1 initial + 2 retries), then abort
    expect(mockedCluster.fork).toHaveBeenCalledTimes(3);
    // Neither old worker was shut down
    expect(worker1.send).not.toHaveBeenCalled();
    expect(worker2.send).not.toHaveBeenCalled();
    // Abort was logged
    expect(log.error).toHaveBeenCalledWith(expect.stringContaining('Aborting rolling restart'), 3, 1);
  });

  test('aborts and preserves remaining workers when replacement times out', async () => {
    jest.useFakeTimers({ doNotFake: ['nextTick'] });
    try {
      const worker1 = new MockWorker(1);
      const worker2 = new MockWorker(2);
      mockedCluster.workers = { '1': worker1, '2': worker2 };

      // Fork returns workers that never emit listening or exit (simulates hang)
      mockedCluster.fork.mockImplementation(() => new MockWorker(nextWorkerId++));

      const restartPromise = restartWorkers(0, undefined, undefined);

      // Advance through all 3 timeout periods (30s each)
      for (let i = 0; i < 3; i += 1) {
        jest.advanceTimersByTime(30000);
        // Let microtasks propagate
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();
      }

      jest.runOnlyPendingTimers();
      await Promise.resolve();
      await restartPromise;

      // Neither worker was shut down
      expect(worker1.send).not.toHaveBeenCalled();
      expect(worker2.send).not.toHaveBeenCalled();
      // 3 fork attempts for worker #1, then abort
      expect(mockedCluster.fork).toHaveBeenCalledTimes(3);
    } finally {
      jest.useRealTimers();
    }
  });

  test('force-kills old worker if it does not exit within graceful timeout', async () => {
    jest.useFakeTimers({ doNotFake: ['nextTick'] });
    try {
      const worker1 = new MockWorker(1);
      mockedCluster.workers = { '1': worker1 };

      // Worker does NOT auto-exit on shutdown (simulates hung worker)
      // But destroy() triggers exit
      worker1.destroy.mockImplementation(() => {
        process.nextTick(() => worker1.emit('exit'));
      });

      forkAlwaysSucceeds();

      const restartPromise = restartWorkers(0, 5000, undefined);

      // Let fork + listening happen
      await new Promise((resolve) => process.nextTick(resolve));
      await new Promise((resolve) => process.nextTick(resolve));

      // Old worker has received shutdown but won't exit gracefully
      expect(worker1.send).toHaveBeenCalledWith(SHUTDOWN_WORKER_MESSAGE);

      // Advance past the graceful timeout
      jest.advanceTimersByTime(5000);

      // Let destroy → exit propagate
      await new Promise((resolve) => process.nextTick(resolve));
      await new Promise((resolve) => process.nextTick(resolve));

      expect(worker1.destroy).toHaveBeenCalled();

      // Let delay timer fire
      jest.runOnlyPendingTimers();
      await Promise.resolve();

      await restartPromise;
    } finally {
      jest.useRealTimers();
    }
  });

  test('aborts partway through: only restarts workers before failure', async () => {
    const worker1 = new MockWorker(1);
    const worker2 = new MockWorker(2);
    const worker3 = new MockWorker(3);
    autoExitOnShutdown(worker1);
    mockedCluster.workers = { '1': worker1, '2': worker2, '3': worker3 };

    let workerIndex = 0;
    mockedCluster.fork.mockImplementation(() => {
      workerIndex += 1;
      const replacement = new MockWorker(nextWorkerId++);
      if (workerIndex <= 1) {
        // First replacement succeeds
        process.nextTick(() => replacement.emit('listening'));
      } else {
        // All subsequent replacements crash
        process.nextTick(() => replacement.emit('exit', 1, null));
      }
      return replacement;
    });

    await restartWorkers(0, undefined, undefined);

    // Worker #1 was restarted successfully
    expect(worker1.send).toHaveBeenCalledWith(SHUTDOWN_WORKER_MESSAGE);
    // Worker #2 and #3 were preserved (replacement failed, loop aborted)
    expect(worker2.send).not.toHaveBeenCalled();
    expect(worker3.send).not.toHaveBeenCalled();
  });
});
