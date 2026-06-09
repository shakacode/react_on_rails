describe('ReactOnRailsProNodeRenderer startup checks', () => {
  afterEach(() => {
    jest.restoreAllMocks();
    jest.resetModules();
  });

  it('runs the RSC peer compatibility check on wrapper startup', async () => {
    const runRscPeerCompatibilityCheck = jest.fn();
    const buildConfig = jest.fn(() => ({ workersCount: 0 }));
    const ready = jest.fn(async () => undefined);
    const worker = jest.fn(() => ({ ready }));

    jest.doMock('cluster', () => ({
      __esModule: true,
      default: { isWorker: false },
    }));
    jest.doMock('../src/shared/runRscPeerCompatibilityCheck.js', () => ({
      __esModule: true,
      runRscPeerCompatibilityCheck,
    }));
    jest.doMock('../src/shared/configBuilder.js', () => ({
      __esModule: true,
      buildConfig,
    }));
    jest.doMock('../src/shared/log.js', () => ({
      __esModule: true,
      default: {
        error: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
      },
    }));
    jest.doMock('../src/worker.js', () => ({
      __esModule: true,
      default: worker,
    }));

    let reactOnRailsProNodeRenderer:
      | typeof import('../src/ReactOnRailsProNodeRenderer').reactOnRailsProNodeRenderer
      | undefined;
    jest.isolateModules(() => {
      ({ reactOnRailsProNodeRenderer } = require('../src/ReactOnRailsProNodeRenderer'));
    });

    if (!reactOnRailsProNodeRenderer) throw new Error('Failed to load reactOnRailsProNodeRenderer');

    await reactOnRailsProNodeRenderer({ workersCount: 0 });

    expect(runRscPeerCompatibilityCheck).toHaveBeenCalledWith({
      proVersion: expect.any(String),
    });
    expect(worker).toHaveBeenCalledWith({ workersCount: 0 });
    expect(ready).toHaveBeenCalledTimes(1);
  });
});
