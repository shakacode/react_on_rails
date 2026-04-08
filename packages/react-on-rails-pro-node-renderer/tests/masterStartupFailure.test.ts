import { WORKER_STARTUP_FAILURE, type WorkerStartupFailureMessage } from '../src/shared/workerMessages';

type MockWorker = {
  id: number;
  isScheduledRestart?: boolean;
  process: { exitCode: number | null };
};

type ClusterHandlers = {
  message: (worker: MockWorker, message: unknown) => void;
  exit: (worker: MockWorker) => void;
};

type MockCluster = {
  on: jest.Mock<MockCluster, [event: string, handler: (...args: unknown[]) => void]>;
  fork: jest.Mock<unknown, []>;
  disconnect: jest.Mock<void, [callback?: () => void]>;
};

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

function setupMasterRunHarness() {
  const operations: string[] = [];
  const clusterHandlers: Partial<ClusterHandlers> = {};
  const mockFork = jest.fn(() => {
    operations.push('fork');
    return {};
  });
  const mockCluster = {} as MockCluster;
  mockCluster.disconnect = jest.fn((callback?: () => void) => {
    if (callback) callback();
  });
  mockCluster.on = jest.fn((event: string, handler: (...args: unknown[]) => void) => {
    operations.push(`on:${event}`);
    if (event === 'message') {
      clusterHandlers.message = handler as ClusterHandlers['message'];
    } else if (event === 'exit') {
      clusterHandlers.exit = handler as ClusterHandlers['exit'];
    }
    return mockCluster;
  });
  mockCluster.fork = mockFork;
  const mockErrorReporterMessage = jest.fn();
  const mockLog = {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    fatal: jest.fn(),
  };
  const mockBuildConfig = jest.fn(() => ({
    workersCount: 2,
    allWorkersRestartInterval: undefined,
    delayBetweenIndividualWorkerRestarts: undefined,
    gracefulWorkerRestartTimeout: 0,
    serverBundleCachePath: '/tmp/react-on-rails-pro-node-renderer-bundles',
  }));
  const mockLogSanitizedConfig = jest.fn();
  const mockGetLicenseStatus = jest.fn(() => 'valid');
  const setIntervalSpy = jest.spyOn(global, 'setInterval').mockReturnValue(0 as unknown as NodeJS.Timeout);
  const setTimeoutSpy = jest
    .spyOn(global, 'setTimeout')
    .mockReturnValue({ unref: jest.fn() } as unknown as NodeJS.Timeout);
  const processExitSpy = jest.spyOn(process, 'exit').mockImplementation(((code?: number) => {
    throw new Error(`process.exit:${code}`);
  }) as typeof process.exit);

  jest.doMock('cluster', () => ({
    __esModule: true,
    default: mockCluster,
  }));
  jest.doMock('../src/shared/log', () => ({
    __esModule: true,
    default: mockLog,
  }));
  jest.doMock('../src/shared/errorReporter', () => ({
    __esModule: true,
    message: mockErrorReporterMessage,
    error: jest.fn(),
    addMessageNotifier: jest.fn(),
    addErrorNotifier: jest.fn(),
    addNotifier: jest.fn(),
  }));
  jest.doMock('../src/shared/configBuilder', () => ({
    __esModule: true,
    buildConfig: mockBuildConfig,
    logSanitizedConfig: mockLogSanitizedConfig,
  }));
  jest.doMock('../src/shared/licenseValidator', () => ({
    __esModule: true,
    getLicenseStatus: mockGetLicenseStatus,
  }));
  jest.doMock('../src/master/restartWorkers', () => ({
    __esModule: true,
    default: jest.fn(),
  }));

  let masterRun: typeof import('../src/master').default | undefined;
  jest.isolateModules(() => {
    // eslint-disable-next-line global-require
    masterRun = require('../src/master').default as typeof import('../src/master').default;
  });

  if (!masterRun) {
    throw new Error('Failed to load masterRun');
  }

  masterRun();

  if (!clusterHandlers.message || !clusterHandlers.exit) {
    throw new Error('Failed to register cluster handlers');
  }

  return {
    operations,
    clusterHandlers: clusterHandlers as ClusterHandlers,
    mockFork,
    mockCluster,
    mockErrorReporterMessage,
    setIntervalSpy,
    setTimeoutSpy,
    processExitSpy,
  };
}

async function waitForSetImmediate() {
  await new Promise<void>((resolve) => {
    setImmediate(resolve);
  });
}

describe('master startup failure handling via masterRun wiring', () => {
  afterEach(() => {
    jest.restoreAllMocks();
    jest.resetModules();
  });

  it.each([
    {
      testName: 'EADDRINUSE startup failure',
      failureWorker: { id: 1, process: { exitCode: 1 } },
      exitingWorker: { id: 1, process: { exitCode: 1 } },
      failure: buildStartupFailureMessage(),
      expectedMessage: 'Node renderer startup failed: localhost:3800 is already in use',
    },
    {
      testName: 'generic startup failure from one worker while another exits first',
      failureWorker: { id: 2, process: { exitCode: 1 } },
      exitingWorker: { id: 1, process: { exitCode: 1 } },
      failure: buildStartupFailureMessage({
        code: 'EACCES',
        message: 'listen EACCES: permission denied 0.0.0.0:80',
      }),
      expectedMessage:
        'Node renderer startup failed in worker 2: listen EACCES: permission denied 0.0.0.0:80',
    },
  ])('registers listeners before forking and aborts without reforking on $testName', (scenario) => {
    const harness = setupMasterRunHarness();

    expect(harness.operations).toEqual(['on:message', 'fork', 'fork', 'on:exit']);
    expect(harness.mockFork).toHaveBeenCalledTimes(2);
    expect(harness.setIntervalSpy).toHaveBeenCalledTimes(1);

    harness.clusterHandlers.message(scenario.failureWorker, scenario.failure);

    expect(() => harness.clusterHandlers.exit(scenario.exitingWorker)).toThrow('process.exit:1');
    expect(harness.mockErrorReporterMessage).toHaveBeenCalledWith(scenario.expectedMessage);
    expect(harness.mockCluster.disconnect).toHaveBeenCalledTimes(1);
    expect(harness.processExitSpy).toHaveBeenCalledWith(1);
    expect(harness.mockFork).toHaveBeenCalledTimes(2);
  });

  it('keeps the first startup-failure details when multiple workers report failures', () => {
    const harness = setupMasterRunHarness();
    const firstFailure = buildStartupFailureMessage({
      code: 'EACCES',
      message: 'listen EACCES: permission denied 0.0.0.0:80',
    });
    const secondFailure = buildStartupFailureMessage({
      code: 'ECONNREFUSED',
      message: 'listen ECONNREFUSED: connection refused 127.0.0.1:3800',
    });

    harness.clusterHandlers.message({ id: 1, process: { exitCode: 1 } }, firstFailure);
    harness.clusterHandlers.message({ id: 2, process: { exitCode: 1 } }, secondFailure);

    expect(() => harness.clusterHandlers.exit({ id: 2, process: { exitCode: 1 } })).toThrow('process.exit:1');
    expect(harness.mockErrorReporterMessage).toHaveBeenCalledWith(
      'Node renderer startup failed in worker 1: listen EACCES: permission denied 0.0.0.0:80',
    );
  });

  it('reports error only once when multiple workers exit during abort', () => {
    const harness = setupMasterRunHarness();
    // Use a disconnect mock that does NOT invoke the callback, so process.exit
    // is not called and subsequent exit events can be observed.
    harness.mockCluster.disconnect.mockImplementation(() => {});

    harness.clusterHandlers.message({ id: 1, process: { exitCode: 1 } }, buildStartupFailureMessage());

    // First exit triggers the error report and disconnect.
    harness.clusterHandlers.exit({ id: 1, process: { exitCode: 1 } });
    expect(harness.mockErrorReporterMessage).toHaveBeenCalledTimes(1);
    expect(harness.mockCluster.disconnect).toHaveBeenCalledTimes(1);

    // Second worker exit during abort — no duplicate report, no refork.
    harness.clusterHandlers.exit({ id: 2, process: { exitCode: 1 } });
    expect(harness.mockErrorReporterMessage).toHaveBeenCalledTimes(1);
    expect(harness.mockCluster.disconnect).toHaveBeenCalledTimes(1);
    expect(harness.mockFork).toHaveBeenCalledTimes(2);
  });

  it('does not refork a scheduled-restart worker when aborting for startup failure', () => {
    const harness = setupMasterRunHarness();

    harness.clusterHandlers.message({ id: 1, process: { exitCode: 1 } }, buildStartupFailureMessage());

    // A scheduled-restart worker exiting during abort should NOT be reforked.
    expect(() =>
      harness.clusterHandlers.exit({ id: 2, isScheduledRestart: true, process: { exitCode: 0 } }),
    ).toThrow('process.exit:1');
    expect(harness.mockFork).toHaveBeenCalledTimes(2);
    expect(harness.mockErrorReporterMessage).toHaveBeenCalledTimes(1);
  });

  it('restarts scheduled-restart workers without reporting an error', () => {
    const harness = setupMasterRunHarness();
    const worker: MockWorker = { id: 1, isScheduledRestart: true, process: { exitCode: 0 } };

    harness.clusterHandlers.exit(worker);

    expect(harness.mockFork).toHaveBeenCalledTimes(3);
    expect(harness.mockErrorReporterMessage).not.toHaveBeenCalled();
    expect(harness.processExitSpy).not.toHaveBeenCalled();
  });

  it('waits one tick for startup-failure IPC before classifying an unexpected crash', async () => {
    const harness = setupMasterRunHarness();
    harness.mockCluster.disconnect.mockImplementation(() => {});
    const worker = { id: 1, process: { exitCode: 1 } };

    // Exit arrives first.
    harness.clusterHandlers.exit(worker);
    // Startup-failure message arrives before the deferred crash classification runs.
    harness.clusterHandlers.message(worker, buildStartupFailureMessage());
    await waitForSetImmediate();

    expect(harness.mockErrorReporterMessage).toHaveBeenCalledWith(
      'Node renderer startup failed: localhost:3800 is already in use',
    );
    expect(harness.mockCluster.disconnect).toHaveBeenCalledTimes(1);
    expect(harness.mockFork).toHaveBeenCalledTimes(2);
    expect(harness.processExitSpy).not.toHaveBeenCalled();
  });

  it('reforks on unexpected runtime crash when no startup failure was received', async () => {
    const harness = setupMasterRunHarness();

    harness.clusterHandlers.exit({ id: 3, process: { exitCode: 1 } });
    await waitForSetImmediate();

    expect(harness.mockErrorReporterMessage).toHaveBeenCalledWith(
      'Worker 3 died UNEXPECTEDLY :(, restarting',
    );
    expect(harness.mockFork).toHaveBeenCalledTimes(3);
    expect(harness.processExitSpy).not.toHaveBeenCalled();
  });

  it('ignores malformed startup-failure messages and treats exit as runtime crash', async () => {
    const harness = setupMasterRunHarness();

    harness.clusterHandlers.message({ id: 1, process: { exitCode: 1 } }, { type: WORKER_STARTUP_FAILURE });
    harness.clusterHandlers.exit({ id: 1, process: { exitCode: 1 } });
    await waitForSetImmediate();

    expect(harness.mockErrorReporterMessage).toHaveBeenCalledWith(
      'Worker 1 died UNEXPECTEDLY :(, restarting',
    );
    expect(harness.mockFork).toHaveBeenCalledTimes(3);
    expect(harness.processExitSpy).not.toHaveBeenCalled();
  });
});
