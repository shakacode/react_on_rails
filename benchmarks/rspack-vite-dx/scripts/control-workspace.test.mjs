import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { createControlWorkspace, prepareControlWorkspaces } from './control-workspace.mjs';

test('benchmark mutations remain isolated from the tracked control', async () => {
  const benchmarkRoot = await mkdtemp(path.join(os.tmpdir(), 'rspack-vite-benchmark-'));
  const canonicalMessage = path.join(benchmarkRoot, 'controls', 'vite', 'src', 'message.js');
  await mkdir(path.dirname(canonicalMessage), { recursive: true });
  await writeFile(canonicalMessage, "export default 'ready';\n");

  try {
    await prepareControlWorkspaces(benchmarkRoot);
    const workspace = await createControlWorkspace(benchmarkRoot, 'vite', 'run-nonce');
    await writeFile(workspace.messagePath, "export default 'measured';\n");

    assert.equal(await readFile(canonicalMessage, 'utf8'), "export default 'ready';\n");
    assert.equal(await readFile(workspace.messagePath, 'utf8'), "export default 'measured';\n");
    await workspace.remove();
  } finally {
    await rm(benchmarkRoot, { recursive: true, force: true });
  }
});
