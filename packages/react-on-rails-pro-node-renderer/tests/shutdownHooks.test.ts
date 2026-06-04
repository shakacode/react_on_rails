import {
  __resetWorkerShutdownHooksForTest,
  registerWorkerShutdownHook,
  runWorkerShutdownHooks,
} from '../src/worker/shutdownHooks';

describe('worker shutdown hooks', () => {
  beforeEach(() => {
    __resetWorkerShutdownHooksForTest();
  });

  afterEach(() => {
    __resetWorkerShutdownHooksForTest();
  });

  test('throws the original error when a single shutdown hook fails', async () => {
    const error = new Error('shutdown failed');
    registerWorkerShutdownHook(async () => {
      throw error;
    });

    await expect(runWorkerShutdownHooks()).rejects.toBe(error);
  });

  test('surfaces all errors when multiple shutdown hooks fail', async () => {
    const firstError = new Error('first shutdown failed');
    const secondError = new Error('second shutdown failed');
    registerWorkerShutdownHook(async () => {
      throw firstError;
    });
    registerWorkerShutdownHook(async () => {
      throw secondError;
    });

    await expect(runWorkerShutdownHooks()).rejects.toMatchObject({
      errors: [firstError, secondError],
      message: 'Multiple worker shutdown hooks failed',
      name: 'AggregateError',
    });
  });
});
