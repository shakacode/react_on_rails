import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

describe('runRscPeerCompatibilityCheck', () => {
  let warnSpy: jest.SpyInstance;
  let runRscPeerCompatibilityCheck: typeof import('../src/shared/runRscPeerCompatibilityCheck').runRscPeerCompatibilityCheck;

  const resolveVersions =
    (rscVersion: string, reactVersion = '19.2.0') =>
    (spec: string): string | null => {
      if (spec === 'react-on-rails-rsc') return rscVersion;
      if (spec === 'react') return reactVersion;
      return null;
    };

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

  it('falls back to the package root when package.json is not exported', () => {
    const appRoot = mkdtempSync(path.join(tmpdir(), 'ror-rsc-peer-'));
    const packageRoot = path.join(appRoot, 'node_modules', 'react-on-rails-rsc');
    mkdirSync(path.join(packageRoot, 'dist'), { recursive: true });
    writeFileSync(path.join(packageRoot, 'dist', 'index.js'), 'export {};\n');
    writeFileSync(
      path.join(packageRoot, 'dist', 'package.json'),
      `${JSON.stringify({ name: 'react-server-dom-webpack', version: '18.0.0' })}\n`,
    );
    writeFileSync(
      path.join(packageRoot, 'package.json'),
      `${JSON.stringify({
        name: 'react-on-rails-rsc',
        version: '20.0.0',
        exports: { '.': './dist/index.js' },
        type: 'module',
      })}\n`,
    );

    try {
      expect(() => runRscPeerCompatibilityCheck({ cwd: appRoot })).toThrow(/Incompatible react-on-rails-rsc/);
      expect(warnSpy).not.toHaveBeenCalled();
    } finally {
      rmSync(appRoot, { recursive: true, force: true });
    }
  });

  it('warns when package resolution cannot start from the supplied cwd', () => {
    expect(() => runRscPeerCompatibilityCheck({ cwd: 'relative-app-root' })).not.toThrow();
    expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('createRequire failed'));
  });

  it('throws on a hard incompatibility (rsc major mismatch)', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        resolveVersion: resolveVersions('20.0.0'),
      }),
    ).toThrow(/Incompatible react-on-rails-rsc/);
  });

  it('warns (does not throw) when below recommendedMin', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        resolveVersion: resolveVersions('19.0.1'),
      }),
    ).not.toThrow();
    expect(warnSpy).toHaveBeenCalledTimes(1);
  });

  it('does not label an existing warning as downgraded when the env hatch is set', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        env: { REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK: '1' },
        resolveVersion: resolveVersions('19.0.1'),
      }),
    ).not.toThrow();
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(warnSpy).toHaveBeenCalledWith(expect.not.stringContaining('downgraded'));
  });

  it('downgrades a hard error to a warning when the env hatch is set', () => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        env: { REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK: '1' },
        resolveVersion: resolveVersions('20.0.0'),
      }),
    ).not.toThrow();
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('downgraded to a warning'));
  });

  it.each(['0', 'false'])('does not downgrade a hard error when the env hatch is %s', (envValue) => {
    expect(() =>
      runRscPeerCompatibilityCheck({
        env: { REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK: envValue },
        resolveVersion: resolveVersions('20.0.0'),
      }),
    ).toThrow(/Incompatible react-on-rails-rsc/);
    expect(warnSpy).not.toHaveBeenCalled();
  });

  it('runs once per process (memoized)', () => {
    const resolveVersion = resolveVersions('19.0.1');
    runRscPeerCompatibilityCheck({ resolveVersion });
    runRscPeerCompatibilityCheck({ resolveVersion });
    expect(warnSpy).toHaveBeenCalledTimes(1);
  });
});
