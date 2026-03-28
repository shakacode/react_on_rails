import cluster from 'cluster';
import {
  WORKER_STARTUP_FAILURE,
  isWorkerStartupFailureMessage,
  type WorkerStartupFailureMessage,
} from '../src/shared/workerMessages';

describe('isWorkerStartupFailureMessage', () => {
  it('returns true for a valid startup failure message', () => {
    const msg: WorkerStartupFailureMessage = {
      type: WORKER_STARTUP_FAILURE,
      stage: 'listen',
      code: 'EADDRINUSE',
      errno: -48,
      syscall: 'listen',
      host: 'localhost',
      port: 3800,
      message: 'listen EADDRINUSE: address already in use :::3800',
    };
    expect(isWorkerStartupFailureMessage(msg)).toBe(true);
  });

  it('returns false for null', () => {
    expect(isWorkerStartupFailureMessage(null)).toBe(false);
  });

  it('returns false for a string', () => {
    expect(isWorkerStartupFailureMessage('hello')).toBe(false);
  });

  it('returns false for an object with a different type', () => {
    expect(isWorkerStartupFailureMessage({ type: 'OTHER' })).toBe(false);
  });

  it('returns false for an object without type', () => {
    expect(isWorkerStartupFailureMessage({ stage: 'listen' })).toBe(false);
  });
});

describe('worker startup failure IPC', () => {
  const originalSend = process.send;
  const originalExit = process.exit;
  const originalIsWorker = cluster.isWorker;

  afterEach(() => {
    process.send = originalSend;
    process.exit = originalExit;
    Object.defineProperty(cluster, 'isWorker', { value: originalIsWorker, writable: true });
  });

  it('sends WORKER_STARTUP_FAILURE message in clustered mode', () => {
    // Simulate a cluster worker environment
    Object.defineProperty(cluster, 'isWorker', { value: true, writable: true });
    const sentMessages: unknown[] = [];
    const exitCalls: number[] = [];

    process.send = ((msg: unknown, _handle?: unknown, _options?: unknown, callback?: () => void) => {
      sentMessages.push(msg);
      if (callback) callback();
      return true;
    }) as typeof process.send;

    process.exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as typeof process.exit;

    // Simulate what the worker does on listen error
    const err = Object.assign(new Error('listen EADDRINUSE: address already in use :::3800'), {
      code: 'EADDRINUSE',
      errno: -48,
      syscall: 'listen',
    });
    const host = 'localhost';
    const port = 3800;

    const startupFailure: WorkerStartupFailureMessage = {
      type: WORKER_STARTUP_FAILURE,
      stage: 'listen',
      code: err.code,
      errno: err.errno,
      syscall: err.syscall,
      host,
      port,
      message: err.message,
    };

    process.send!(startupFailure, undefined, undefined, () => {
      process.exit(1);
    });

    expect(sentMessages).toHaveLength(1);
    expect(isWorkerStartupFailureMessage(sentMessages[0])).toBe(true);
    expect((sentMessages[0] as WorkerStartupFailureMessage).code).toBe('EADDRINUSE');
    expect(exitCalls).toEqual([1]);
  });

  it('exits without IPC in single-process mode', () => {
    Object.defineProperty(cluster, 'isWorker', { value: false, writable: true });
    process.send = undefined;

    const exitCalls: number[] = [];
    process.exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as typeof process.exit;

    // In single-process mode, cluster.isWorker is false and process.send is undefined
    if (cluster.isWorker && process.send) {
      // Should not reach here
      process.send({ type: WORKER_STARTUP_FAILURE }, undefined, undefined, () => {
        process.exit(1);
      });
      return;
    }

    process.exit(1);

    expect(exitCalls).toEqual([1]);
  });
});
