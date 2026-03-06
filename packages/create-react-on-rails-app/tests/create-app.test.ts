import path from 'path';
import fs from 'fs';
import { validateAppName, buildGeneratorArgs, createApp } from '../src/create-app';
import { CliOptions } from '../src/types';
import { execLiveArgs, logError, logInfo, logStepDone } from '../src/utils';

jest.mock('fs');
jest.mock('../src/utils', () => ({
  ...jest.requireActual('../src/utils'),
  execLiveArgs: jest.fn(),
  logStep: jest.fn(),
  logStepDone: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logInfo: jest.fn(),
}));

const mockedFs = jest.mocked(fs);
const mockedExecLiveArgs = jest.mocked(execLiveArgs);
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
    expect(result.error).toContain('letters, numbers, hyphens, and underscores');
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
    expect(buildGeneratorArgs(baseOptions)).toEqual(['--ignore-warnings']);
  });

  it('adds typescript flag when template is typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, template: 'typescript' })).toEqual([
      '--typescript',
      '--ignore-warnings',
    ]);
  });

  it('adds rspack flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true })).toEqual(['--rspack', '--ignore-warnings']);
  });

  it('adds rsc flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rsc: true })).toEqual(['--rsc', '--ignore-warnings']);
  });

  it('combines all enabled flags in order', () => {
    expect(
      buildGeneratorArgs({
        ...baseOptions,
        template: 'typescript',
        rspack: true,
        rsc: true,
      }),
    ).toEqual(['--typescript', '--rspack', '--rsc', '--ignore-warnings']);
  });

  it('combines rspack and rsc flags without typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true, rsc: true })).toEqual([
      '--rspack',
      '--rsc',
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
    process.env = { ...originalEnv };
    mockedExecLiveArgs.mockReset();
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
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      3,
      'bundle',
      ['add', 'react_on_rails_pro', '--strict'],
      appPath,
    );
    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      4,
      'bundle',
      ['exec', 'rails', 'generate', 'react_on_rails:install', '--rsc', '--ignore-warnings'],
      appPath,
    );
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
      ['exec', 'rails', 'generate', 'react_on_rails:install', '--ignore-warnings'],
      appPath,
    );
    expect(mockedExecLiveArgs).toHaveBeenCalledTimes(3);
    expect(mockedExecLiveArgs).not.toHaveBeenCalledWith(
      'bundle',
      ['add', 'react_on_rails_pro', '--strict'],
      expect.anything(),
    );
    expect(mockedLogInfo).toHaveBeenCalledWith('Then visit http://localhost:3000/hello_world');
    expect(processExitSpy).not.toHaveBeenCalled();
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
      'Directory removed. Configure access to React on Rails Pro gem source and rerun. For custom source/git setups, rerun without --rsc and add react_on_rails_pro manually in Gemfile.',
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
      'Configure gem source access for react_on_rails_pro, then delete the created "my-app" directory and rerun with --rsc.',
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
    process.env.REACT_ON_RAILS_GEM_PATH = '../react_on_rails';
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', baseOptions);

    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      2,
      'bundle',
      ['add', 'react_on_rails', '--strict', '--path', path.resolve('../react_on_rails')],
      appPath,
    );
  });

  it('uses local pro path when REACT_ON_RAILS_PRO_GEM_PATH is set', () => {
    process.env.REACT_ON_RAILS_PRO_GEM_PATH = '../react_on_rails_pro';
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', { ...baseOptions, rsc: true });

    expect(mockedExecLiveArgs).toHaveBeenNthCalledWith(
      3,
      'bundle',
      ['add', 'react_on_rails_pro', '--strict', '--path', path.resolve('../react_on_rails_pro')],
      appPath,
    );
  });
});
