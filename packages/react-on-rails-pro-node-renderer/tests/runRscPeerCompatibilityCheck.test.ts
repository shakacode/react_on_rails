describe('runRscPeerCompatibilityCheck', () => {
  let warnSpy: jest.SpyInstance;
  let runRscPeerCompatibilityCheck: typeof import('../src/shared/runRscPeerCompatibilityCheck').runRscPeerCompatibilityCheck;

  beforeEach(() => {
    jest.resetModules();

    const log = jest.requireActual('../src/shared/log') as typeof import('../src/shared/log');
    warnSpy = jest.spyOn(log.default, 'warn').mockImplementation(() => undefined);

    ({ runRscPeerCompatibilityCheck } = jest.requireActual(
      '../src/shared/runRscPeerCompatibilityCheck',
    ) as typeof import('../src/shared/runRscPeerCompatibilityCheck'));
  });

  afterEach(() => {
    warnSpy.mockRestore();
  });

  it('no-ops when react-on-rails-rsc cannot be resolved', () => {
    expect(() => runRscPeerCompatibilityCheck({ resolveVersion: () => null })).not.toThrow();
    expect(warnSpy).not.toHaveBeenCalled();
  });

  it('throws on a hard incompatibility (rsc major mismatch)', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        resolveVersion: (spec) => (spec.startsWith('react-on-rails-rsc') ? '20.0.0' : '19.2.0'),
      }),
    ).toThrow(/Incompatible react-on-rails-rsc/);
  });

  it('warns (does not throw) when below recommendedMin', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        resolveVersion: (spec) => (spec.startsWith('react-on-rails-rsc') ? '19.0.1' : '19.2.0'),
      }),
    ).not.toThrow();
    expect(warnSpy).toHaveBeenCalledTimes(1);
  });

  it('does not label an existing warning as downgraded when the env hatch is set', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        env: { REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK: '1' },
        resolveVersion: (spec) => (spec.startsWith('react-on-rails-rsc') ? '19.0.1' : '19.2.0'),
      }),
    ).not.toThrow();
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(warnSpy).toHaveBeenCalledWith(expect.not.stringContaining('downgraded'));
  });

  it('downgrades a hard error to a warning when the env hatch is set', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        env: { REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK: '1' },
        resolveVersion: (spec) => (spec.startsWith('react-on-rails-rsc') ? '20.0.0' : '19.2.0'),
      }),
    ).not.toThrow();
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('downgraded to a warning'));
  });

  it.each(['0', 'false'])('does not downgrade a hard error when the env hatch is %s', (envValue) => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        env: { REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK: envValue },
        resolveVersion: (spec) => (spec.startsWith('react-on-rails-rsc') ? '20.0.0' : '19.2.0'),
      }),
    ).toThrow(/Incompatible react-on-rails-rsc/);
    expect(warnSpy).not.toHaveBeenCalled();
  });

  it('runs once per process (memoized)', () => {
    const resolveVersion = (spec: string) => (spec.startsWith('react-on-rails-rsc') ? '19.0.1' : '19.2.0');
    runRscPeerCompatibilityCheck({ resolveVersion });
    runRscPeerCompatibilityCheck({ resolveVersion });
    expect(warnSpy).toHaveBeenCalledTimes(1);
  });
});
