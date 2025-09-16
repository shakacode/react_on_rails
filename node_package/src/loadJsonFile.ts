/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

import * as path from 'path';
import * as fs from 'fs/promises';

type LoadedJsonFile = Record<string, unknown>;
const loadedJsonFiles = new Map<string, LoadedJsonFile>();

export default async function loadJsonFile<T extends LoadedJsonFile = LoadedJsonFile>(
  fileName: string,
): Promise<T> {
  // Asset JSON files are uploaded to node renderer.
  // Renderer copies assets to the same place as the server-bundle.js and rsc-bundle.js.
  // Thus, the __dirname of this code is where we can find the manifest file.
  const filePath = path.resolve(__dirname, fileName);
  const loadedJsonFile = loadedJsonFiles.get(filePath);
  if (loadedJsonFile) {
    return loadedJsonFile as T;
  }

  try {
    const file = JSON.parse(await fs.readFile(filePath, 'utf8')) as T;
    loadedJsonFiles.set(filePath, file);
    return file;
  } catch (error) {
    console.error(`Failed to load JSON file: ${filePath}`, error);
    throw error;
  }
}
