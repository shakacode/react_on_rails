#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { containsLocalPaths } from './local-paths.mjs';

const target = process.argv[2];
if (!target || !fs.existsSync(target)) {
  console.error(`local-path scan failed: target does not exist: ${target ?? 'MISSING'}`);
  process.exit(2);
}

const containsLocalPathFile = (entry) => {
  const stat = fs.lstatSync(entry);
  if (stat.isSymbolicLink()) return false;
  if (stat.isDirectory()) {
    const directory = fs.opendirSync(entry);
    try {
      while (true) {
        const child = directory.readSync();
        if (child === null) break;
        if (containsLocalPathFile(path.join(entry, child.name))) return true;
      }
    } finally {
      directory.closeSync();
    }
  } else if (stat.isFile() && containsLocalPaths(fs.readFileSync(entry, 'utf8'))) {
    console.log(entry);
    return true;
  }
  return false;
};

try {
  process.exit(containsLocalPathFile(target) ? 0 : 1);
} catch (error) {
  console.error(`local-path scan failed: ${error.message}`);
  process.exit(2);
}
