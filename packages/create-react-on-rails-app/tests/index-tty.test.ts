import { promptForMode } from '../src/prompt';
import { validateAll } from '../src/validators';
import { createApp, validateAppName } from '../src/create-app';
import { detectPackageManager, logError, logInfo } from '../src/utils';

jest.mock('../src/prompt');
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

const mockedPromptForMode = jest.mocked(promptForMode);
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
 * Awaits the exported `ready` promise so the async action fully completes.
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

describe('TTY detection branching in run()', () => {
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

  it('calls promptForMode when stdin and stdout are TTY and no mode flag is passed', async () => {
    Object.defineProperty(process.stdin, 'isTTY', { value: true, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: true, writable: true });
    mockedPromptForMode.mockResolvedValue({ pro: false, rsc: true });
    process.argv = ['node', 'create-react-on-rails-app', 'my-app'];

    await loadIndex();

    expect(mockedPromptForMode).toHaveBeenCalled();
  });

  it('does not call promptForMode when stdin is not a TTY', async () => {
    Object.defineProperty(process.stdin, 'isTTY', { value: undefined, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: true, writable: true });
    process.argv = ['node', 'create-react-on-rails-app', 'my-app'];

    await loadIndex();

    expect(mockedPromptForMode).not.toHaveBeenCalled();
    expect(mockedLogInfo).toHaveBeenCalledWith(expect.stringContaining('not running interactively'));
  });

  it('does not call promptForMode when stdout is not a TTY', async () => {
    Object.defineProperty(process.stdin, 'isTTY', { value: true, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: undefined, writable: true });
    process.argv = ['node', 'create-react-on-rails-app', 'my-app'];

    await loadIndex();

    expect(mockedPromptForMode).not.toHaveBeenCalled();
    expect(mockedLogInfo).toHaveBeenCalledWith(expect.stringContaining('not running interactively'));
  });

  it('does not call promptForMode when --rsc is explicitly passed', async () => {
    Object.defineProperty(process.stdin, 'isTTY', { value: true, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: true, writable: true });
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--rsc'];

    await loadIndex();

    expect(mockedPromptForMode).not.toHaveBeenCalled();
  });

  it('does not call promptForMode when --standard is explicitly passed', async () => {
    Object.defineProperty(process.stdin, 'isTTY', { value: true, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: true, writable: true });
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--standard'];

    await loadIndex();

    expect(mockedPromptForMode).not.toHaveBeenCalled();
  });

  it('exits with error when --standard is combined with --pro', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--standard', '--pro'];

    await loadIndex();

    expect(mockedLogError).toHaveBeenCalledWith('--standard cannot be combined with --pro or --rsc.');
    expect(process.exit).toHaveBeenCalledWith(1);
  });

  it('exits with error when --standard is combined with --rsc', async () => {
    process.argv = ['node', 'create-react-on-rails-app', 'my-app', '--standard', '--rsc'];

    await loadIndex();

    expect(mockedLogError).toHaveBeenCalledWith('--standard cannot be combined with --pro or --rsc.');
    expect(process.exit).toHaveBeenCalledWith(1);
  });
});

describe('bundler flag resolution in run()', () => {
  const originalArgv = process.argv;
  const originalStdinIsTTY = process.stdin.isTTY;
  const originalStdoutIsTTY = process.stdout.isTTY;

  beforeEach(() => {
    jest.clearAllMocks();
    setupMocks();
    // Non-interactive so no mode prompt fires; standard mode is used automatically.
    Object.defineProperty(process.stdin, 'isTTY', { value: undefined, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: undefined, writable: true });
  });

  afterEach(() => {
    process.argv = originalArgv;
    Object.defineProperty(process.stdin, 'isTTY', { value: originalStdinIsTTY, writable: true });
    Object.defineProperty(process.stdout, 'isTTY', { value: originalStdoutIsTTY, writable: true });
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
});
