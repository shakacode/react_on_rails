import path from 'path';
import fs from 'fs';
import { validateAppName, buildGeneratorArgs, createApp } from '../src/create-app';
import { CliOptions } from '../src/types';
import {
  execCaptureArgs,
  execLiveArgs,
  getCommandVersion,
  logError,
  logInfo,
  logStepDone,
} from '../src/utils';

jest.mock('fs');
jest.mock('../src/utils', () => ({
  ...jest.requireActual('../src/utils'),
  execLiveArgs: jest.fn(),
  execCaptureArgs: jest.fn(),
  getCommandVersion: jest.fn(),
  logStep: jest.fn(),
  logStepDone: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logInfo: jest.fn(),
}));

const mockedFs = jest.mocked(fs);
const mockedExecCaptureArgs = jest.mocked(execCaptureArgs);
const mockedExecLiveArgs = jest.mocked(execLiveArgs);
const mockedGetCommandVersion = jest.mocked(getCommandVersion);
const mockedLogError = jest.mocked(logError);
const mockedLogInfo = jest.mocked(logInfo);
const mockedLogStepDone = jest.mocked(logStepDone);

const baseOptions: CliOptions = {
  template: 'javascript',
  packageManager: 'npm',
  rspack: false,
  pro: false,
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
    expect(buildGeneratorArgs(baseOptions)).toEqual(['--new-app', '--force', '--ignore-warnings']);
  });

  it('adds typescript flag when template is typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, template: 'typescript' })).toEqual([
      '--new-app',
      '--typescript',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('adds rspack flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true })).toEqual([
      '--new-app',
      '--rspack',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('adds rsc flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rsc: true })).toEqual([
      '--new-app',
      '--rsc',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('adds pro flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, pro: true })).toEqual([
      '--new-app',
      '--pro',
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
    ).toEqual(['--new-app', '--typescript', '--rspack', '--rsc', '--force', '--ignore-warnings']);
  });

  it('combines rspack and rsc flags without typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true, rsc: true })).toEqual([
      '--new-app',
      '--rspack',
      '--rsc',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('combines rspack and pro flags without typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true, pro: true })).toEqual([
      '--new-app',
      '--rspack',
      '--pro',
      '--force',
      '--ignore-warnings',
    ]);
  });

  it('prefers --rsc over --pro when both are set', () => {
    expect(buildGeneratorArgs({ ...baseOptions, pro: true, rsc: true })).toEqual([
      '--new-app',
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
    mockedExecCaptureArgs.mockReset();
    mockedExecCaptureArgs.mockImplementation((command, args) => {
      if (command === 'git' && args[0] === 'status') {
        return 'M Gemfile';
      }
      if (command === 'git' && args[0] === 'config') {
        throw new Error('git config not set');
      }

      return '';
    });
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

  function gitCommitCalls(): Array<[string, string[], string | undefined, NodeJS.ProcessEnv | undefined]> {
    return mockedExecLiveArgs.mock.calls.filter(
      (call): call is [string, string[], string | undefined, NodeJS.ProcessEnv | undefined] =>
        call[0] === 'git' && Array.isArray(call[1]) && call[1].includes('commit'),
    );
  }

  function gitCommitSubjects(): string[] {
    return gitCommitCalls().map(([, args]) => {
      const subjectIndex = args.indexOf('-m');
      return subjectIndex >= 0 ? args[subjectIndex + 1] : '';
    });
  }

  // Returns only the "step" commands (rails, bundle, pnpm, etc.) — excludes
  // educational git operations (add, commit) so assertions are resilient to
  // changes in the educational-commit interleaving.
  function stepCalls(): Array<[string, ...unknown[]]> {
    return mockedExecLiveArgs.mock.calls.filter(([cmd]) => cmd !== 'git');
  }

  function stepCallSummaries(): string[] {
    return stepCalls().map(([cmd, args]) => {
      const subArgs = args as string[];
      if (cmd === 'rails') return `rails ${subArgs[0]}`;
      if (cmd === 'bundle' && subArgs[0] === 'add') return `bundle add ${subArgs[1]}`;
      if (cmd === 'bundle' && subArgs.includes('generate')) return 'bundle generate';
      if (cmd === 'pnpm') return `pnpm ${subArgs[0]}`;
      return `${cmd} ${subArgs[0]}`;
    });
  }

  function expectFallbackGitIdentityOnCommits(): void {
    for (const [, args, , env] of gitCommitCalls()) {
      expect(args).toEqual(expect.arrayContaining(['-c', 'commit.gpgsign=false', 'commit']));
      expect(env).toEqual(
        expect.objectContaining({
          GIT_AUTHOR_NAME: 'React on Rails Generator',
          GIT_AUTHOR_EMAIL: 'generator@reactonrails.invalid',
          GIT_COMMITTER_NAME: 'React on Rails Generator',
          GIT_COMMITTER_EMAIL: 'generator@reactonrails.invalid',
        }),
      );
    }
  }

  function expectGitIdentityLookedUpOncePerApp(): void {
    const gitConfigCalls = mockedExecCaptureArgs.mock.calls.filter(
      (call): call is [string, string[], string | undefined, NodeJS.ProcessEnv | undefined] =>
        call[0] === 'git' && Array.isArray(call[1]) && call[1][0] === 'config',
    );

    expect(gitConfigCalls).toEqual([
      ['git', ['config', '--get', 'user.name'], expect.any(String)],
      ['git', ['config', '--get', 'user.email'], expect.any(String)],
    ]);
  }

  function expectRailsGitScaffoldRestored(appPath: string): void {
    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      path.join(appPath, '.gitignore'),
      expect.stringContaining('/tmp/*'),
      'utf8',
    );
    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      path.join(appPath, '.gitignore'),
      expect.stringContaining('/node_modules'),
      'utf8',
    );
    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      path.join(appPath, '.gitattributes'),
      expect.stringContaining('db/schema.rb linguist-generated'),
      'utf8',
    );
  }

  it('installs react_on_rails_pro and prints hello_server route for --rsc', () => {
    const options = { ...baseOptions, rsc: true };
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', options);

    expect(mockedExecLiveArgs).toHaveBeenCalledWith('rails', [
      'new',
      'my-app',
      '--database=postgresql',
      '--skip-javascript',
      '--skip-git',
    ]);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('bundle', ['add', 'react_on_rails', '--strict'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('bundle', ['add', 'react_on_rails_pro'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
      'bundle',
      [
        'exec',
        'rails',
        'generate',
        'react_on_rails:install',
        '--new-app',
        '--rsc',
        '--force',
        '--ignore-warnings',
      ],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'npm' }),
    );
    expect(stepCallSummaries()).toEqual([
      'rails new',
      'bundle add react_on_rails',
      'bundle add react_on_rails_pro',
      'bundle generate',
    ]);
    expect(mockedLogStepDone).toHaveBeenCalledWith('react_on_rails gem added');
    expect(mockedLogStepDone).toHaveBeenCalledWith('react_on_rails_pro gem added');
    expect(mockedLogInfo).toHaveBeenCalledWith('Then visit http://localhost:3000');
    expect(gitCommitSubjects()).toEqual([
      'Create Rails app with PostgreSQL',
      'Add react_on_rails gem',
      'Add react_on_rails_pro gem',
      'Install React Server Components with JavaScript and Webpack',
    ]);
    expectRailsGitScaffoldRestored(appPath);
    expectFallbackGitIdentityOnCommits();
    expectGitIdentityLookedUpOncePerApp();
    expect(processExitSpy).not.toHaveBeenCalled();
  });

  it('installs react_on_rails_pro and keeps hello_world route for --pro', () => {
    const options = { ...baseOptions, pro: true };
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', options);

    expect(mockedExecLiveArgs).toHaveBeenCalledWith('rails', [
      'new',
      'my-app',
      '--database=postgresql',
      '--skip-javascript',
      '--skip-git',
    ]);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('bundle', ['add', 'react_on_rails', '--strict'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('bundle', ['add', 'react_on_rails_pro'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
      'bundle',
      [
        'exec',
        'rails',
        'generate',
        'react_on_rails:install',
        '--new-app',
        '--pro',
        '--force',
        '--ignore-warnings',
      ],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'npm' }),
    );
    expect(stepCallSummaries()).toEqual([
      'rails new',
      'bundle add react_on_rails',
      'bundle add react_on_rails_pro',
      'bundle generate',
    ]);
    expect(mockedLogStepDone).toHaveBeenCalledWith('react_on_rails gem added');
    expect(mockedLogStepDone).toHaveBeenCalledWith('react_on_rails_pro gem added');
    expect(mockedLogInfo).toHaveBeenCalledWith('Then visit http://localhost:3000');
    expect(gitCommitSubjects()).toEqual([
      'Create Rails app with PostgreSQL',
      'Add react_on_rails gem',
      'Add react_on_rails_pro gem',
      'Install React on Rails Pro with JavaScript and Webpack',
    ]);
    expectRailsGitScaffoldRestored(appPath);
    expect(processExitSpy).not.toHaveBeenCalled();
  });

  it('restores the Rails git scaffold from installed railties templates when available', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');

    mockedExecCaptureArgs.mockImplementation((command, args) => {
      if (command === 'git' && args[0] === 'status') {
        return 'M Gemfile';
      }
      if (command === 'git' && args[0] === 'config') {
        throw new Error('git config not set');
      }
      if (command === 'ruby' && args[0] === '-e' && args[2] === 'gitignore.tt') {
        return '# rendered gitignore\n/tmp/*';
      }
      if (command === 'ruby' && args[0] === '-e' && args[2] === 'gitattributes.tt') {
        return '# rendered gitattributes\ndb/schema.rb linguist-generated';
      }

      return '';
    });

    createApp('my-app', baseOptions);

    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      path.join(appPath, '.gitignore'),
      '# rendered gitignore\n/tmp/*\n',
      'utf8',
    );
    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      path.join(appPath, '.gitattributes'),
      '# rendered gitattributes\ndb/schema.rb linguist-generated\n',
      'utf8',
    );
  });

  it('guards Rails template rendering to supported railties major versions', () => {
    let rendererScript = '';

    mockedExecCaptureArgs.mockImplementation((command, args) => {
      if (command === 'git' && args[0] === 'status') {
        return 'M Gemfile';
      }
      if (command === 'git' && args[0] === 'config') {
        throw new Error('git config not set');
      }
      if (command === 'ruby' && args[0] === '-e' && args[2] === 'gitignore.tt') {
        rendererScript = args[1];
        return '# rendered gitignore\n/tmp/*';
      }
      if (command === 'ruby' && args[0] === '-e' && args[2] === 'gitattributes.tt') {
        return '# rendered gitattributes\ndb/schema.rb linguist-generated';
      }

      return '';
    });

    createApp('my-app', baseOptions);

    expect(rendererScript).toMatch(/\[\s*7,\s*8\s*\]\.include\?\(railties_major\)/);
  });

  it('falls back to bundled Rails git scaffold when template rendering fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');

    mockedExecCaptureArgs.mockImplementation((command, args) => {
      if (command === 'git' && args[0] === 'status') {
        return 'M Gemfile';
      }
      if (command === 'git' && args[0] === 'config') {
        throw new Error('git config not set');
      }
      if (command === 'ruby' && args[0] === '-e') {
        throw new Error('unsupported railties major');
      }

      return '';
    });

    createApp('my-app', baseOptions);

    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      path.join(appPath, '.gitignore'),
      expect.stringContaining('/node_modules'),
      'utf8',
    );
    expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
      path.join(appPath, '.gitattributes'),
      expect.stringContaining('vendor/* linguist-vendored'),
      'utf8',
    );
  });

  it('uses --rsc generator mode when both --pro and --rsc are set', () => {
    const options = { ...baseOptions, pro: true, rsc: true };
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', options);

    expect(mockedExecLiveArgs).toHaveBeenCalledWith('bundle', ['add', 'react_on_rails_pro'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
      'bundle',
      [
        'exec',
        'rails',
        'generate',
        'react_on_rails:install',
        '--new-app',
        '--rsc',
        '--force',
        '--ignore-warnings',
      ],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'npm' }),
    );
    expect(mockedExecLiveArgs).not.toHaveBeenCalledWith(
      'bundle',
      [
        'exec',
        'rails',
        'generate',
        'react_on_rails:install',
        '--new-app',
        '--pro',
        '--force',
        '--ignore-warnings',
      ],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'npm' }),
    );
    expect(mockedLogInfo).toHaveBeenCalledWith('Then visit http://localhost:3000');
    expect(processExitSpy).not.toHaveBeenCalled();
  });

  it('creates a standard app without rsc', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', baseOptions);

    expect(mockedExecLiveArgs).toHaveBeenCalledWith('rails', [
      'new',
      'my-app',
      '--database=postgresql',
      '--skip-javascript',
      '--skip-git',
    ]);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('bundle', ['add', 'react_on_rails', '--strict'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
      'bundle',
      ['exec', 'rails', 'generate', 'react_on_rails:install', '--new-app', '--force', '--ignore-warnings'],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'npm' }),
    );
    expect(stepCallSummaries()).toEqual(['rails new', 'bundle add react_on_rails', 'bundle generate']);
    expect(mockedExecLiveArgs).not.toHaveBeenCalledWith(
      'bundle',
      ['add', 'react_on_rails_pro'],
      expect.anything(),
    );
    expect(mockedLogInfo).toHaveBeenCalledWith('Then visit http://localhost:3000');
    expect(mockedLogInfo).toHaveBeenCalledWith('Educational git history: git log --oneline --reverse');
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

    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
      'bundle',
      ['exec', 'rails', 'generate', 'react_on_rails:install', '--new-app', '--force', '--ignore-warnings'],
      appPath,
      expect.objectContaining({ REACT_ON_RAILS_PACKAGE_MANAGER: 'pnpm' }),
    );
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('pnpm', ['import'], appPath);
    expect(mockedExecLiveArgs).toHaveBeenCalledWith('pnpm', ['install'], appPath);
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
    expect(stepCallSummaries()).toEqual([
      'rails new',
      'bundle add react_on_rails',
      'bundle generate',
      'pnpm import',
      'pnpm install',
    ]);
    expect(gitCommitSubjects()).toEqual([
      'Create Rails app with PostgreSQL',
      'Add react_on_rails gem',
      'Install React on Rails with JavaScript and Webpack',
      'Normalize the generated app for pnpm',
    ]);
    expectRailsGitScaffoldRestored(appPath);
    expectFallbackGitIdentityOnCommits();
    expectGitIdentityLookedUpOncePerApp();
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

    mockedExecLiveArgs.mockImplementation((command, args) => {
      if (command === 'pnpm' && args[0] === 'import') {
        throw new Error('pnpm import failed');
      }
    });

    expect(() => createApp('my-app', { ...baseOptions, packageManager: 'pnpm' })).toThrow('process.exit');

    expect(processExitSpy).toHaveBeenCalledWith(1);
    expect(mockedLogError).toHaveBeenCalledWith(
      'Failed to finish pnpm setup. The app was created, but package manager normalization did not complete.',
    );
    expect(mockedLogStepDone).not.toHaveBeenCalledWith('Done!');
    expect(mockedLogInfo).not.toHaveBeenCalledWith('Then visit http://localhost:3000');
    expect(consoleLogSpy).not.toHaveBeenCalledWith('  bin/dev');
    expect(mockedFs.rmSync).not.toHaveBeenCalledWith(appPath, { recursive: true, force: true });
  });

  it('cleans up app directory when react_on_rails add fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    mockedExecLiveArgs.mockImplementation((command, args) => {
      if (command === 'bundle' && args[0] === 'add' && args[1] === 'react_on_rails') {
        throw new Error('ror gem install failed');
      }
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

  it('keeps scaffolding when educational git commit creation fails', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');

    mockedExecLiveArgs.mockImplementation((command, args) => {
      if (command === 'git' && args.includes('commit')) {
        throw new Error('git commit failed');
      }
    });

    createApp('my-app', baseOptions);

    expect(mockedLogInfo).toHaveBeenCalledWith(
      'Educational git history paused after "Create Rails app with PostgreSQL" because git commit automation failed. The app scaffold will continue.',
    );
    expect(mockedLogInfo).toHaveBeenCalledWith(
      'Educational git history is partial because git commit automation was skipped after an earlier failure.',
    );
    expect(mockedFs.rmSync).not.toHaveBeenCalledWith(appPath, { recursive: true, force: true });
    expect(gitCommitCalls()).toHaveLength(1);
    expect(processExitSpy).not.toHaveBeenCalled();
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
    mockedExecLiveArgs.mockImplementation((command, args) => {
      if (command === 'bundle' && args[0] === 'add' && args[1] === 'react_on_rails_pro') {
        throw new Error('pro gem install failed');
      }
    });

    expect(() => createApp('my-app', { ...baseOptions, rsc: true })).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith('Failed to add react_on_rails_pro gem required by --rsc.');
    expect(mockedFs.rmSync).toHaveBeenCalledWith(appPath, { recursive: true, force: true });
    expect(mockedLogInfo).toHaveBeenCalledWith(
      'Directory removed. Ensure react_on_rails_pro is installable in your Bundler/RubyGems setup, then rerun with --rsc.',
    );
  });

  it('cleans up app directory when react_on_rails_pro add fails for --pro', () => {
    const appPath = path.resolve(process.cwd(), 'my-app');
    mockedExecLiveArgs.mockImplementation((command, args) => {
      if (command === 'bundle' && args[0] === 'add' && args[1] === 'react_on_rails_pro') {
        throw new Error('pro gem install failed');
      }
    });

    expect(() => createApp('my-app', { ...baseOptions, pro: true })).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith('Failed to add react_on_rails_pro gem required by --pro.');
    expect(mockedFs.rmSync).toHaveBeenCalledWith(appPath, { recursive: true, force: true });
    expect(mockedLogInfo).toHaveBeenCalledWith(
      'Directory removed. Ensure react_on_rails_pro is installable in your Bundler/RubyGems setup, then rerun with --pro.',
    );
  });

  it('falls back to manual cleanup guidance if automatic cleanup fails', () => {
    mockedExecLiveArgs.mockImplementation((command, args) => {
      if (command === 'bundle' && args[0] === 'add' && args[1] === 'react_on_rails_pro') {
        throw new Error('pro gem install failed');
      }
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
    mockedExecLiveArgs.mockImplementation((command, args) => {
      if (command === 'bundle' && args.includes('generate')) {
        throw new Error('generator failed');
      }
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

    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
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

    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
      'bundle',
      ['add', 'react_on_rails_pro', '--path', localProGemPath],
      appPath,
    );
  });

  it('uses local pro path when REACT_ON_RAILS_PRO_GEM_PATH is set for --pro', () => {
    const localProGemPath = '/tmp/fake-react_on_rails_pro';
    process.env.REACT_ON_RAILS_PRO_GEM_PATH = localProGemPath;
    const appPath = path.resolve(process.cwd(), 'my-app');

    createApp('my-app', { ...baseOptions, pro: true });

    expect(mockedExecLiveArgs).toHaveBeenCalledWith(
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

  it('exits early when local react_on_rails_pro path does not exist for --pro', () => {
    const missingProGemPath = '/tmp/missing-react_on_rails_pro';
    process.env.REACT_ON_RAILS_PRO_GEM_PATH = missingProGemPath;
    mockedFs.existsSync.mockImplementation((targetPath) => targetPath !== missingProGemPath);

    expect(() => createApp('my-app', { ...baseOptions, pro: true })).toThrow('process.exit');
    expect(mockedLogError).toHaveBeenCalledWith(
      `Local gem path from REACT_ON_RAILS_PRO_GEM_PATH does not exist: ${missingProGemPath}`,
    );
    expect(mockedExecLiveArgs).not.toHaveBeenCalled();
  });
});
