import { execFileSync, spawnSync } from 'child_process';
import picocolors from 'picocolors';

/**
 * picocolors' default instance only presence-checks `FORCE_COLOR` (`"FORCE_COLOR" in env`),
 * so `FORCE_COLOR=0` / `FORCE_COLOR=false` incorrectly ENABLE color. chalk@4 parsed the
 * value and treated `0`/`false` as disabled. Restore that semantics here so callers/CI that
 * set `FORCE_COLOR=0` for plain-text logs keep getting plain text after the chalk→picocolors swap.
 *
 * Priority: NO_COLOR disables; FORCE_COLOR=0/false disables; FORCE_COLOR present & truthy enables;
 * otherwise defer to picocolors' own TTY/CI detection.
 */
function resolveColorEnabled(): boolean {
  if (process.env.NO_COLOR) return false;

  const forceColor = process.env.FORCE_COLOR;
  if (forceColor !== undefined) {
    if (forceColor === '0' || forceColor === 'false') return false;
    return true;
  }

  return picocolors.isColorSupported;
}

/** Shared color instance with chalk-compatible FORCE_COLOR handling; reused by other modules. */
export const pc = picocolors.createColors(resolveColorEnabled());

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
