import path from 'path';
import fs from 'fs';
import { validateAppName, buildGeneratorArgs, createApp } from '../src/create-app';
import { CliOptions } from '../src/types';
import { execLiveArgs, getCommandVersion, logError, logInfo, logStepDone } from '../src/utils';

jest.mock('fs');
jest.mock('../src/utils', () => ({
  ...jest.requireActual('../src/utils'),
  execLiveArgs: jest.fn(),
  getCommandVersion: jest.fn(),
  logStep: jest.fn(),
  logStepDone: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logInfo: jest.fn(),
}));

const mockedFs = jest.mocked(fs);
const mockedExecLiveArgs = jest.mocked(execLiveArgs);
const mockedGetCommandVersion = jest.mocked(getCommandVersion);
const mockedLogError = jest.mocked(logError);
const mockedLogInfo = jest.mocked(logInfo);
const mockedLogStepDone = jest.mocked(logStepDone);

const baseOptions: CliOptions = {
  template: 'javascript',
  packageManager: 'npm',
  rspack: false,
  rsc: false,
};

describe('validateAppName', () => {
  beforeEach(() => {
    mockedFs.existsSync.mockReturnValue(false);
  });

  it('rejects empty name', () => {
    const result = validateAppName('');
    expect(result.success).toBe(false);
    expect(result.error).toContain('required');
  });

  it('rejects whitespace-only name', () => {
    const result = validateAppName('   ');
    expect(result.success).toBe(false);
  });

  it('rejects names with spaces', () => {
    const result = validateAppName('my app');
    expect(result.success).toBe(false);
    expect(result.error).toContain('must start with a letter');
  });

  it('rejects names starting with a hyphen', () => {
    const result = validateAppName('-myapp');
    expect(result.success).toBe(false);
    expect(result.error).toContain('must start with a letter');
  });

  it('rejects names starting with an underscore', () => {
    const result = validateAppName('_myapp');
    expect(result.success).toBe(false);
    expect(result.error).toContain('must start with a letter');
  });

  it('rejects names starting with a digit', () => {
    const result = validateAppName('1app');
    expect(result.success).toBe(false);
    expect(result.error).toContain('must start with a letter');
  });

  it('rejects names ending with a hyphen', () => {
    const result = validateAppName('myapp-');
    expect(result.success).toBe(false);
  });

  it('rejects names ending with an underscore', () => {
    const result = validateAppName('myapp_');
    expect(result.success).toBe(false);
  });

  it('rejects names with consecutive separators', () => {
    const result = validateAppName('my--app');
    expect(result.success).toBe(false);
  });

  it('rejects names with special characters', () => {
    const result = validateAppName('my@app');
    expect(result.success).toBe(false);
  });

  it('rejects names with dots', () => {
    const result = validateAppName('my.app');
    expect(result.success).toBe(false);
  });

  it('accepts valid names with letters', () => {
    const result = validateAppName('myapp');
    expect(result.success).toBe(true);
  });

  it('accepts valid names with hyphens', () => {
    const result = validateAppName('my-app');
    expect(result.success).toBe(true);
  });

  it('accepts valid names with underscores', () => {
    const result = validateAppName('my_app');
    expect(result.success).toBe(true);
  });

  it('accepts valid names with numbers', () => {
    const result = validateAppName('my-app-2');
    expect(result.success).toBe(true);
  });

  it('rejects when directory already exists', () => {
    mockedFs.existsSync.mockReturnValue(true);
    const result = validateAppName('existing-app');
    expect(result.success).toBe(false);
    expect(result.error).toContain('already exists');
  });
});

describe('buildGeneratorArgs', () => {
  it('includes ignore-warnings by default', () => {
    expect(buildGeneratorArgs(baseOptions)).toEqual(['--force', '--ignore-warnings']);
  });

  it('adds typescript flag when template is typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, template: 'typescript' })).toEqual([
      '--typescript',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('adds rspack flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true })).toEqual([
      '--rspack',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('adds rsc flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rsc: true })).toEqual([
      '--rsc',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('combines all enabled flags in order', () => {
    expect(
      buildGeneratorArgs({
        ...baseOptions,
        template: 'typescript',
        rspack: true,
        rsc: true,
      }),
    ).toEqual(['--typescript', '--rspack', '--rsc', '--force', '--ignore-warnings']);
  });

  it('combines rspack and rsc flags without typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true, rsc: true })).toEqual([
      '--rspack',
      '--rsc',
      '--force',
      '--ignore-warnings',
    ]);
  });
});

describe('createApp', () => {
  let processExitSpy: jest.SpyInstance;
  let consoleLogSpy: jest.SpyInstance;
  let consoleErrorSpy: jest.SpyInstance;
  const originalEnv = process.env;

  beforeEach(() => {
    mockedFs.rmSync.mockReset();
    mockedFs.existsSync.mockReturnValue(true);
    mockedFs.readFileSync.mockReset();
    mockedFs.writeFileSync.mockReset();
    process.env = { ...originalEnv };
    mockedExecLiveArgs.mockReset();
    mockedGetCommandVersion.mockReset();
    mockedGetCommandVersion.mockImplementation((command) => (command === 'pnpm' ? '10.22.0' : null));
    mockedLogError.mockReset();
    mockedLogInfo.mockReset();
    mockedLogStepDone.mockReset();

    processExitSpy = jest.spyOn(process, 'exit').mockImplementation((() => {
      throw new Error('process.exit');
    }) as never);
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    process.env = originalEnv;
    processExitSpy.mockRestore();
    consoleLogSpy.mockRestore();
    consoleErrorSpy.mockRestore();
  });

  it('installs react_on_rails_pro and prints hello_server route for --rsc', () => {
    const options = { ...baseOptions, rsc: true };
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', options);

    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(1, 'rails', [
      'new',
      'my-app',
      '--database=postgresql',
      '--skip-javascript',
    ]);
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      2,
      'bundle',
      ['add', 'react_on_rails', '--strict'],
      appPath,
    );
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(3, 'bundle', ['add', 'react_on_rails_pro'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      4,
      'bundle',
      ['exec', 'rails', 'generate', 'react_on_rails:install', '--rsc', '--force', '--ignore-warnings'],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'npm' }),
    );
    expect(mockedExecLiveArgs).toHaveBeenCalledTimes(4);
    expect(mockedLogStepDone).toHaveBeenCalledWith('react_on_rails gem added');
    expect(mockedLogStepDone).toHaveBeenCalledWith('react_on_rails_pro gem added');
    expect(mockedLogInfo).toHaveBeenCalledWith('Then visit http://localhost:3000/hello_server');
    expect(processExitSpy).not.toHaveBeenCalled();
  });

  it('creates a standard app without rsc', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', baseOptions);

    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(1, 'rails', [
      'new',
      'my-app',
      '--database=postgresql',
      '--skip-javascript',
    ]);
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      2,
      'bundle',
      ['add', 'react_on_rails', '--strict'],
      appPath,
    );
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      3,
      'bundle',
      ['exec', 'rails', 'generate', 'react_on_rails:install', '--force', '--ignore-warnings'],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'npm' }),
    );
    expect(mockedExecLiveArgs).toHaveBeenCalledTimes(3);
    expect(mockedExecLiveArgs).not.toHaveBeenCalledWith(
      'bundle',
      ['add', 'react_on_rails_pro'],
      expect.anything(),
    );
    expect(mockedLogInfo).toHaveBeenCalledWith('Then visit http://localhost:3000/hello_world');
    expect(consoleLogSpy).toHaveBeenCalledWith('  bin/rails db:prepare');
    expect(processExitSpy).not.toHaveBeenCalled();
  });

  it('converts pnpm scaffolds away from npm artifacts', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    const packageJsonPath = path.join(appPath, 'package.json');
    const setupPath = path.join(appPath, 'bin', 'setup');
    const packageLockPath = path.join(appPath, 'package-lock.json');

    mockedFs.readFileSync.mockImplementation((targetPath) => {
      if (targetPath === packageJsonPath) {
        return JSON.stringify({ packageManager: 'npm@11.6.2', name: 'app' });
      }
      if (targetPath === setupPath) {
        return '#!/usr/bin/env ruby\nsystem!("npm install")\n';
      }

      return '';
    });

    createApp('my-app', { ...baseOptions, packageManager: 'pnpm' });

    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      3,
      'bundle',
      ['exec', 'rails', 'generate', 'react_on_rails:install', '--force', '--ignore-warnings'],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'pnpm' }),
    );
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(4, 'pnpm', ['import'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(5, 'pnpm', ['install'], appPath);
    expect(mockedFs.rmSync).toHaveBeenCalledWith(packageLockPath, { force: true });
    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      packageJsonPath,
      expect.stringContaining('"packageManager": "pnpm@10.22.0"'),
      'utf8',
    );
    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      setupPath,
      expect.stringContaining('system!("pnpm install")'),
      'utf8',
    );
  });

  it('skips pnpm import when no package-lock.json exists but still runs pnpm install', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    const packageJsonPath = path.join(appPath, 'package.json');
    const setupPath = path.join(appPath, 'bin', 'setup');
    const packageLockPath = path.join(appPath, 'package-lock.json');

    mockedFs.existsSync.mockImplementation((targetPath) => targetPath !== packageLockPath);
    mockedFs.readFileSync.mockImplementation((targetPath) => {
      if (targetPath === packageJsonPath) {
        return JSON.stringify({ packageManager: 'pnpm@10.22.0', name: 'app' });
      }
      if (targetPath === setupPath) {
        return '#!/usr/bin/env ruby\nsystem!("pnpm install")\n';
      }

      return '';
    });

    createApp('my-app', { ...baseOptions, packageManager: 'pnpm' });

    expect(mockedExecLiveArgs).not.toHaveBeenCalledWith('pnpm', ['import'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('pnpm', ['install'], appPath);
    expect(mockedFs.rmSync).not.toHaveBeenCalledWith(packageLockPath, { force: true });
  });

  it('exits without printing success when pnpm normalization fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    const packageJsonPath = path.join(appPath, 'package.json');
    const packageLockPath = path.join(appPath, 'package-lock.json');

    mockedFs.existsSync.mockReturnValue(true);
    mockedFs.readFileSync.mockImplementation((targetPath) => {
      if (targetPath === packageJsonPath) {
        return JSON.stringify({ packageManager: 'npm@11.6.2', name: 'app' });
      }
      return '';
    });

    mockedExecLiveArgs
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {
        throw new Error('pnpm import failed');
      });

    expect(() => createApp('my-app', { ...baseOptions, packageManager: 'pnpm' })).toThrow('process.exit');

    expect(processExitSpy).toHaveBeenCalledWith(1);
    expect(mockedLogError).toHaveBeenCalledWith(
      'Failed to finish pnpm setup. The app was created, but package manager normalization did not complete.',
    );
    expect(mockedLogStepDone).not.toHaveBeenCalledWith('Done!');
    expect(mockedLogInfo).not.toHaveBeenCalledWith('Then visit http://localhost:3000/hello_world');
    expect(consoleLogSpy).not.toHaveBeenCalledWith('  bin/dev');
    expect(mockedFs.rmSync).not.toHaveBeenCalledWith(appPath, { recursive: true, force: true });
  });

  it('cleans up app directory when react_on_rails add fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    mockedExecLiveArgs
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {
        throw new Error('ror gem install failed');
      });

    expect(() => createApp('my-app', baseOptions)).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith(
      'Failed to add react_on_rails gem. Check the output above for details.',
    );
    expect(mockedFs.rmSync).toHaveBeenCalledWith(appPath, { recursive: true, force: true });
  });

  it('cleans up app directory when rails new fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    mockedExecLiveArgs.mockImplementationOnce(() => {
      throw new Error('rails new failed');
    });

    expect(() => createApp('my-app', baseOptions)).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith(
      'Failed to create Rails application. Check the output above for details.',
    );
    expect(mockedFs.rmSync).toHaveBeenCalledWith(appPath, { recursive: true, force: true });
    expect(mockedLogInfo).toHaveBeenCalledWith(
      'Directory removed. Fix the Rails app creation issue and rerun.',
    );
  });

  it('skips cleanup logging when app directory was never created', () => {
    mockedFs.existsSync.mockReturnValue(false);
    mockedExecLiveArgs.mockImplementationOnce(() => {
      throw new Error('rails new failed');
    });

    expect(() => createApp('my-app', baseOptions)).toThrow('process.exit');
    expect(mockedFs.rmSync).not.toHaveBeenCalled();
    expect(mockedLogInfo).not.toHaveBeenCalledWith('Cleaning up "my-app" directory...');
  });

  it('cleans up app directory when react_on_rails_pro add fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    mockedExecLiveArgs
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {
        throw new Error('pro gem install failed');
      });

    expect(() => createApp('my-app', { ...baseOptions, rsc: true })).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith('Failed to add react_on_rails_pro gem required by --rsc.');
    expect(mockedFs.rmSync).toHaveBeenCalledWith(appPath, { recursive: true, force: true });
    expect(mockedLogInfo).toHaveBeenCalledWith(
      'Directory removed. Ensure react_on_rails_pro is installable in your Bundler/RubyGems setup, then rerun with --rsc.',
    );
  });

  it('falls back to manual cleanup guidance if automatic cleanup fails', () => {
    mockedExecLiveArgs
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {
        throw new Error('pro gem install failed');
      });
    mockedFs.rmSync.mockImplementationOnce(() => {
      throw new Error('cleanup failed');
    });

    expect(() => createApp('my-app', { ...baseOptions, rsc: true })).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith(
      'Ensure react_on_rails_pro is installable, then delete the created "my-app" directory and rerun with --rsc.',
    );
  });

  it('cleans up app directory when generator fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    mockedExecLiveArgs
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {})
      .mockImplementationOnce(() => {
        throw new Error('generator failed');
      });

    expect(() => createApp('my-app', baseOptions)).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith(
      'React on Rails generator failed. Check the output above for details.',
    );
    expect(mockedFs.rmSync).toHaveBeenCalledWith(appPath, { recursive: true, force: true });
    expect(mockedLogInfo).toHaveBeenCalledWith('Directory removed. Fix the generator issue and rerun.');
  });

  it('uses local react_on_rails gem path when REACT_ON_RAILS_GEM_PATH is set', () => {
    const localGemPath = '/tmp/fake-react_on_rails';
    process.env.REACT_ON_RAILS_GEM_PATH = localGemPath;
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', baseOptions);

    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      2,
      'bundle',
      ['add', 'react_on_rails', '--path', localGemPath],
      appPath,
    );
  });

  it('uses local pro path when REACT_ON_RAILS_PRO_GEM_PATH is set', () => {
    const localProGemPath = '/tmp/fake-react_on_rails_pro';
    process.env.REACT_ON_RAILS_PRO_GEM_PATH = localProGemPath;
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', { ...baseOptions, rsc: true });

    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      3,
      'bundle',
      ['add', 'react_on_rails_pro', '--path', localProGemPath],
      appPath,
    );
  });

  it('exits early when local react_on_rails path does not exist', () => {
    const missingLocalGemPath = '/tmp/missing-react_on_rails';
    process.env.REACT_ON_RAILS_GEM_PATH = missingLocalGemPath;
    mockedFs.existsSync.mockImplementation((targetPath) => targetPath !== missingLocalGemPath);

    expect(() => createApp('my-app', baseOptions)).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith(
      `Local gem path from REACT_ON_RAILS_GEM_PATH does not exist: ${missingLocalGemPath}`,
    );
    expect(mockedExecLiveArgs).not.toHaveBeenCalled();
  });

  it('exits early when local react_on_rails_pro path does not exist', () => {
    const missingProGemPath = '/tmp/missing-react_on_rails_pro';
    process.env.REACT_ON_RAILS_PRO_GEM_PATH = missingProGemPath;
    mockedFs.existsSync.mockImplementation((targetPath) => targetPath !== missingProGemPath);

    expect(() => createApp('my-app', { ...baseOptions, rsc: true })).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith(
      `Local gem path from REACT_ON_RAILS_PRO_GEM_PATH does not exist: ${missingProGemPath}`,
    );
    expect(mockedExecLiveArgs).not.toHaveBeenCalled();
  });
});
