import { execFileSync, spawnSync } from 'child_process';
import { detectPackageManager, execCaptureArgs, execLiveArgs } from '../src/utils';

jest.mock('child_process');
const mockedExecFileSync = jest.mocked(execFileSync);
const mockedSpawnSync = jest.mocked(spawnSync);

describe('detectPackageManager', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
    (mockedExecFileSync as jest.Mock).mockImplementation(() => {
      throw new Error('command not found');
    });
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('detects pnpm from user agent', () => {
    process.env.npm_config_user_agent = 'pnpm/9.14.2 npm/? node/v22.0.0';
    expect(detectPackageManager()).toBe('pnpm');
  });

  it('detects npm from user agent', () => {
    process.env.npm_config_user_agent = 'npm/10.8.2 node/v22.0.0';
    expect(detectPackageManager()).toBe('npm');
  });

  it('falls back to checking pnpm availability', () => {
    delete process.env.npm_config_user_agent;
    (mockedExecFileSync as jest.Mock).mockImplementation((cmd: string) => {
      if (cmd === 'pnpm') return '9.14.2';
      throw new Error('command not found');
    });
    expect(detectPackageManager()).toBe('pnpm');
  });

  it('falls back to npm if pnpm not available', () => {
    delete process.env.npm_config_user_agent;
    (mockedExecFileSync as jest.Mock).mockImplementation((cmd: string) => {
      if (cmd === 'npm') return '10.8.2';
      throw new Error('command not found');
    });
    expect(detectPackageManager()).toBe('npm');
  });

  it('returns null if nothing available', () => {
    delete process.env.npm_config_user_agent;
    (mockedExecFileSync as jest.Mock).mockImplementation(() => {
      throw new Error('command not found');
    });
    expect(detectPackageManager()).toBeNull();
  });
});

describe('command helpers', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = {
      ...originalEnv,
      HOME: '/tmp/home',
      PATH: '/usr/bin:/bin',
    };
    mockedSpawnSync.mockReset();
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('merges parent environment into execLiveArgs child env', () => {
    mockedSpawnSync.mockReturnValue({ status: 0 } as ReturnType<typeof spawnSync>);

    execLiveArgs('git', ['status'], '/tmp/app', { CUSTOM_FLAG: 'yes' });

    expect(mockedSpawnSync).toHaveBeenCalledWith(
      'git',
      ['status'],
      expect.objectContaining({
        stdio: 'inherit',
        cwd: '/tmp/app',
        env: expect.objectContaining({
          HOME: '/tmp/home',
          PATH: '/usr/bin:/bin',
          CUSTOM_FLAG: 'yes',
        }),
      }),
    );
  });

  it('merges parent environment into execCaptureArgs child env', () => {
    mockedSpawnSync.mockReturnValue({ status: 0, stdout: 'ok', stderr: '' } as ReturnType<typeof spawnSync>);

    const result = execCaptureArgs('git', ['status'], '/tmp/app', { CUSTOM_FLAG: 'yes' });

    expect(result).toBe('ok');
    expect(mockedSpawnSync).toHaveBeenCalledWith(
      'git',
      ['status'],
      expect.objectContaining({
        stdio: 'pipe',
        encoding: 'utf8',
        cwd: '/tmp/app',
        env: expect.objectContaining({
          HOME: '/tmp/home',
          PATH: '/usr/bin:/bin',
          CUSTOM_FLAG: 'yes',
        }),
      }),
    );
  });

  it('raises a signal-specific error when execLiveArgs command is terminated', () => {
    mockedSpawnSync.mockReturnValue({ status: null, signal: 'SIGTERM' } as ReturnType<typeof spawnSync>);

    expect(() => execLiveArgs('git', ['status'])).toThrow('Command "git" was terminated by SIGTERM');
  });

  it('raises a signal-specific error when execCaptureArgs command is terminated', () => {
    mockedSpawnSync.mockReturnValue({ status: null, signal: 'SIGKILL' } as ReturnType<typeof spawnSync>);

    expect(() => execCaptureArgs('git', ['status'])).toThrow('Command "git" was terminated by SIGKILL');
  });
});
