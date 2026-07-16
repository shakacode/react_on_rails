import { cp, mkdir, rm } from 'node:fs/promises';
import path from 'node:path';

const temporaryDirectoryName = '.tmp-controls';

export async function prepareControlWorkspaces(benchmarkRoot) {
  const temporaryRoot = path.join(benchmarkRoot, temporaryDirectoryName);
  await rm(temporaryRoot, { recursive: true, force: true });
  await mkdir(temporaryRoot, { recursive: true });
}

export async function createControlWorkspace(benchmarkRoot, tool, runNonce) {
  const sessionDirectory = path.join(benchmarkRoot, temporaryDirectoryName, runNonce);
  const controlDirectory = path.join(sessionDirectory, tool);
  await mkdir(sessionDirectory, { recursive: true });
  await cp(path.join(benchmarkRoot, 'controls', tool), controlDirectory, { recursive: true });

  return {
    controlDirectory,
    messagePath: path.join(controlDirectory, 'src', 'message.js'),
    async remove() {
      await rm(sessionDirectory, { recursive: true, force: true });
    },
  };
}

export async function removeControlWorkspaces(benchmarkRoot) {
  await rm(path.join(benchmarkRoot, temporaryDirectoryName), { recursive: true, force: true });
}
