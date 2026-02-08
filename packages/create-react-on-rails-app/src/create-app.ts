import path from 'path';
import fs from 'fs';
import { CliOptions } from './types.js';
import { execLiveArgs, logStep, logStepDone, logError, logSuccess, logInfo } from './utils.js';

const TOTAL_STEPS = 4;

function buildGeneratorArgs(options: CliOptions): string[] {
  const args: string[] = [];

  if (options.template === 'typescript') {
    args.push('--typescript');
  }

  if (options.rspack) {
    args.push('--rspack');
  }

  args.push('--ignore-warnings');

  return args;
}

function printSuccessMessage(appName: string): void {
  console.log('');
  logSuccess(`Created ${appName} with React on Rails!`);
  console.log('');
  logInfo('Next steps:');
  console.log(`  cd ${appName}`);
  console.log('  bin/dev');
  console.log('');
  logInfo('Then visit http://localhost:3000/hello_world');
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

  // Step 1: Create Rails application
  logStep(1, TOTAL_STEPS, 'Creating Rails application...');
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
  logStep(2, TOTAL_STEPS, 'Adding react_on_rails gem...');
  try {
    execLiveArgs('bundle', ['add', 'react_on_rails', '--strict'], appPath);
    logStepDone('react_on_rails gem added');
  } catch (error) {
    logError('Failed to add react_on_rails gem. Check the output above for details.');
    if (error instanceof Error && error.message) {
      console.error(`Debug info: ${error.message}`);
    }
    process.exit(1);
  }

  // Step 3: Run react_on_rails generator
  const generatorArgs = buildGeneratorArgs(options);
  logStep(3, TOTAL_STEPS, 'Running React on Rails generator...');
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
  logStep(4, TOTAL_STEPS, 'Done!');
  printSuccessMessage(appName);
}
