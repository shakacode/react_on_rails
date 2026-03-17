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
  if (!fs.existsSync(appPath)) {
    return;
  }

  logInfo(`Cleaning up "${appName}" directory...`);
  try {
    fs.rmSync(appPath, { recursive: true, force: true });
    logInfo(cleanupSuccessMessage);
  } catch {
    logError(cleanupFallbackMessage);
  }
}

function localGemPath(envVarName: string): string | null {
  const value = process.env[envVarName];
  if (!value || value.trim() === '') {
    return null;
  }

  const resolvedPath = path.resolve(value);
  if (!fs.existsSync(resolvedPath)) {
    logError(`Local gem path from ${envVarName} does not exist: ${resolvedPath}`);
    process.exit(1);
  }

  return resolvedPath;
}

function bundleAddArgs(gemName: string, localPath: string | null, strict: boolean = true): string[] {
  const args = ['add', gemName];

  if (localPath) {
    args.push('--path', localPath);
  } else if (strict) {
    args.push('--strict');
  }

  return args;
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
  logInfo('Documentation: https://reactonrails.com/docs/');
  console.log('');
}

export function validateAppName(name: string): { success: boolean; error?: string } {
  if (!name) {
    return { success: false, error: 'App name is required.' };
  }

  const trimmedName = name.trim();

  if (!trimmedName) {
    return { success: false, error: 'App name is required.' };
  }

  if (!/^[a-zA-Z][a-zA-Z0-9]*([_-][a-zA-Z0-9]+)*$/.test(trimmedName)) {
    return {
      success: false,
      error:
        'App name must start with a letter, end with a letter or number, and may contain hyphens or underscores only between alphanumeric characters.',
    };
  }

  const appPath = path.resolve(process.cwd(), trimmedName);
  if (fs.existsSync(appPath)) {
    return {
      success: false,
      error: `Directory "${trimmedName}" already exists. Please choose a different name or remove it.`,
    };
  }

  return { success: true };
}

export function createApp(appName: string, options: CliOptions): void {
  const appPath = path.resolve(process.cwd(), appName);
  const baseSteps = 3; // rails new + add react_on_rails + run generator
  const totalSteps = baseSteps + (options.rsc ? 1 : 0);
  let currentStep = 1;
  const reactOnRailsGemPath = localGemPath('REACT_ON_RAILS_GEM_PATH');
  const reactOnRailsProGemPath = options.rsc ? localGemPath('REACT_ON_RAILS_PRO_GEM_PATH') : null;

  // Step 1: Create Rails application
  // appName is validated by validateAppName() to be ^[a-zA-Z][a-zA-Z0-9]*([_-][a-zA-Z0-9]+)*$ only,
  // so it's always a simple directory name safe to use with rails new.
  logStep(currentStep, totalSteps, 'Creating Rails application...');
  try {
    execLiveArgs('rails', ['new', appName, '--database=postgresql', '--skip-javascript']);
    logStepDone('Rails application created');
  } catch (error) {
    logError('Failed to create Rails application. Check the output above for details.');
    if (error instanceof Error && error.message) {
      console.error(`Debug info: ${error.message}`);
    }
    cleanupAppDirectory(
      appPath,
      appName,
      'Directory removed. Fix the Rails app creation issue and rerun.',
      `Delete the created "${appName}" directory and rerun once the Rails app creation issue is resolved.`,
    );
    process.exit(1);
  }

  // Step 2: Add react_on_rails gem
  currentStep += 1;
  logStep(currentStep, totalSteps, 'Adding react_on_rails gem...');
  try {
    const reactOnRailsArgs = bundleAddArgs('react_on_rails', reactOnRailsGemPath);
    if (reactOnRailsGemPath) {
      logInfo(`Using local react_on_rails gem path: ${reactOnRailsGemPath}`);
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
    currentStep += 1;
    logStep(currentStep, totalSteps, 'Adding react_on_rails_pro gem (--rsc)...');
    try {
      const reactOnRailsProArgs = bundleAddArgs('react_on_rails_pro', reactOnRailsProGemPath, false);
      if (reactOnRailsProGemPath) {
        logInfo(`Using local react_on_rails_pro gem path: ${reactOnRailsProGemPath}`);
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
        'Directory removed. Ensure react_on_rails_pro is installable in your Bundler/RubyGems setup, then rerun with --rsc.',
        `Ensure react_on_rails_pro is installable, then delete the created "${appName}" directory and rerun with --rsc.`,
      );
      process.exit(1);
    }
  }

  // Final generator step
  const generatorArgs = buildGeneratorArgs(options);
  currentStep += 1;
  logStep(currentStep, totalSteps, 'Running React on Rails generator...');
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
    cleanupAppDirectory(
      appPath,
      appName,
      'Directory removed. Fix the generator issue and rerun.',
      `Delete the created "${appName}" directory and rerun once the generator issue is resolved.`,
    );
    process.exit(1);
  }

  // Final success
  logStepDone('Done!');
  printSuccessMessage(appName, options.rsc ? 'hello_server' : 'hello_world');
}
