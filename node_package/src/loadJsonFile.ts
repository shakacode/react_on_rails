import * as path from 'path';
import * as fs from 'fs/promises';

const loadedJsonFiles = new Map<string, Record<string, unknown>>();

export default async function loadJsonFile(fileName: string) {
  // Asset JSON files are uploaded to node renderer.
  // Renderer copies assets to the same place as the server-bundle.js and rsc-bundle.js.
  // Thus, the __dirname of this code is where we can find the manifest file.
  const filePath = path.resolve(__dirname, fileName);
  if (!loadedJsonFiles.has(filePath)) {
    try {
      const file = JSON.parse(await fs.readFile(filePath, 'utf8'));
      loadedJsonFiles.set(filePath, file);
    } catch (error) {
      console.error(`Failed to load JSON file: ${filePath}`, error);
      throw error;
    }
  }

  return loadedJsonFiles.get(filePath)!;
}
