import { execFileSync, spawnSync } from 'child_process';
import picocolors from 'picocolors';

const CHALK_CI_COLOR_ENV_KEYS = [
  'TRAVIS',
  'CIRCLECI',
  'APPVEYOR',
  'GITLAB_CI',
  'GITHUB_ACTIONS',
  'BUILDKITE',
];
const CHALK_TEAMCITY_COLOR_PATTERN = /^(9\.(0*[1-9]\d*)\.|\d{2,}\.)/;
const CHALK_TERM_256_COLOR_PATTERN = /-256(color)?$/i;
const CHALK_TERM_COLOR_PATTERN = /^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/i;

function hasChalkCompatibleTtyColorSignal(): boolean {
  const { CI, CI_NAME, COLORTERM, TEAMCITY_VERSION, TERM, TERM_PROGRAM } = process.env;

  if (TERM === 'dumb') {
    return false;
  }

  if (process.platform === 'win32') {
    return true;
  }

  if (CI !== undefined) {
    return CHALK_CI_COLOR_ENV_KEYS.some((key) => process.env[key] !== undefined) || CI_NAME === 'codeship';
  }

  if (TEAMCITY_VERSION !== undefined) {
    return CHALK_TEAMCITY_COLOR_PATTERN.test(TEAMCITY_VERSION);
  }

  if (COLORTERM === 'truecolor') {
    return true;
  }

  if (TERM_PROGRAM === 'iTerm.app' || TERM_PROGRAM === 'Apple_Terminal') {
    return true;
  }

  const term = TERM ?? '';

  return (
    CHALK_TERM_256_COLOR_PATTERN.test(term) || CHALK_TERM_COLOR_PATTERN.test(term) || COLORTERM !== undefined
  );
}

/**
 * Decide whether to colorize output, matching what `chalk@4` produced before the
 * chalk→picocolors swap. The scaffolder is a user's first contact with the
 * framework and its logs are often captured, so keeping the same basic
 * colorize/plain decision avoids surprising behavior changes.
 *
 * picocolors' own `isColorSupported` bakes in a different precedence than chalk
 * (it lets NO_COLOR override FORCE_COLOR, and enables color on a bare CI even for
 * piped stdout), so instead of deferring to it we reproduce the relevant chalk@4
 * environment precedence directly and only use picocolors for the actual escape codes:
 *
 *   1. FORCE_COLOR present  → `0`/`false` disables; any other value (incl. empty)
 *      forces color ON, overriding NO_COLOR and a non-TTY stdout.
 *   2. else NO_COLOR present (any value, incl. empty) → disabled.
 *   3. else colorize only for an interactive TTY with one of chalk@4's positive
 *      environment signals. A bare TTY with unset or unrecognized TERM stays
 *      plain, matching supports-color@7.2.0's fallback behavior.
 */
function chalkCompatibleColorEnabled(): boolean {
  const { FORCE_COLOR, NO_COLOR } = process.env;

  if (FORCE_COLOR !== undefined) {
    return FORCE_COLOR !== '0' && FORCE_COLOR !== 'false';
  }
  if (NO_COLOR !== undefined) {
    return false;
  }
  return (process.stdout?.isTTY ?? false) && hasChalkCompatibleTtyColorSignal();
}

export const pc = picocolors.createColors(chalkCompatibleColorEnabled());

function childEnv(env?: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
  // Always inherit PATH, HOME, and the rest of process.env; callers only add/override keys.
  return env ? { ...process.env, ...env } : process.env;
}

/**
 * Execute a command and stream output to the current terminal.
 *
 * Security contract:
 * - This uses `spawnSync` with `shell: false`, so command and args are passed as literal tokens.
 * - Callers must still ensure `command` and `args` come from trusted/validated values.
 */
export function execLiveArgs(command: string, args: string[], cwd?: string, env?: NodeJS.ProcessEnv): void {
  const result = spawnSync(command, args, {
    stdio: 'inherit',
    cwd,
    env: childEnv(env),
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status === null) {
    throw new Error(`Command "${command}" was terminated by ${result.signal ?? 'unknown signal'}`);
  }
  if (result.status !== 0) {
    throw new Error(`Command "${command}" exited with code ${result.status}`);
  }
}

export function execCaptureArgs(
  command: string,
  args: string[],
  cwd?: string,
  env?: NodeJS.ProcessEnv,
): string {
  const result = spawnSync(command, args, {
    stdio: 'pipe',
    encoding: 'utf8',
    cwd,
    env: childEnv(env),
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status === null) {
    throw new Error(`Command "${command}" was terminated by ${result.signal ?? 'unknown signal'}`);
  }
  if (result.status !== 0) {
    const stderr = result.stderr?.trim();
    throw new Error(
      stderr && stderr.length > 0
        ? `Command "${command}" exited with code ${result.status}: ${stderr}`
        : `Command "${command}" exited with code ${result.status}`,
    );
  }

  return result.stdout?.trim() ?? '';
}

export function getCommandVersion(command: string): string | null {
  try {
    return execFileSync(command, ['--version'], { encoding: 'utf8', stdio: 'pipe' }).trim();
  } catch {
    return null;
  }
}

export function detectPackageManager(): 'npm' | 'pnpm' | null {
  const userAgent = process.env.npm_config_user_agent;
  if (userAgent) {
    if (userAgent.startsWith('pnpm')) return 'pnpm';
    if (userAgent.startsWith('npm')) return 'npm';
  }

  if (getCommandVersion('pnpm')) return 'pnpm';
  if (getCommandVersion('npm')) return 'npm';

  return null;
}

export function logStep(current: number, total: number, message: string): void {
  console.log(pc.cyan(`\n[${current}/${total}] ${message}`));
}

export function logStepDone(message: string): void {
  console.log(pc.green(`  ✓ ${message}`));
}

export function logError(message: string): void {
  console.error(pc.red(`\nError: ${message}\n`));
}

export function logSuccess(message: string): void {
  console.log(pc.green(message));
}

export function logInfo(message: string): void {
  console.log(pc.cyan(message));
}
