#!/usr/bin/env node
/**
 * Test: Can concurrent writes to the SAME bundle cause truncation?
 * 
 * Scenario (realistic production):
 * - Multiple workers receive request with same bundleTimestamp
 * - All write the SAME content to /uploads/{hash}.js
 * - createWriteStream uses O_TRUNC which truncates on open
 * - If worker A is 60% done and worker B opens the file,
 *   the file gets truncated to 0, losing A's progress
 */

import fsp from 'node:fs/promises';
import { createWriteStream, statSync } from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const TEST_DIR = path.join(os.tmpdir(), `upload-trunc-${Date.now()}`);
const UPLOAD_FILE = path.join(TEST_DIR, 'bundle.js');
const BUNDLE_SIZE_MB = 2;

console.log('='.repeat(70));
console.log('UPLOAD TRUNCATION TEST - Same Bundle, Multiple Writers');
console.log('='.repeat(70));
console.log(`Test file: ${UPLOAD_FILE}\n`);

function generateBundle(sizeMB) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = '// BUNDLE START\n';
  content += 'var ReactOnRails = { test: true };\n';
  const line = 'console.log("' + 'x'.repeat(100) + '");\n';
  while (content.length < targetSize - 100) {
    content += line;
  }
  content += '// BUNDLE END - COMPLETE_MARKER\n';
  return Buffer.from(content, 'utf8');
}

async function writeWithRandomDelay(id, content, delayRange = 10) {
  return new Promise((resolve, reject) => {
    const stream = createWriteStream(UPLOAD_FILE);
    let position = 0;
    const chunkSize = 64 * 1024;
    let chunksWritten = 0;

    const writeNext = () => {
      if (position >= content.length) {
        stream.end();
        return;
      }

      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;
      chunksWritten++;

      // Random delay to increase chance of interleaving
      setTimeout(() => {
        stream.write(chunk, writeNext);
      }, Math.random() * delayRange);
    };

    stream.on('finish', () => {
      resolve({ id, chunksWritten, bytesWritten: position });
    });
    stream.on('error', reject);

    writeNext();
  });
}

async function main() {
  await fsp.mkdir(TEST_DIR, { recursive: true });

  // Generate ONE bundle (same content for all workers)
  const bundle = generateBundle(BUNDLE_SIZE_MB);
  const expectedSize = bundle.length;
  console.log(`Bundle size: ${(expectedSize / 1024 / 1024).toFixed(2)}MB`);
  console.log(`Expected final size: ${expectedSize} bytes`);
  console.log('');

  // Run test 5 times
  for (let run = 1; run <= 5; run++) {
    // Clean the file before each run
    try { await fsp.unlink(UPLOAD_FILE); } catch {}
    
    console.log(`\n--- Run ${run} ---`);
    console.log('Starting 3 concurrent writers with SAME content...');

    const results = await Promise.all([
      writeWithRandomDelay('A', bundle, 5),
      writeWithRandomDelay('B', bundle, 5),
      writeWithRandomDelay('C', bundle, 5),
    ]);

    // Check the final file
    const stats = await fsp.stat(UPLOAD_FILE);
    const content = await fsp.readFile(UPLOAD_FILE, 'utf8');
    const isComplete = content.includes('COMPLETE_MARKER');
    
    console.log(`Final file size: ${stats.size} bytes (${((stats.size / expectedSize) * 100).toFixed(1)}%)`);
    
    if (stats.size < expectedSize) {
      console.log(`🔴 TRUNCATED! Missing ${expectedSize - stats.size} bytes`);
    } else if (!isComplete) {
      console.log(`🔴 CORRUPTED! File is full size but missing end marker`);
    } else {
      console.log(`✅ Complete`);
    }

    // Check if file is valid JS
    try {
      new Function(content);
    } catch (e) {
      console.log(`🔴 INVALID JS: ${e.message.substring(0, 60)}`);
    }
  }

  console.log(`\nTest directory: ${TEST_DIR}`);
}

main().catch(console.error);
