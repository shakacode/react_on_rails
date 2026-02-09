import { execFileSync } from 'child_process';
import { detectPackageManager } from '../src/utils';

jest.mock('child_process');
const mockedExecFileSync = jest.mocked(execFileSync);

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
