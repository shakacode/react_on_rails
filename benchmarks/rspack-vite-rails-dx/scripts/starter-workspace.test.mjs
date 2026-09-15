import assert from 'node:assert/strict';
import test from 'node:test';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { createWorkspace, prepareWorkspaces } from './starter-workspace.mjs';

test('copies a starter, links dependencies, and mutates only the copy', async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ror-rails-dx-'));
  const source = path.join(root, 'starters/rspack');
  const component = path.join(source, 'app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx');
  try {
    await mkdir(path.dirname(component), { recursive: true });
    await mkdir(path.join(source, 'node_modules'));
    await writeFile(component, "const BENCHMARK_MARKER = 'benchmark-initial';\n");
    await prepareWorkspaces(root);
    const workspace = await createWorkspace(root, 'rspack', 'test');
    await workspace.setMarker('changed');
    assert.match(await readFile(workspace.messagePath, 'utf8'), /'changed'/);
    assert.match(await readFile(component, 'utf8'), /'benchmark-initial'/);
    await workspace.remove();
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
