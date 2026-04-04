import { Command } from 'commander';
import chalk from 'chalk';
import { CliOptions } from './types.js';
import { validateAll } from './validators.js';
import { createApp, validateAppName } from './create-app.js';
import { detectPackageManager, logError, logInfo } from './utils.js';
import { promptForMode, PROMPT_CANCELLED_BY_SIGINT } from './prompt.js';

// Use require() for CJS compatibility - avoids __dirname + fs.readFileSync
// eslint-disable-next-line @typescript-eslint/no-require-imports, global-require
const packageJson = require('../package.json') as { version: string };

async function run(appName: string, rawOpts: Record<string, unknown>): Promise<void> {
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

  let pro = Boolean(rawOpts.pro);
  let rsc = Boolean(rawOpts.rsc);

  console.log('');
  console.log(`${chalk.bold('create-react-on-rails-app')} v${packageJson.version}`);
  console.log('');

  const nameValidation = validateAppName(appName);
  if (!nameValidation.success) {
    logError(nameValidation.error ?? 'Invalid app name');
    process.exit(1);
  }

  // When no mode flag is explicitly passed, prompt interactively (TTY only).
  // Non-interactive environments (CI, pipes) fall back to standard mode.
  const modeExplicit = rawOpts.pro !== undefined || rawOpts.rsc !== undefined;
  if (!modeExplicit) {
    if (process.stdin.isTTY) {
      const choice = await promptForMode();
      pro = choice.pro;
      rsc = choice.rsc;
    } else {
      logInfo('No mode flag specified and stdin is not a TTY; using standard mode.');
    }
  }

  const options: CliOptions = {
    template,
    packageManager: packageManager as 'npm' | 'pnpm',
    rspack: Boolean(rawOpts.rspack),
    pro,
    rsc,
  };

  if (options.rsc && options.pro) {
    logInfo('Note: --rsc takes precedence over --pro; --pro will be ignored.');
  }

  if (options.rsc || options.pro) {
    const modeFlag = options.rsc ? '--rsc' : '--pro';
    logInfo(`Note: ${modeFlag} installs react_on_rails_pro and requires that gem to be installable.`);
    logInfo(
      `If installation fails, verify your Bundler/RubyGems setup for react_on_rails_pro, then rerun with ${modeFlag}.`,
    );
    logInfo('Pro setup docs: https://reactonrails.com/docs/pro/installation/');
    console.log('');
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
  let modeLabel = '';
  if (options.rsc) {
    modeLabel = ', mode: rsc';
  } else if (options.pro) {
    modeLabel = ', mode: pro';
  }
  logInfo(
    `Creating "${appName}" with template: ${options.template}, package manager: ${options.packageManager}${options.rspack ? ', bundler: rspack' : ''}${modeLabel}`,
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
  .option('--pro', 'Generate React on Rails Pro setup (installs react_on_rails_pro)')
  .option('--rsc', 'Generate React Server Components setup (installs react_on_rails_pro)')
  .addHelpText(
    'after',
    `
Examples:
  $ npx create-react-on-rails-app my-app                        # prompts for mode
  $ npx create-react-on-rails-app my-app --rsc                  # skip prompt, use RSC
  $ npx create-react-on-rails-app my-app --pro                  # skip prompt, use Pro
  $ npx create-react-on-rails-app my-app --template javascript
  $ npx create-react-on-rails-app my-app --rspack
  $ npx create-react-on-rails-app my-app --rspack --rsc
  $ npx create-react-on-rails-app my-app --package-manager pnpm

When no --pro or --rsc flag is given, an interactive prompt lets you choose
between Standard, Pro, and RSC modes (default: RSC). When stdin is not a TTY
(for example in CI or with redirected input), standard mode is used automatically.

What it does:
  1. Creates a new Rails app with PostgreSQL
  2. Adds required gem(s) (react_on_rails, plus react_on_rails_pro for Pro/RSC)
  3. Runs the React on Rails generator (Shakapacker, components, webpack config)
  4. Creates educational git commits for each major scaffold step

After setup, run bin/dev and visit:
  - http://localhost:3000 (generated home page)
  - /hello_world (default and --pro example page)
  - /hello_server (--rsc example page)

Inspect the generated setup history with:
  - git log --oneline --reverse

The generated app includes one git commit per logical setup step.`,
  )
  .addHelpText(
    'after',
    `
--pro and --rsc support both JavaScript and TypeScript templates.

Documentation: https://reactonrails.com/docs/`,
  )
  .action(async (appName: string, opts: Record<string, unknown>) => {
    try {
      await run(appName, opts);
    } catch (error) {
      if (error instanceof Error && error.message === PROMPT_CANCELLED_BY_SIGINT) {
        console.log('');
        process.exit(0);
      }
      logError(error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program.parseAsync().catch((error: unknown) => {
  logError(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
