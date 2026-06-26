import { validateAll } from '../src/validators';
import { createApp, validateAppName } from '../src/create-app';
import { detectPackageManager, logError, logInfo } from '../src/utils';

jest.mock('../src/validators');
jest.mock('../src/create-app');
jest.mock('../src/utils', () => ({
  ...jest.requireActual('../src/utils'),
  detectPackageManager: jest.fn(),
  logError: jest.fn(),
  logInfo: jest.fn(),
  logStep: jest.fn(),
  logStepDone: jest.fn(),
  logSuccess: jest.fn(),
}));

const mockedValidateAll = jest.mocked(validateAll);
const mockedValidateAppName = jest.mocked(validateAppName);
const mockedCreateApp = jest.mocked(createApp);
const mockedDetectPackageManager = jest.mocked(detectPackageManager);
const mockedLogInfo = jest.mocked(logInfo);
const mockedLogError = jest.mocked(logError);

function setupMocks() {
  mockedValidateAppName.mockReturnValue({ success: true });
  mockedValidateAll.mockReturnValue({ allValid: true, results: [] });
  mockedCreateApp.mockImplementation(() => {});
  mockedDetectPackageManager.mockReturnValue('npm');
  jest.spyOn(console, 'log').mockImplementation(() => {});
  jest.spyOn(process, 'exit').mockImplementation(() => undefined as never);
}

/**
 * Imports index.ts in an isolated module scope so that each test gets a fresh
 * Commander program. process.argv must be set before calling this.
 */
function loadIndex(): Promise<void> {
  return new Promise((resolve, reject) => {
    jest.isolateModules(() => {
      try {
        const mod = require('../src/index') as { ready: Promise<void> };
        mod.ready.then(resolve, reject);
      } catch (err) {
        reject(err);
      }
    });
  });
}

describe('setup mode resolution in run()', () => {
  const originalArgv = process.argv;
  const originalStdinIsTTY = process.stdin.isTTY;
  const originalStdoutIsTTY = process.stdout.isTTY;

  beforeEach(() => {
    jest.clearAllMocks();
    setupMocks();
  });

  afterEach(() => {
    process.argv = originalArgv;
    Object.defineProperty(process.stdin, 'isTTY', { value: originalStdinIsTTY, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: originalStdoutIsTTY, writable: true });
    jest.restoreAllMocks();
  });

  it('defaults to the Pro setup without RSC when no mode flag is passed in a TTY', async () => {
    Object.defineProperty(process.stdin, 'isTTY', { value: true, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: true, writable: true });
    process.argv = ['node', 'create-react-on-rails-app', 'my-app'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith(
      'my-app',
      expect.objectContaining({ pro: true, rsc: false, tailwind: false }),
    );
    expect(mockedLogInfo).toHaveBeenCalledWith(expect.stringContaining('Default setup: React on Rails Pro'));
  });

  it('defaults to the Pro setup without RSC when stdin/stdout are not TTYs', async () => {
    Object.defineProperty(process.stdin, 'isTTY', { value: undefined, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: undefined, writable: true });
    process.argv = ['node', 'create-react-on-rails-app', 'my-app'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith(
      'my-app',
      expect.objectContaining({ pro: true, rsc: false }),
    );
    expect(mockedLogInfo).not.toHaveBeenCalledWith(expect.stringContaining('not running interactively'));
  });

  it('keeps --standard as the explicit OSS-only setup', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--standard'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith(
      'my-app',
      expect.objectContaining({ pro: false, rsc: false }),
    );
  });

  it('keeps --pro as the explicit Pro setup without the RSC example', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--pro'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith(
      'my-app',
      expect.objectContaining({ pro: true, rsc: false }),
    );
  });

  it('keeps --rsc as the explicit Pro setup with the RSC example', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--rsc'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith(
      'my-app',
      expect.objectContaining({ pro: false, rsc: true }),
    );
  });

  it('keeps --rsc precedence over --pro for compatibility', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--pro', '--rsc'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith(
      'my-app',
      expect.objectContaining({ pro: false, rsc: true }),
    );
    expect(mockedLogInfo).toHaveBeenCalledWith(
      'Note: --rsc takes precedence over --pro; --pro will be ignored.',
    );
  });
});

describe('bundler flag resolution in run()', () => {
  const originalArgv = process.argv;

  beforeEach(() => {
    jest.clearAllMocks();
    setupMocks();
  });

  afterEach(() => {
    process.argv = originalArgv;
    jest.restoreAllMocks();
  });

  it('selects Rspack by default when no bundler flag is passed', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith('my-app', expect.objectContaining({ rspack: true }));
  });

  it('selects Webpack when --webpack is passed (alias for --no-rspack)', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--webpack'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith('my-app', expect.objectContaining({ rspack: false }));
  });

  it('accepts --no-rspack and --webpack together (both select Webpack)', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--no-rspack', '--webpack'];

    await loadIndex();

    expect(mockedLogError).not.toHaveBeenCalled();
    expect(mockedCreateApp).toHaveBeenCalledWith('my-app', expect.objectContaining({ rspack: false }));
  });

  it('exits with error when --rspack and --webpack are combined', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--rspack', '--webpack'];

    await loadIndex();

    expect(mockedLogError).toHaveBeenCalledWith(
      'Conflicting bundler flags: pass either --rspack or --webpack (alias for --no-rspack), not both.',
    );
    expect(process.exit).toHaveBeenCalledWith(1);
  });

  it('passes tailwind option when --tailwind is passed', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--tailwind'];

    await loadIndex();

    expect(mockedCreateApp).toHaveBeenCalledWith('my-app', expect.objectContaining({ tailwind: true }));
  });
});
