import { Command } from 'commander';
import chalk from 'chalk';
import { CliOptions } from './types.js';
import { validateAll } from './validators.js';
import { createApp, validateAppName } from './create-app.js';
import { detectPackageManager, logError, logInfo } from './utils.js';

// Use require() for CJS compatibility - avoids __dirname + fs.readFileSync
// eslint-disable-next-line @typescript-eslint/no-require-imports, global-require
const packageJson = require('../package.json') as { version: string };

function run(appName: string, rawOpts: Record<string, unknown>): void {
  const { template } = rawOpts;
  if (typeof template !== 'string' || (template !== 'javascript' && template !== 'typescript')) {
    logError(`Invalid template "${String(template)}". Must be "javascript" or "typescript".`);
    process.exit(1);
  }

  let packageManager = rawOpts.packageManager as string | undefined;
  if (packageManager) {
    if (packageManager !== 'npm' && packageManager !== 'pnpm') {
      logError(`Invalid package manager "${packageManager}". Must be "npm" or "pnpm".`);
      process.exit(1);
    }
  } else {
    packageManager = detectPackageManager() ?? 'npm';
  }

  const options: CliOptions = {
    template,
    packageManager: packageManager as 'npm' | 'pnpm',
    rspack: Boolean(rawOpts.rspack),
  };

  console.log('');
  console.log(`${chalk.bold('create-react-on-rails-app')} v${packageJson.version}`);
  console.log('');

  const nameValidation = validateAppName(appName);
  if (!nameValidation.success) {
    logError(nameValidation.error ?? 'Invalid app name');
    process.exit(1);
  }

  logInfo('Checking prerequisites...');
  const { allValid, results } = validateAll(options.packageManager);

  for (const { name, result } of results) {
    if (result.valid) {
      console.log(chalk.green(`  ✓ ${name}: ${result.message}`));
    } else {
      console.log(chalk.red(`  ✗ ${name}`));
    }
  }

  if (!allValid) {
    console.log('');
    for (const { result } of results) {
      if (!result.valid) {
        logError(result.message);
      }
    }
    process.exit(1);
  }

  console.log('');
  logInfo(
    `Creating "${appName}" with template: ${options.template}, package manager: ${options.packageManager}${options.rspack ? ', bundler: rspack' : ''}`,
  );

  createApp(appName, options);
}

const program = new Command();

program
  .name('create-react-on-rails-app')
  .description(
    'Create a new React on Rails application with a single command.\n\n' +
      'Sets up a Rails app with React, Webpack/Rspack, server-side rendering,\n' +
      'and hot module replacement - ready to develop in minutes.',
  )
  .version(packageJson.version)
  .argument('<app-name>', 'Name of the application to create')
  .option('-t, --template <type>', 'javascript or typescript', 'typescript')
  .option('-p, --package-manager <pm>', 'npm or pnpm (auto-detected if not specified)')
  .option('--rspack', 'Use Rspack instead of Webpack (~20x faster builds)', false)
  .addHelpText(
    'after',
    `
Examples:
  $ npx create-react-on-rails-app my-app
  $ npx create-react-on-rails-app my-app --template javascript
  $ npx create-react-on-rails-app my-app --rspack
  $ npx create-react-on-rails-app my-app --package-manager pnpm

What it does:
  1. Creates a new Rails app with PostgreSQL
  2. Adds the react_on_rails gem
  3. Runs the React on Rails generator (Shakapacker, components, webpack config)

After setup, run bin/dev and visit http://localhost:3000/hello_world

Documentation: https://www.shakacode.com/react-on-rails/docs/`,
  )
  .action((appName: string, opts: Record<string, unknown>) => {
    try {
      run(appName, opts);
    } catch (error) {
      logError(error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program.parse();
