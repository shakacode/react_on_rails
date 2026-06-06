import { spawnSync } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';

const smokeScriptPath = path.resolve(__dirname, '../scripts/smoke-test-local-gems.sh');

function extractBashFunction(source: string, functionName: string): string {
  const startMarker = `${functionName}() {`;
  const startIndex = source.indexOf(startMarker);
  if (startIndex === -1) {
    throw new Error(`Could not find ${functionName} in ${smokeScriptPath}`);
  }

  const functionLines: string[] = [];
  let braceDepth = 0;
  for (const line of source.slice(startIndex).split('\n')) {
    functionLines.push(line);
    for (const char of line) {
      if (char === '{') braceDepth += 1;
      if (char === '}') braceDepth -= 1;
    }

    if (braceDepth === 0) return functionLines.join('\n');
  }

  throw new Error(`Could not parse ${functionName} in ${smokeScriptPath}`);
}

describe('smoke-test-local-gems.sh', () => {
  const smokeScript = fs.readFileSync(smokeScriptPath, 'utf8');

  it('reports a missing generated app directory without leaking pushd output', () => {
    const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'ror-smoke-test-'));
    const missingAppDir = path.join(tempRoot, 'missing-app');
    const harness = [
      'set -Eeuo pipefail',
      'PNPM_CMD=(false)',
      extractBashFunction(smokeScript, 'verify_generated_app_runtime'),
      'verify_generated_app_runtime "$1"',
    ].join('\n');

    try {
      const result = spawnSync('bash', ['-c', harness, 'smoke-harness', missingAppDir], {
        encoding: 'utf8',
      });

      expect(result.status).toBe(1);
      expect(result.stdout).toContain('Building test bundles for missing-app...');
      expect(result.stderr).toContain(`Generated app directory is missing for missing-app: ${missingAppDir}`);
      expect(result.stderr).not.toContain('pushd:');
    } finally {
      fs.rmSync(tempRoot, { recursive: true, force: true });
    }
  });
});
