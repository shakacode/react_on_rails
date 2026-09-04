import { cp, lstat, mkdir, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import path from 'node:path';

const temporaryDirectoryName = '.work';
const excludedNames = new Set(['.bundle', '.overmind.sock', 'log', 'node_modules', 'tmp', 'vendor']);

export async function prepareWorkspaces(root) {
  await rm(path.join(root, temporaryDirectoryName), { recursive: true, force: true });
  await mkdir(path.join(root, temporaryDirectoryName), { recursive: true });
}

export async function createWorkspace(root, tool, nonce) {
  const source = path.join(root, 'starters', tool);
  const destination = path.join(root, temporaryDirectoryName, `${tool}-${nonce}`);
  await cp(source, destination, {
    recursive: true,
    filter(candidate) {
      return candidate === source || !excludedNames.has(path.basename(candidate));
    },
  });
  const dependencyPath = path.join(source, 'node_modules');
  if (!(await lstat(dependencyPath)).isDirectory()) throw new Error(`${tool} node_modules is not installed`);
  await symlink(dependencyPath, path.join(destination, 'node_modules'), 'dir');
  await mkdir(path.join(destination, 'log'), { recursive: true });
  await mkdir(path.join(destination, 'tmp'), { recursive: true });
  return {
    directory: destination,
    messagePath:
      tool === 'rspack'
        ? path.join(destination, 'app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx')
        : path.join(destination, 'app/frontend/pages/inertia_example/index.tsx'),
    async setMarker(marker) {
      const contents = await readFile(this.messagePath, 'utf8');
      const updated = contents.replace(
        /const BENCHMARK_MARKER = '[^']+'/,
        `const BENCHMARK_MARKER = '${marker}'`,
      );
      if (updated === contents) throw new Error(`benchmark marker was not found in ${tool} starter`);
      await writeFile(this.messagePath, updated);
    },
    async remove() {
      await rm(destination, { recursive: true, force: true });
    },
  };
}

export async function removeWorkspaces(root) {
  await rm(path.join(root, temporaryDirectoryName), { recursive: true, force: true });
}
