import { execFileSync, spawnSync } from 'child_process';
import picocolors from 'picocolors';

/**
 * Decide whether to colorize output, matching what `chalk@4` produced before the
 * chalk→picocolors swap. The scaffolder is a user's first contact with the
 * framework and its logs are often captured, so keeping the exact same
 * colorize/plain decision avoids surprising behavior changes.
 *
 * picocolors' own `isColorSupported` bakes in a different precedence than chalk
 * (it lets NO_COLOR override FORCE_COLOR, and enables color on a bare CI even for
 * piped stdout), so instead of deferring to it we reproduce chalk@4's precedence
 * directly and only use picocolors for the actual escape codes:
 *
 *   1. FORCE_COLOR present  → `0`/`false` disables; any other value (incl. empty)
 *      forces color ON, overriding NO_COLOR and a non-TTY stdout.
 *   2. else NO_COLOR present (any value, incl. empty) → disabled.
 *   3. else colorize only for an interactive TTY (a bare CI does not force color).
 */
function chalkCompatibleColorEnabled(): boolean {
  const { FORCE_COLOR, NO_COLOR, TERM } = process.env;

  if (FORCE_COLOR !== undefined) {
    return FORCE_COLOR !== '0' && FORCE_COLOR !== 'false';
  }
  if (NO_COLOR !== undefined) {
    return false;
  }
  return (process.stdout?.isTTY ?? false) && TERM !== 'dumb';
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
