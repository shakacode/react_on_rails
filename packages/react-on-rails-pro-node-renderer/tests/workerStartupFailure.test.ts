import {
  WORKER_STARTUP_FAILURE,
  isWorkerStartupFailureMessage,
  type WorkerStartupFailureMessage,
} from '../src/shared/workerMessages';
import { handleStartupListenError } from '../src/worker/startupErrorHandler';

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

  it('returns false for a non-integer port', () => {
    expect(
      isWorkerStartupFailureMessage({
        type: WORKER_STARTUP_FAILURE,
        stage: 'listen',
        host: 'localhost',
        port: 3800.5,
        message: 'some error',
      }),
    ).toBe(false);
  });

  it('returns false for an out-of-range port', () => {
    expect(
      isWorkerStartupFailureMessage({
        type: WORKER_STARTUP_FAILURE,
        stage: 'listen',
        host: 'localhost',
        port: 70000,
        message: 'some error',
      }),
    ).toBe(false);
  });

  it('returns false for a negative port', () => {
    expect(
      isWorkerStartupFailureMessage({
        type: WORKER_STARTUP_FAILURE,
        stage: 'listen',
        host: 'localhost',
        port: -1,
        message: 'some error',
      }),
    ).toBe(false);
  });
});

describe('worker startup listen error handling', () => {
  const buildListenError = () =>
    Object.assign(new Error('listen EADDRINUSE: address already in use :::3800'), {
      code: 'EADDRINUSE',
      errno: -48,
      syscall: 'listen',
    });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('sends WORKER_STARTUP_FAILURE message in clustered mode via the production handler', () => {
    const sentMessages: unknown[] = [];
    const exitCalls: number[] = [];
    const send = ((msg: unknown, _handle?: unknown, _options?: unknown, callback?: () => void) => {
      sentMessages.push(msg);
      callback?.();
      return true;
    }) as NodeJS.Process['send'];
    const exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as NodeJS.Process['exit'];

    handleStartupListenError({
      err: buildListenError(),
      host: 'localhost',
      port: 3800,
      isWorker: true,
      send,
      exit,
    });

    expect(sentMessages).toHaveLength(1);
    expect(isWorkerStartupFailureMessage(sentMessages[0])).toBe(true);
    expect(sentMessages[0]).toMatchObject({
      type: WORKER_STARTUP_FAILURE,
      stage: 'listen',
      host: 'localhost',
      port: 3800,
      code: 'EADDRINUSE',
    });
    expect(exitCalls).toEqual([1]);
  });

  it('exits without IPC in single-process mode via the production handler', () => {
    const send = jest.fn();
    const exitCalls: number[] = [];
    const exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as NodeJS.Process['exit'];

    handleStartupListenError({
      err: buildListenError(),
      host: 'localhost',
      port: 3800,
      isWorker: false,
      send: send as unknown as NodeJS.Process['send'],
      exit,
    });

    expect(send).not.toHaveBeenCalled();
    expect(exitCalls).toEqual([1]);
  });

  it('logs a warning and exits when cluster worker has no IPC channel', () => {
    // Temporarily remove process.send so the fallback `send ?? process.send?.bind(process)`
    // resolves to undefined, simulating a worker whose IPC channel has been destroyed.
    const originalSend = process.send;
    delete (process as { send?: typeof process.send }).send;

    const exitCalls: number[] = [];
    const exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as NodeJS.Process['exit'];

    try {
      handleStartupListenError({
        err: buildListenError(),
        host: 'localhost',
        port: 3800,
        isWorker: true,
        send: undefined,
        exit,
      });

      expect(exitCalls).toEqual([1]);
    } finally {
      process.send = originalSend;
    }
  });

  it('exits when process.send throws synchronously', () => {
    const send = (() => {
      throw new Error('ERR_IPC_CHANNEL_CLOSED');
    }) as NodeJS.Process['send'];
    const exitCalls: number[] = [];
    const exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as NodeJS.Process['exit'];

    handleStartupListenError({
      err: buildListenError(),
      host: 'localhost',
      port: 3800,
      isWorker: true,
      send,
      exit,
    });

    expect(exitCalls).toEqual([1]);
  });

  it('exits via timeout fallback when IPC callback is never invoked', () => {
    jest.useFakeTimers();
    const exitCalls: number[] = [];
    // send accepts the message but never invokes the callback, simulating a
    // half-broken IPC channel.
    const send = ((_msg: unknown, _handle?: unknown, _options?: unknown, _callback?: () => void) =>
      true) as NodeJS.Process['send'];
    const exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as NodeJS.Process['exit'];

    handleStartupListenError({
      err: buildListenError(),
      host: 'localhost',
      port: 3800,
      isWorker: true,
      send,
      exit,
    });

    // Callback was never invoked, so exit hasn't been called yet.
    expect(exitCalls).toEqual([]);

    // Advance past the IPC_SEND_TIMEOUT_MS (2000ms) fallback timer.
    jest.advanceTimersByTime(2000);
    expect(exitCalls).toEqual([1]);

    jest.useRealTimers();
  });

  it('does not exit twice when callback fires after timeout', () => {
    jest.useFakeTimers();
    const exitCalls: number[] = [];
    let savedCallback: (() => void) | undefined;
    const send = ((_msg: unknown, _handle?: unknown, _options?: unknown, callback?: () => void) => {
      savedCallback = callback;
      return true;
    }) as NodeJS.Process['send'];
    const exit = ((code?: number) => {
      exitCalls.push(code ?? 0);
    }) as NodeJS.Process['exit'];

    handleStartupListenError({
      err: buildListenError(),
      host: 'localhost',
      port: 3800,
      isWorker: true,
      send,
      exit,
    });

    // Timeout fires first.
    jest.advanceTimersByTime(2000);
    expect(exitCalls).toEqual([1]);

    // Late callback — should be a no-op.
    savedCallback?.();
    expect(exitCalls).toEqual([1]);

    jest.useRealTimers();
  });
});
