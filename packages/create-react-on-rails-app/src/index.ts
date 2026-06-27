import { Command } from 'commander';
import chalk from 'chalk';
import { CliOptions } from './types.js';
import { validateAll } from './validators.js';
import { createApp, validateAppName } from './create-app.js';
import type { ResolvedSetupMode } from './mode.js';
import { resolveSetupMode } from './mode.js';
import { detectPackageManager, logError, logInfo } from './utils.js';

// Use require() for CJS compatibility - avoids __dirname + fs.readFileSync
// eslint-disable-next-line @typescript-eslint/no-require-imports, global-require
const packageJson = require('../package.json') as { version: string };

function run(appName: string, rawOpts: Record<string, unknown>, command?: Command): void {
  const { template: rawTemplate } = rawOpts;
  if (typeof rawTemplate !== 'string' || (rawTemplate !== 'javascript' && rawTemplate !== 'typescript')) {
    logError(`Invalid template "${String(rawTemplate)}". Must be "javascript" or "typescript".`);
    process.exit(1);
    return;
  }
  const template = rawTemplate;

  let packageManager = rawOpts.packageManager as string | undefined;
  if (packageManager) {
    if (packageManager !== 'npm' && packageManager !== 'pnpm') {
      logError(`Invalid package manager "${packageManager}". Must be "npm" or "pnpm".`);
      process.exit(1);
    }
  } else {
    packageManager = detectPackageManager() ?? 'npm';
  }

  let setupMode: ResolvedSetupMode;
  try {
    setupMode = resolveSetupMode(rawOpts);
  } catch (error) {
    logError(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
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

  console.log('');
  console.log(`${chalk.bold('create-react-on-rails-app')} v${packageJson.version}`);
  console.log('');

  const nameValidation = validateAppName(appName);
  if (!nameValidation.success) {
    logError(nameValidation.error ?? 'Invalid app name');
    process.exit(1);
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
    tailwind: Boolean(rawOpts.tailwind),
    pro: setupMode.pro,
    rsc: setupMode.rsc,
    // Commander's `--no-agent-files` declares a default of true on rawOpts.agentFiles,
    // so undefined (no flag) and true (default) both map to true; only --no-agent-files
    // sets it false.
    agentFiles: (rawOpts.agentFiles ?? true) === true,
    cliVersion: packageJson.version,
  };

  if (setupMode.defaulted) {
    logInfo(
      'Default setup: React on Rails Pro for React 19.2 support. Use --standard only when you intentionally want an open-source-only setup.',
    );
  }

  if (setupMode.requiresPro) {
    const modeFlag = options.rsc ? '--rsc' : '--pro';
    const setupLabel = setupMode.defaulted ? 'The default setup' : modeFlag;
    logInfo(`Note: ${setupLabel} adds react_on_rails_pro and uses the Pro generator path.`);
    logInfo('If installation fails, verify your Bundler/RubyGems setup, then rerun the command.');
    logInfo('Pro setup docs: https://reactonrails.com/docs/pro/installation/');
    logInfo('Pro pricing and sign up: https://pro.reactonrails.com/');
    logInfo(
      'License: no token is required for development, test, CI/CD, or staging. Production Pro deployments need a paid license, with free or low-cost options for startups and small projects.',
    );
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
    modeLabel = ', setup: pro with RSC example';
  } else if (options.pro) {
    modeLabel = ', setup: pro without RSC example';
  } else {
    modeLabel = ', setup: open-source-only';
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
  .option('--standard', 'Advanced: generate open-source React on Rails without Pro React 19.2 features')
  .option('--pro', 'Generate the default React on Rails Pro setup explicitly')
  .option('--rsc', 'Advanced: generate React on Rails Pro with the RSC example')
  .option('--no-agent-files', 'Skip AI-agent guidance files (AGENTS.md + editor pointers)')
  .addHelpText(
    'after',
    `
Examples:
  $ npx create-react-on-rails-app my-app                        # default: Pro for React 19.2 support
  $ npx create-react-on-rails-app my-app --template javascript
  $ npx create-react-on-rails-app my-app --no-rspack             # use Webpack instead of Rspack
  $ npx create-react-on-rails-app my-app --webpack               # same as --no-rspack
  $ npx create-react-on-rails-app my-app --tailwind
  $ npx create-react-on-rails-app my-app --pro                   # explicit default Pro setup
  $ npx create-react-on-rails-app my-app --rsc                   # advanced: Pro with RSC example
  $ npx create-react-on-rails-app my-app --standard              # advanced: OSS-only setup
  $ npx create-react-on-rails-app my-app --no-rspack --rsc
  $ npx create-react-on-rails-app my-app --package-manager pnpm
  $ npx create-react-on-rails-app my-app --no-agent-files            # skip AGENTS.md + editor pointers

No setup questions are asked. New apps use React on Rails Pro by default because
that is where React 19.2 feature support lives. Use --standard only when you
intentionally want an open-source-only scaffold. Use --rsc when you want the
generated React Server Components example.

Pro license note: no token is required for development, test, CI/CD, or
staging. Production Pro deployments need a paid license, with free or low-cost
options for startups and small projects. See pricing and sign up:
https://pro.reactonrails.com/

What it does:
  1. Creates a new Rails app with PostgreSQL
  2. Adds required gem(s) (react_on_rails, plus react_on_rails_pro unless --standard)
  3. Runs the React on Rails generator (Shakapacker, components, webpack config)
  4. Creates educational git commits for each major scaffold step

After setup, run bin/dev and visit:
  - http://localhost:3000 (generated home page)
  - /hello_world (default, --standard, and --pro example page)
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
  .action((appName: string, opts: Record<string, unknown>, command: Command) => {
    try {
      run(appName, opts, command);
    } catch (error) {
      logError(error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// eslint-disable-next-line import/prefer-default-export -- named export for test clarity
export const ready = program.parseAsync().catch((error: unknown) => {
  logError(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
