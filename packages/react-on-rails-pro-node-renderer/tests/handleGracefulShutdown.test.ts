import { SHUTDOWN_WORKER_MESSAGE } from '../src/shared/utils';

type HookHandler = (...args: unknown[]) => void;

const flushPromises = () =>
  new Promise<void>((resolve) => {
    setImmediate(resolve);
  });

describe('handleGracefulShutdown', () => {
  const loadHandleGracefulShutdown = (
    worker: { id: number; destroy: jest.Mock; disconnect: jest.Mock },
    runWorkerShutdownHooks = jest.fn(async () => undefined),
  ) => {
    jest.resetModules();
    jest.doMock('cluster', () => ({
      __esModule: true,
      default: { worker },
    }));
    jest.doMock('../src/worker/shutdownHooks.js', () => ({
      runWorkerShutdownHooks,
    }));

    // eslint-disable-next-line global-require, @typescript-eslint/no-require-imports
    const handleGracefulShutdown = require('../src/worker/handleGracefulShutdown')
      .default as typeof import('../src/worker/handleGracefulShutdown').default;

    return { handleGracefulShutdown, runWorkerShutdownHooks };
  };

  const buildApp = () => {
    const hooks: Record<string, HookHandler> = {};
    const app = {
      addHook: jest.fn((name: string, handler: HookHandler) => {
        hooks[name] = handler;
      }),
      close: jest.fn(async () => undefined),
    };

    return { app, hooks };
  };

  let processOnSpy: jest.SpyInstance;
  let messageHandler: ((message: unknown) => void) | undefined;

  beforeEach(() => {
    messageHandler = undefined;
    processOnSpy = jest.spyOn(process, 'on').mockImplementation((event, listener) => {
      if (event === 'message') {
        messageHandler = listener as (message: unknown) => void;
      }
      return process;
    });
  });

  afterEach(() => {
    processOnSpy.mockRestore();
    jest.dontMock('cluster');
    jest.dontMock('../src/worker/shutdownHooks.js');
  });

  test('runs shutdown hooks before destroying an idle worker without closing Fastify', async () => {
    const worker = { id: 1, destroy: jest.fn(), disconnect: jest.fn() };
    const { handleGracefulShutdown, runWorkerShutdownHooks } = loadHandleGracefulShutdown(worker);
    const { app } = buildApp();

    handleGracefulShutdown(app as never);
    messageHandler!(SHUTDOWN_WORKER_MESSAGE);
    await flushPromises();

    expect(runWorkerShutdownHooks).toHaveBeenCalledTimes(1);
    expect(worker.destroy).toHaveBeenCalledTimes(1);
    expect(runWorkerShutdownHooks.mock.invocationCallOrder[0]).toBeLessThan(
      worker.destroy.mock.invocationCallOrder[0]!,
    );
    expect(app.close).not.toHaveBeenCalled();
    expect(worker.disconnect).not.toHaveBeenCalled();
  });

  test('disconnects while requests are active, then runs shutdown hooks before destroy after response', async () => {
    const worker = { id: 1, destroy: jest.fn(), disconnect: jest.fn() };
    const { handleGracefulShutdown, runWorkerShutdownHooks } = loadHandleGracefulShutdown(worker);
    const { app, hooks } = buildApp();

    handleGracefulShutdown(app as never);
    hooks.onRequest!(undefined, undefined, jest.fn());
    messageHandler!(SHUTDOWN_WORKER_MESSAGE);

    expect(worker.disconnect).toHaveBeenCalledTimes(1);
    expect(runWorkerShutdownHooks).not.toHaveBeenCalled();
    expect(worker.destroy).not.toHaveBeenCalled();

    hooks.onResponse!(undefined, undefined, jest.fn());
    await flushPromises();

    expect(runWorkerShutdownHooks).toHaveBeenCalledTimes(1);
    expect(worker.destroy).toHaveBeenCalledTimes(1);
    expect(runWorkerShutdownHooks.mock.invocationCallOrder[0]).toBeLessThan(
      worker.destroy.mock.invocationCallOrder[0]!,
    );
    expect(app.close).not.toHaveBeenCalled();
  });

  test('forces worker destroy when shutdown hooks hang', () => {
    jest.useFakeTimers();
    try {
      const worker = { id: 1, destroy: jest.fn(), disconnect: jest.fn() };
      const { handleGracefulShutdown, runWorkerShutdownHooks } = loadHandleGracefulShutdown(
        worker,
        jest.fn(() => new Promise(() => undefined)),
      );
      const { app } = buildApp();

      handleGracefulShutdown(app as never);
      messageHandler!(SHUTDOWN_WORKER_MESSAGE);

      expect(runWorkerShutdownHooks).toHaveBeenCalledTimes(1);
      expect(app.close).not.toHaveBeenCalled();
      expect(worker.destroy).not.toHaveBeenCalled();

      jest.advanceTimersByTime(10_000);

      expect(worker.destroy).toHaveBeenCalledTimes(1);
    } finally {
      jest.useRealTimers();
    }
  });
});
