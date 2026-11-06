#!/usr/bin/env node

// Fails when a packed npm tarball contains a `//# sourceMappingURL=` comment
// that points at a file the tarball does not ship. Dangling pointers break
// `node --enable-source-maps`, debuggers, error trackers, and bundlers that
// follow them (#5079, #5307).
//
// Usage: node script/check-packed-source-maps.mjs <package.tgz>...

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const CHECKED_FILE = /\.(?:[cm]?js|d\.[cm]?ts)$/;
const POINTER = /^\s*\/\/[#@] sourceMappingURL=(\S+)\s*$/gm;

function listFiles(dir) {
  return fs
    .readdirSync(dir, { withFileTypes: true, recursive: true })
    .filter((entry) => entry.isFile())
    .map((entry) => path.join(entry.parentPath, entry.name));
}

function danglingPointersIn(file, root) {
  return [...fs.readFileSync(file, 'utf8').matchAll(POINTER)]
    .map(([, url]) => url)
    .filter((url) => !url.startsWith('data:'))
    .filter((url) => !fs.existsSync(path.resolve(path.dirname(file), decodeURIComponent(url))))
    .map((url) => `${path.relative(root, file)} -> ${url}`);
}

function danglingPointers(tarball) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'packed-source-maps-'));
  try {
    execFileSync('tar', ['-xzf', tarball, '-C', dir]);
    return listFiles(dir)
      .filter((file) => CHECKED_FILE.test(file))
      .flatMap((file) => danglingPointersIn(file, dir));
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

const tarballs = process.argv.slice(2);
if (tarballs.length === 0) {
  console.error('Usage: node script/check-packed-source-maps.mjs <package.tgz>...');
  process.exit(1);
}

let failed = false;
for (const tarball of tarballs) {
  const dangling = danglingPointers(tarball);
  if (dangling.length === 0) {
    console.log(`OK ${tarball}: no dangling sourceMappingURL pointers`);
  } else {
    failed = true;
    console.error(
      `FAIL ${tarball}: ${dangling.length} sourceMappingURL pointer(s) to files not in the package`,
    );
    for (const line of dangling.slice(0, 10)) console.error(`  ${line}`);
    if (dangling.length > 10) console.error(`  ... and ${dangling.length - 10} more`);
  }
}

process.exit(failed ? 1 : 0);
