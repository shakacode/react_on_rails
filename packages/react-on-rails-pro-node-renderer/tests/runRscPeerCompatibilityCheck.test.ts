import path from 'node:path';
import log from '../src/shared/log';
import {
  runRscPeerCompatibilityCheck,
  __resetRscPeerCompatibilityCheckForTests,
} from '../src/shared/runRscPeerCompatibilityCheck';

const FIXTURE = path.join(__dirname, 'fixtures');

describe('runRscPeerCompatibilityCheck', () => {
  let warnSpy: jest.SpyInstance;

  beforeEach(() => {
    __resetRscPeerCompatibilityCheckForTests();
    warnSpy = jest.spyOn(log, 'warn').mockImplementation(() => undefined);
  });

  afterEach(() => {
    warnSpy.mockRestore();
  });

  it('no-ops when react-on-rails-rsc cannot be resolved', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({ cwd: path.join(FIXTURE, 'no-rsc'), resolveVersion: () => null }),
    ).not.toThrow();
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

  it('downgrades a hard error to a warning when the env hatch is set', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        env: { REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK: '1' },
        resolveVersion: (spec) => (spec.startsWith('react-on-rails-rsc') ? '20.0.0' : '19.2.0'),
      }),
    ).not.toThrow();
    expect(warnSpy).toHaveBeenCalledTimes(1);
  });

  it('runs once per process (memoized)', () => {
    const resolveVersion = (spec: string) => (spec.startsWith('react-on-rails-rsc') ? '19.0.1' : '19.2.0');
    runRscPeerCompatibilityCheck({ resolveVersion });
    runRscPeerCompatibilityCheck({ resolveVersion });
    expect(warnSpy).toHaveBeenCalledTimes(1);
  });
});
