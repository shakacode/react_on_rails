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

import * as fs from 'fs';
import * as fsPromises from 'fs/promises';
import * as path from 'path';

type LoadedJsonFile = Record<string, unknown>;
const loadedJsonFiles = new Map<string, LoadedJsonFile>();

const resolveJsonFilePath = (fileName: string): string => path.resolve(__dirname, fileName);

export function getJsonFileSignature(fileName: string): string {
  const filePath = resolveJsonFilePath(fileName);
  try {
    const stats = fs.statSync(filePath);
    return `${filePath}\0${stats.size}\0${stats.mtimeMs}`;
  } catch {
    return `${filePath}\0missing`;
  }
}

export function clearLoadedJsonFile(fileName: string): void {
  loadedJsonFiles.delete(resolveJsonFilePath(fileName));
}

export default async function loadJsonFile<T extends LoadedJsonFile = LoadedJsonFile>(
  fileName: string,
): Promise<T> {
  // Asset JSON files are uploaded to node renderer.
  // Renderer copies assets to the same place as the server-bundle.js and rsc-bundle.js.
  // Thus, the __dirname of this code is where we can find the manifest file.
  const filePath = resolveJsonFilePath(fileName);
  const loadedJsonFile = loadedJsonFiles.get(filePath);
  if (loadedJsonFile) {
    return loadedJsonFile as T;
  }

  try {
    const file = JSON.parse(await fsPromises.readFile(filePath, 'utf8')) as T;
    loadedJsonFiles.set(filePath, file);
    return file;
  } catch (error) {
    console.error(`Failed to load JSON file: ${filePath}`, error);
    throw error;
  }
}
