/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

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
