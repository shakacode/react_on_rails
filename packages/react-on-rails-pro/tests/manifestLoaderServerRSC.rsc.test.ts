/**
 * @jest-environment node
 */

import * as fs from 'fs/promises';
import * as os from 'os';
import * as path from 'path';
import { setManifestFileNames } from '../src/cache/manifestLoader.ts';
import { getServerRenderer } from '../src/cache/manifestLoaderServer.ts';

const writeManifest = async (filePath: string, moduleName = 'initial') => {
  await fs.writeFile(
    filePath,
    JSON.stringify({
      moduleLoading: { prefix: '/packs/' },
      filePathToModuleMetadata: {
        [`file:///app/${moduleName}.jsx`]: {
          id: moduleName,
          chunks: [],
          css: [],
          name: '*',
        },
      },
    }),
  );
};

describe('manifestLoaderServer', () => {
  afterEach(async () => {
    await setManifestFileNames('', '');
  });

  it('invalidates the server renderer when the client manifest file changes', async () => {
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'ror-manifest-loader-server-'));
    const clientManifest = path.join(tempDir, 'react-client-manifest.json');
    const serverClientManifest = path.join(tempDir, 'react-server-client-manifest.json');

    await writeManifest(clientManifest);
    await writeManifest(serverClientManifest);

    await setManifestFileNames(clientManifest, serverClientManifest);
    const firstRenderer = await getServerRenderer();

    await writeManifest(clientManifest, 'changed-client-manifest');
    await setManifestFileNames(clientManifest, serverClientManifest);
    const secondRenderer = await getServerRenderer();

    expect(secondRenderer).not.toBe(firstRenderer);
  });
});
