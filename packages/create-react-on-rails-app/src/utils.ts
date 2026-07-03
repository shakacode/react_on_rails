import { execFileSync, spawnSync } from 'child_process';
import picocolors from 'picocolors';

/**
 * Shared color instance, reused by other modules.
 *
 * We start from picocolors' own color detection and layer two overrides so the
 * output matches what `chalk@4` produced before the swap (the scaffolder is a
 * user's first contact with the framework, and its logs are often captured):
 *
 *  1. picocolors enables color whenever `FORCE_COLOR` is merely present
 *     (`!!env.FORCE_COLOR`), so `FORCE_COLOR=0` / `FORCE_COLOR=false` would turn
 *     color ON. chalk@4 parsed that value and treated `0`/`false` as disabled.
 *  2. picocolors enables color whenever `!!env.CI` is set, even for non-TTY
 *     (piped) stdout. chalk@4 did not: in CI with piped output it stayed plain
 *     unless FORCE_COLOR or a TTY was present, so a bare `CI` must not force
 *     ANSI escapes into captured logs.
 *
 * Everything else (NO_COLOR incl. empty, FORCE_COLOR truthy, real TTY, --color)
 * is left to picocolors, keeping the override surface small.
 */
const forceColor = 'FORCE_COLOR' in process.env ? process.env.FORCE_COLOR : undefined;
const forceColorEnabled = forceColor !== undefined && forceColor !== '0' && forceColor !== 'false';
const forceColorDisabled = forceColor === '0' || forceColor === 'false';
const enabledByTty = (process.stdout?.isTTY ?? false) && process.env.TERM !== 'dumb';
// Color is enabled only when picocolors already wants it AND that is not solely
// because of CI (an explicit FORCE_COLOR/TTY signal must also be present).
const colorEnabled =
  !forceColorDisabled &&
  picocolors.isColorSupported &&
  (forceColorEnabled || enabledByTty || !process.env.CI);

export const pc = picocolors.createColors(colorEnabled);

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
