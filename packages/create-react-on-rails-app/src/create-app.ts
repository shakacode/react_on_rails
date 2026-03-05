import path from 'path';
import fs from 'fs';
import { CliOptions } from './types.js';
import { execLiveArgs, logStep, logStepDone, logError, logSuccess, logInfo } from './utils.js';

function cleanupAppDirectory(
  appPath: string,
  appName: string,
  cleanupSuccessMessage: string,
  cleanupFallbackMessage: string,
): void {
  logInfo(`Cleaning up "${appName}" directory...`);
  try {
    fs.rmSync(appPath, { recursive: true, force: true });
    logInfo(cleanupSuccessMessage);
  } catch {
    logInfo(cleanupFallbackMessage);
  }
}

function localGemPath(envVarName: string): string | null {
  const value = process.env[envVarName];
  if (!value || value.trim() === '') {
    return null;
  }

  return path.resolve(value);
}

export function buildGeneratorArgs(options: CliOptions): string[] {
  const args: string[] = [];

  if (options.template === 'typescript') {
    args.push('--typescript');
  }

  if (options.rspack) {
    args.push('--rspack');
  }

  if (options.rsc) {
    args.push('--rsc');
  }

  args.push('--ignore-warnings');

  return args;
}

function printSuccessMessage(appName: string, route: string): void {
  console.log('');
  logSuccess(`Created ${appName} with React on Rails!`);
  console.log('');
  logInfo('Next steps:');
  console.log(`  cd ${appName}`);
  console.log('  bin/dev');
  console.log('');
  logInfo(`Then visit http://localhost:3000/${route}`);
  console.log('');
  logInfo('Documentation: https://www.shakacode.com/react-on-rails/docs/');
  console.log('');
}

export function validateAppName(name: string): { success: boolean; error?: string } {
  if (!name || name.trim() === '') {
    return { success: false, error: 'App name is required.' };
  }

  if (!/^[a-zA-Z0-9_-]+$/.test(name)) {
    return {
      success: false,
      error: 'App name can only contain letters, numbers, hyphens, and underscores.',
    };
  }

  const appPath = path.resolve(process.cwd(), name);
  if (fs.existsSync(appPath)) {
    return {
      success: false,
      error: `Directory "${name}" already exists. Please choose a different name or remove it.`,
    };
  }

  return { success: true };
}

export function createApp(appName: string, options: CliOptions): void {
  const appPath = path.resolve(process.cwd(), appName);
  const totalSteps = options.rsc ? 5 : 4;
  const generatorStep = options.rsc ? 4 : 3;
  const doneStep = options.rsc ? 5 : 4;
  const reactOnRailsGemPath = localGemPath('REACT_ON_RAILS_GEM_PATH');
  const reactOnRailsProGemPath = localGemPath('REACT_ON_RAILS_PRO_GEM_PATH');

  // Step 1: Create Rails application
  // appName is validated by validateAppName() to be [a-zA-Z0-9_-]+ only,
  // so it's always a simple directory name safe to use with rails new.
  logStep(1, totalSteps, 'Creating Rails application...');
  try {
    execLiveArgs('rails', ['new', appName, '--database=postgresql', '--skip-javascript']);
    logStepDone('Rails application created');
  } catch (error) {
    logError('Failed to create Rails application. Check the output above for details.');
    if (error instanceof Error && error.message) {
      console.error(`Debug info: ${error.message}`);
    }
    process.exit(1);
  }

  // Step 2: Add react_on_rails gem
  logStep(2, totalSteps, 'Adding react_on_rails gem...');
  try {
    const reactOnRailsArgs = ['add', 'react_on_rails', '--strict'];
    if (reactOnRailsGemPath) {
      logInfo(`Using local react_on_rails gem path: ${reactOnRailsGemPath}`);
      reactOnRailsArgs.push('--path', reactOnRailsGemPath);
    }
    execLiveArgs('bundle', reactOnRailsArgs, appPath);
    logStepDone('react_on_rails gem added');
  } catch (error) {
    logError('Failed to add react_on_rails gem. Check the output above for details.');
    if (error instanceof Error && error.message) {
      console.error(`Debug info: ${error.message}`);
    }
    cleanupAppDirectory(
      appPath,
      appName,
      'Directory removed. Fix gem installation access or connectivity issues and rerun.',
      `Delete the created "${appName}" directory and rerun once gem installation issues are resolved.`,
    );
    process.exit(1);
  }

  if (options.rsc) {
    logStep(3, totalSteps, 'Adding react_on_rails_pro gem (--rsc)...');
    try {
      const reactOnRailsProArgs = ['add', 'react_on_rails_pro'];
      if (reactOnRailsProGemPath) {
        logInfo(`Using local react_on_rails_pro gem path: ${reactOnRailsProGemPath}`);
        reactOnRailsProArgs.push('--path', reactOnRailsProGemPath);
      }
      execLiveArgs('bundle', reactOnRailsProArgs, appPath);
      logStepDone('react_on_rails_pro gem added');
    } catch (error) {
      logError('Failed to add react_on_rails_pro gem required by --rsc.');
      if (error instanceof Error && error.message) {
        console.error(`Debug info: ${error.message}`);
      }
      cleanupAppDirectory(
        appPath,
        appName,
        'Directory removed. Configure access to React on Rails Pro gem source and rerun. ' +
          'For custom source/git setups, rerun without --rsc and add react_on_rails_pro manually in Gemfile.',
        `Configure gem source access for react_on_rails_pro, then delete the created "${appName}" directory and rerun with --rsc.`,
      );
      process.exit(1);
    }
  }

  // Step 3: Run react_on_rails generator
  const generatorArgs = buildGeneratorArgs(options);
  logStep(generatorStep, totalSteps, 'Running React on Rails generator...');
  try {
    execLiveArgs(
      'bundle',
      ['exec', 'rails', 'generate', 'react_on_rails:install', ...generatorArgs],
      appPath,
    );
    logStepDone('React on Rails setup complete');
  } catch (error) {
    logError('React on Rails generator failed. Check the output above for details.');
    if (error instanceof Error && error.message) {
      console.error(`Debug info: ${error.message}`);
    }
    process.exit(1);
  }

  // Step 4: Success
  logStep(doneStep, totalSteps, 'Done!');
  printSuccessMessage(appName, options.rsc ? 'hello_server' : 'hello_world');
}
