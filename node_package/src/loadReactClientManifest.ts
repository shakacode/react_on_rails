import * as path from 'path';
import * as fs from 'fs/promises';

type ClientManifest = Record<string, unknown>;
const loadedReactClientManifests = new Map<string, ClientManifest>();

export default async function loadReactClientManifest(reactClientManifestFileName: string) {
  // React client manifest is uploaded to node renderer as an asset.
  // Renderer copies assets to the same place as the server-bundle.js and rsc-bundle.js.
  // Thus, the __dirname of this code is where we can find the manifest file.
  const manifestPath = path.resolve(__dirname, reactClientManifestFileName);
  const loadedReactClientManifest = loadedReactClientManifests.get(manifestPath);
  if (loadedReactClientManifest) {
    return loadedReactClientManifest;
  }

  try {
    const manifest = JSON.parse(await fs.readFile(manifestPath, 'utf8')) as ClientManifest;
    loadedReactClientManifests.set(manifestPath, manifest);
    return manifest;
  } catch (error) {
    throw new Error(`Failed to load React client manifest from ${manifestPath}: ${error}`);
  }
}
