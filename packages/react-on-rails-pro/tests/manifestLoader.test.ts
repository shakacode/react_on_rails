/**
 * @jest-environment node
 */

import * as fs from 'fs/promises';
import * as os from 'os';
import * as path from 'path';
import { getRscCssHrefs, setManifestFileNames } from '../src/cache/manifestLoader.ts';

const writeManifest = async (filePath: string, cssFile: string) => {
  await fs.writeFile(
    filePath,
    JSON.stringify({
      moduleLoading: { prefix: '/packs/' },
      filePathToModuleMetadata: {
        'file:///app/UseClient.jsx': {
          id: '1',
          chunks: [],
          css: [cssFile],
          name: '*',
        },
      },
    }),
  );
};

describe('manifestLoader', () => {
  it('invalidates manifest-derived CSS when the client manifest file changes', async () => {
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'ror-manifest-loader-'));
    const clientManifest = path.join(tempDir, 'react-client-manifest.json');
    const serverClientManifest = path.join(tempDir, 'react-server-client-manifest.json');

    await writeManifest(clientManifest, 'css/first.css');
    await writeManifest(serverClientManifest, 'css/first.css');
    setManifestFileNames(clientManifest, serverClientManifest);
    await expect(getRscCssHrefs()).resolves.toEqual(['/packs/css/first.css']);

    await writeManifest(clientManifest, 'css/second.css');
    setManifestFileNames(clientManifest, serverClientManifest);

    await expect(getRscCssHrefs()).resolves.toEqual(['/packs/css/second.css']);
  });
});
