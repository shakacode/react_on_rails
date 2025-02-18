import * as path from 'path';
import * as fs from 'fs/promises';

const loadedReactClientManifests = new Map<string, Record<string, unknown>>();

export default async function loadReactClientManifest(reactClientManifestFileName: string) {
  // React client manifest is uploaded to node renderer as an asset.
  // Renderer copies assets to the same place as the server-bundle.js and rsc-bundle.js.
  // Thus, the __dirname of this code is where we can find the manifest file.
  const manifestPath = path.resolve(__dirname, reactClientManifestFileName);
  if (!loadedReactClientManifests.has(manifestPath)) {
    // TODO: convert to async
    try {
      const manifest = JSON.parse(await fs.readFile(manifestPath, 'utf8'));
      loadedReactClientManifests.set(manifestPath, manifest);
    } catch (error) {
      throw new Error(`Failed to load React client manifest from ${manifestPath}: ${error}`);
    }
  }

  return loadedReactClientManifests.get(manifestPath)!;
}
