import { Command } from 'commander';
import chalk from 'chalk';
import { CliOptions } from './types.js';
import { validateAll } from './validators.js';
import { createApp, validateAppName } from './create-app.js';
import { detectPackageManager, logError, logInfo } from './utils.js';
import { promptForMode, promptForTailwind, PROMPT_CANCELLED } from './prompt.js';

// Use require() for CJS compatibility - avoids __dirname + fs.readFileSync
// eslint-disable-next-line @typescript-eslint/no-require-imports, global-require
const packageJson = require('../package.json') as { version: string };

async function run(appName: string, rawOpts: Record<string, unknown>, command?: Command): Promise<void> {
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

  if (rawOpts.standard && (rawOpts.pro || rawOpts.rsc)) {
    logError('--standard cannot be combined with --pro or --rsc.');
    process.exit(1);
  }

  // --webpack is a friendly alias for --no-rspack. Commander reports --no-rspack's declared
  // default as rawOpts.rspack === true, so we use the option source to distinguish an explicit
  // --rspack from the default and reject contradictory flags (--rspack --webpack).
  const rspackExplicitlyTrue = rawOpts.rspack === true && command?.getOptionValueSource('rspack') === 'cli';
  const webpackRequested = rawOpts.webpack === true;
  if (webpackRequested && rspackExplicitlyTrue) {
    logError(
      'Conflicting bundler flags: pass either --rspack or --webpack (alias for --no-rspack), not both.',
    );
    process.exit(1);
  }

  let pro = Boolean(rawOpts.pro);
  let rsc = Boolean(rawOpts.rsc);
  let tailwind = Boolean(rawOpts.tailwind);

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
  const modeExplicit =
    rawOpts.pro !== undefined || rawOpts.rsc !== undefined || rawOpts.standard !== undefined;
  if (!modeExplicit) {
    if (process.stdin.isTTY && process.stdout.isTTY) {
      const choice = await promptForMode();
      pro = choice.pro;
      rsc = choice.rsc;
      if (rawOpts.tailwind === undefined) {
        tailwind = await promptForTailwind();
      }
    } else {
      logInfo(
        'No mode flag specified and not running interactively (stdin/stdout is not a TTY); using standard mode.',
      );
    }
  }

  const options: CliOptions = {
    template,
    packageManager: packageManager as 'npm' | 'pnpm',
    // Rspack is the default; an explicit --no-rspack or its --webpack alias selects Webpack.
    // (rawOpts.rspack ?? true) makes the three inputs explicit: undefined (no flag) -> true,
    // true (--rspack) -> true, false (--no-rspack) -> false.
    // Footgun: re-adding `.option('--rspack', desc, false)` would default rawOpts.rspack to
    // false and silently flip the default back to Webpack.
    // Note: buildGeneratorArgs always forwards an explicit --rspack/--no-rspack to the Ruby
    // generator, so the generator's own fresh-install fallback (fresh_install_rspack_default,
    // which consults the Shakapacker version) is never reached via create-react-on-rails-app.
    rspack: webpackRequested ? false : (rawOpts.rspack ?? true) === true,
    tailwind,
    pro,
    rsc,
    // Commander's `--no-agent-files` declares a default of true on rawOpts.agentFiles,
    // so undefined (no flag) and true (default) both map to true; only --no-agent-files
    // sets it false.
    agentFiles: (rawOpts.agentFiles ?? true) === true,
    cliVersion: packageJson.version,
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
  const tailwindLabel = options.tailwind ? ', Tailwind CSS v4' : '';
  logInfo(
    `Creating "${appName}" with template: ${options.template}, package manager: ${options.packageManager}, bundler: ${options.rspack ? 'rspack' : 'webpack'}${modeLabel}${tailwindLabel}`,
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
  .option('--rspack', 'Use Rspack as the bundler (default, ~20x faster builds)')
  .option('--no-rspack', 'Use Webpack instead of Rspack')
  .option('--webpack', 'Use Webpack as the bundler (alias for --no-rspack)')
  .option('--tailwind', 'Install Tailwind CSS v4 and style the generated SSR example')
  .option('--standard', 'Generate open-source React on Rails setup (skip prompt)')
  .option('--pro', 'Generate React on Rails Pro setup (installs react_on_rails_pro)')
  .option('--rsc', 'Generate React Server Components setup (installs react_on_rails_pro)')
  .option('--no-agent-files', 'Skip AI-agent guidance files (AGENTS.md + editor pointers)')
  .addHelpText(
    'after',
    `
Examples:
  $ npx create-react-on-rails-app my-app                        # prompts for mode
  $ npx create-react-on-rails-app my-app --rsc                  # skip prompt, use RSC
  $ npx create-react-on-rails-app my-app --pro                  # skip prompt, use Pro
  $ npx create-react-on-rails-app my-app --standard             # skip prompt, use Standard
  $ npx create-react-on-rails-app my-app --template javascript
  $ npx create-react-on-rails-app my-app --no-rspack             # use Webpack instead of Rspack
  $ npx create-react-on-rails-app my-app --webpack               # same as --no-rspack
  $ npx create-react-on-rails-app my-app --tailwind
  $ npx create-react-on-rails-app my-app --no-rspack --rsc
  $ npx create-react-on-rails-app my-app --package-manager pnpm
  $ npx create-react-on-rails-app my-app --no-agent-files            # skip AGENTS.md + editor pointers

When no mode flag (--standard, --pro, or --rsc) is given, an interactive prompt
lets you choose between Standard, Pro, and RSC modes (default: RSC). When stdin
or stdout is not a TTY (for example in CI, piped input, or redirected output),
standard mode is used automatically.

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
  .action(async (appName: string, opts: Record<string, unknown>, command: Command) => {
    try {
      await run(appName, opts, command);
    } catch (error) {
      if (error instanceof Error && error.message === PROMPT_CANCELLED) {
        console.log('');
        process.exit(0);
      }
      logError(error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// eslint-disable-next-line import/prefer-default-export -- named export for test clarity
export const ready = program.parseAsync().catch((error: unknown) => {
  logError(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
