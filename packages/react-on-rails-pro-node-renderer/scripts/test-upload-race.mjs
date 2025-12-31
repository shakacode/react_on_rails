#!/usr/bin/env node
/**
 * Test: Can multiple workers corrupt the upload file?
 *
 * Simulates multiple processes writing to the same file simultaneously.
 */

import fsp from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';

const TEST_DIR = path.join(os.tmpdir(), `upload-race-${Date.now()}`);
const UPLOAD_FILE = path.join(TEST_DIR, 'bundle.js');

console.log('='.repeat(70));
console.log('UPLOAD FILE RACE CONDITION TEST');
console.log('='.repeat(70));
console.log(`Test file: ${UPLOAD_FILE}\n`);

function generateBundle(id, sizeMB = 1) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = `// BUNDLE FROM WRITER ${id}\n`;
  content += `var WRITER_ID = "${id}";\n`;

  const line = `console.log("Writer ${id}: ${'x'.repeat(80)}");\n`;
  while (content.length < targetSize - 100) {
    content += line;
  }

  content += `// END BUNDLE ${id}\n`;
  return Buffer.from(content, 'utf8');
}

async function writeBundle(id, content) {
  return new Promise((resolve, reject) => {
    const stream = createWriteStream(UPLOAD_FILE);
    let position = 0;
    const chunkSize = 64 * 1024;

    const writeNext = () => {
      if (position >= content.length) {
        stream.end();
        return;
      }

      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;

      // Add random delay to increase chance of interleaving
      setTimeout(() => {
        stream.write(chunk, writeNext);
      }, Math.random() * 10);
    };

    stream.on('finish', () => {
      console.log(`Writer ${id}: finished writing`);
      resolve();
    });
    stream.on('error', reject);

    console.log(`Writer ${id}: starting to write ${(content.length / 1024).toFixed(0)}KB`);
    writeNext();
  });
}

async function main() {
  await fsp.mkdir(TEST_DIR, { recursive: true });

  // Generate different bundles for each "worker"
  const bundle1 = generateBundle('A', 1);
  const bundle2 = generateBundle('B', 1);
  const bundle3 = generateBundle('C', 1);

  console.log('Starting 3 concurrent writers to the SAME file...\n');

  // Start all writers simultaneously
  await Promise.all([
    writeBundle('A', bundle1),
    writeBundle('B', bundle2),
    writeBundle('C', bundle3),
  ]);

  console.log('\n' + '─'.repeat(70));
  console.log('RESULTS');
  console.log('─'.repeat(70));

  // Read the result
  const result = await fsp.readFile(UPLOAD_FILE, 'utf8');

  // Check what we got
  const hasA = result.includes('WRITER_ID = "A"');
  const hasB = result.includes('WRITER_ID = "B"');
  const hasC = result.includes('WRITER_ID = "C"');
  const hasEndA = result.includes('END BUNDLE A');
  const hasEndB = result.includes('END BUNDLE B');
  const hasEndC = result.includes('END BUNDLE C');

  console.log(`\nFile contains Writer A header: ${hasA}`);
  console.log(`File contains Writer B header: ${hasB}`);
  console.log(`File contains Writer C header: ${hasC}`);
  console.log(`File contains Writer A footer: ${hasEndA}`);
  console.log(`File contains Writer B footer: ${hasEndB}`);
  console.log(`File contains Writer C footer: ${hasEndC}`);

  // Check if file is valid JS
  let isValidJS = false;
  try {
    new Function(result);
    isValidJS = true;
  } catch (e) {
    console.log(`\nJS Parse Error: ${e.message.substring(0, 100)}`);
  }

  console.log(`\nFile is valid JavaScript: ${isValidJS}`);
  console.log(`File size: ${(result.length / 1024).toFixed(0)}KB`);

  // Count how many different writers' content is in the file
  const writerMatches = [hasA, hasB, hasC].filter(Boolean).length;

  if (writerMatches > 1 || !isValidJS) {
    console.log(`
🔴 RACE CONDITION DEMONSTRATED!

Multiple writers corrupted the file:
- File contains content from ${writerMatches} different writers
- File is ${isValidJS ? 'valid' : 'INVALID'} JavaScript

This proves that concurrent writes to /uploads/{hash}.js
can corrupt the bundle file!
`);
  } else {
    console.log(`
✅ One writer won the race cleanly.

Last writer to finish: ${hasEndA ? 'A' : hasEndB ? 'B' : hasEndC ? 'C' : 'unknown'}
File appears consistent.

(Run multiple times - race conditions are probabilistic)
`);
  }

  console.log(`Test directory: ${TEST_DIR}`);
}

main().catch(console.error);
