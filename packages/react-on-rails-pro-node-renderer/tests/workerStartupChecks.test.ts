describe('worker startup checks', () => {
  afterEach(() => {
    jest.restoreAllMocks();
    jest.resetModules();
  });

  it('runs the RSC peer compatibility check on direct worker startup', () => {
    const runRscPeerCompatibilityCheck = jest.fn();
    jest.doMock('../src/shared/runRscPeerCompatibilityCheck.js', () => ({
      __esModule: true,
      runRscPeerCompatibilityCheck,
    }));
    jest.doMock('../src/worker/handleGracefulShutdown.js', () => ({
      __esModule: true,
      default: jest.fn(),
    }));

    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      const worker = require('../src/worker').default as typeof import('../src/worker').default;
      const app = worker({
        serverBundleCachePath: '/tmp/react-on-rails-pro-node-renderer-test',
        workersCount: 0,
      });
      void app.close();
    });

    expect(runRscPeerCompatibilityCheck).toHaveBeenCalledWith({
      proVersion: expect.any(String),
    });
  });
});
