import {
  WORKER_STARTUP_FAILURE,
  isWorkerStartupFailureMessage,
  type WorkerStartupFailureMessage,
} from '../src/shared/workerMessages';

/**
 * These tests verify that the master process correctly handles the
 * WORKER_STARTUP_FAILURE IPC message by aborting instead of reforking,
 * while preserving the existing behavior for scheduled restarts and
 * runtime crashes.
 *
 * We test the decision logic in isolation by simulating the cluster events
 * that the master process listens to, rather than forking real workers.
 */

function buildStartupFailureMessage(
  overrides: Partial<WorkerStartupFailureMessage> = {},
): WorkerStartupFailureMessage {
  return {
    type: WORKER_STARTUP_FAILURE,
    stage: 'listen',
    code: 'EADDRINUSE',
    errno: -48,
    syscall: 'listen',
    host: 'localhost',
    port: 3800,
    message: 'listen EADDRINUSE: address already in use :::3800',
    ...overrides,
  };
}

describe('master startup failure handling', () => {
  let isAbortingForStartupFailure: boolean;
  let fatalStartupFailure: { workerId: number; failure: WorkerStartupFailureMessage } | null;
  let forkCount: number;
  let exitCode: number | null;
  let reportedMessages: string[];

  // Simulated handlers matching master.ts logic
  function handleMessage(worker: { id: number }, message: unknown) {
    if (!isWorkerStartupFailureMessage(message) || isAbortingForStartupFailure) return;

    isAbortingForStartupFailure = true;
    fatalStartupFailure = { workerId: worker.id, failure: message };
  }

  function handleExit(worker: {
    id: number;
    isScheduledRestart?: boolean;
    process: { exitCode: number | null };
  }) {
    if (worker.isScheduledRestart) {
      forkCount += 1; // cluster.fork()
      return;
    }

    if (isAbortingForStartupFailure) {
      const failure = fatalStartupFailure?.failure;
      const msg =
        failure?.code === 'EADDRINUSE'
          ? `Node renderer startup failed: port ${failure.port} is already in use`
          : `Node renderer startup failed in worker ${worker.id}: ${failure?.message || `exit code ${worker.process.exitCode}`}`;

      reportedMessages.push(msg);
      exitCode = 1;
      return;
    }

    const msg = `Worker ${worker.id} died UNEXPECTEDLY :(, restarting`;
    reportedMessages.push(msg);
    forkCount += 1; // cluster.fork()
  }

  beforeEach(() => {
    isAbortingForStartupFailure = false;
    fatalStartupFailure = null;
    forkCount = 0;
    exitCode = null;
    reportedMessages = [];
  });

  it('aborts with clear message on EADDRINUSE startup failure', () => {
    const worker = { id: 1, process: { exitCode: 1 } };
    const failure = buildStartupFailureMessage();

    // Worker sends startup failure message
    handleMessage(worker, failure);
    expect(isAbortingForStartupFailure).toBe(true);

    // Worker exits
    handleExit(worker);

    expect(forkCount).toBe(0); // No refork
    expect(exitCode).toBe(1);
    expect(reportedMessages).toEqual(['Node renderer startup failed: port 3800 is already in use']);
  });

  it('aborts with generic message on non-EADDRINUSE startup failure', () => {
    const worker = { id: 2, process: { exitCode: 1 } };
    const failure = buildStartupFailureMessage({
      code: 'EACCES',
      message: 'listen EACCES: permission denied 0.0.0.0:80',
    });

    handleMessage(worker, failure);
    handleExit(worker);

    expect(forkCount).toBe(0);
    expect(exitCode).toBe(1);
    expect(reportedMessages).toEqual([
      'Node renderer startup failed in worker 2: listen EACCES: permission denied 0.0.0.0:80',
    ]);
  });

  it('deduplicates multiple workers failing simultaneously', () => {
    const worker1 = { id: 1, process: { exitCode: 1 } };
    const worker2 = { id: 2, process: { exitCode: 1 } };
    const failure = buildStartupFailureMessage();

    // Both workers send failure messages
    handleMessage(worker1, failure);
    handleMessage(worker2, failure);

    // Only the first one is recorded
    expect(fatalStartupFailure?.workerId).toBe(1);

    // First worker exit triggers abort
    handleExit(worker1);
    expect(exitCode).toBe(1);
    expect(forkCount).toBe(0);
  });

  it('reforks on scheduled restart', () => {
    const worker = { id: 1, isScheduledRestart: true, process: { exitCode: 0 } };

    handleExit(worker);

    expect(forkCount).toBe(1);
    expect(exitCode).toBeNull();
    expect(reportedMessages).toHaveLength(0);
  });

  it('reforks on unexpected runtime crash without startup failure', () => {
    const worker = { id: 3, process: { exitCode: 1 } };

    // No startup failure message sent — this is a runtime crash
    handleExit(worker);

    expect(forkCount).toBe(1);
    expect(exitCode).toBeNull();
    expect(reportedMessages).toEqual(['Worker 3 died UNEXPECTEDLY :(, restarting']);
  });

  it('ignores non-startup-failure messages', () => {
    const worker = { id: 1 };

    handleMessage(worker, { type: 'SOME_OTHER_MESSAGE' });
    handleMessage(worker, 'a string message');
    handleMessage(worker, null);

    expect(isAbortingForStartupFailure).toBe(false);
    expect(fatalStartupFailure).toBeNull();
  });
});
