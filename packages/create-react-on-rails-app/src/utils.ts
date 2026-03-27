import { execFileSync, spawnSync } from 'child_process';
import chalk from 'chalk';

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
    ...(env ? { env } : {}),
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(`Command "${command}" exited with code ${result.status}`);
  }
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
  console.log(chalk.cyan(`\n[${current}/${total}] ${message}`));
}

export function logStepDone(message: string): void {
  console.log(chalk.green(`  ✓ ${message}`));
}

export function logError(message: string): void {
  console.error(chalk.red(`\nError: ${message}\n`));
}

export function logSuccess(message: string): void {
  console.log(chalk.green(message));
}

export function logInfo(message: string): void {
  console.log(chalk.cyan(message));
}
