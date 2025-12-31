#!/usr/bin/env node
/**
 * Test atomicity using child processes for TRUE parallelism.
 *
 * Usage:
 *   node scripts/test-atomicity-parallel.mjs
 */

import { fork, spawn } from 'node:child_process';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TEST_FILE_SIZE_MB = 200;
const TEST_DIR = path.join(os.tmpdir(), `atomicity-parallel-${Date.now()}`);

async function generateTestFile(filePath, sizeMB) {
  console.log(`Generating ${sizeMB}MB test file...`);
  const start = Date.now();

  const fd = fs.openSync(filePath, 'w');
  const chunk = Buffer.alloc(1024 * 1024, 'x'); // 1MB of 'x'

  for (let i = 0; i < sizeMB; i++) {
    fs.writeSync(fd, chunk);
  }
  fs.writeSync(fd, '\n// COMPLETE_MARKER_12345_END //\n');
  fs.closeSync(fd);

  console.log(`Generated in ${Date.now() - start}ms`);
}

// Reader script that runs in a child process
const READER_SCRIPT = `
const fs = require('fs');
const destPath = process.argv[2];
const expectedSize = parseInt(process.argv[3], 10);

let readAttempts = 0;
let partialReads = 0;
let completeReads = 0;
let notFound = 0;
let errors = 0;
let sizes = new Set();

const startTime = Date.now();

// Run for max 30 seconds or until parent signals stop
process.on('message', (msg) => {
  if (msg === 'stop') {
    report();
    process.exit(0);
  }
});

function report() {
  process.send({
    readAttempts,
    partialReads,
    completeReads,
    notFound,
    errors,
    uniqueSizes: sizes.size,
    duration: Date.now() - startTime
  });
}

function poll() {
  readAttempts++;

  try {
    const stats = fs.statSync(destPath);
    sizes.add(stats.size);

    // Read last 50 bytes to check for completion marker
    if (stats.size >= 50) {
      const fd = fs.openSync(destPath, 'r');
      const buf = Buffer.alloc(50);
      fs.readSync(fd, buf, 0, 50, stats.size - 50);
      fs.closeSync(fd);

      if (buf.toString().includes('COMPLETE_MARKER_12345_END')) {
        completeReads++;
      } else {
        partialReads++;
        // Log first few partial reads with their sizes
        if (partialReads <= 5) {
          console.error('  [Reader] Partial read #' + partialReads + ': size=' + (stats.size/1024/1024).toFixed(2) + 'MB');
        }
      }
    } else if (stats.size > 0) {
      partialReads++;
    }
  } catch (err) {
    if (err.code === 'ENOENT') {
      notFound++;
    } else {
      errors++;
    }
  }

  // Continue polling immediately
  setImmediate(poll);
}

poll();
`;

async function runTest(testName, operation) {
  console.log('\n' + '='.repeat(60));
  console.log(`TEST: ${testName}`);
  console.log('='.repeat(60));

  const destPath = path.join(TEST_DIR, `dest-${testName.replace(/\s+/g, '-').toLowerCase()}.dat`);

  // Clean up destination
  await fsp.unlink(destPath).catch(() => {});

  // Spawn reader process
  const reader = spawn('node', ['-e', READER_SCRIPT, destPath, String(TEST_FILE_SIZE_MB * 1024 * 1024)], {
    stdio: ['pipe', 'inherit', 'inherit', 'ipc']
  });

  // Wait a bit for reader to start
  await new Promise(r => setTimeout(r, 50));

  // Run the operation
  const opStart = Date.now();
  await operation(destPath);
  const opTime = Date.now() - opStart;

  // Give reader a moment to see the final state
  await new Promise(r => setTimeout(r, 100));

  // Get results from reader
  return new Promise((resolve) => {
    reader.on('message', (results) => {
      reader.kill();
      console.log(`\nResults:`);
      console.log(`  Operation time: ${opTime}ms`);
      console.log(`  Read attempts: ${results.readAttempts}`);
      console.log(`  Not found: ${results.notFound}`);
      console.log(`  Partial reads: ${results.partialReads}`);
      console.log(`  Complete reads: ${results.completeReads}`);
      console.log(`  Unique sizes observed: ${results.uniqueSizes}`);

      if (results.partialReads > 0) {
        console.log(`\n  ❌ NOT ATOMIC! Observed ${results.partialReads} partial reads.`);
      } else if (results.completeReads > 0) {
        console.log(`\n  ✅ ATOMIC! File was either not found or complete.`);
      } else {
        console.log(`\n  ⚠️  Reader never saw complete file`);
      }

      resolve({ ...results, opTime, isAtomic: results.partialReads === 0 });
    });

    reader.send('stop');

    // Timeout fallback
    setTimeout(() => {
      reader.kill();
      resolve({ error: 'timeout', isAtomic: false });
    }, 5000);
  });
}

async function main() {
  console.log('='.repeat(60));
  console.log('ATOMICITY TEST WITH TRUE PARALLELISM');
  console.log('='.repeat(60));
  console.log(`Test directory: ${TEST_DIR}`);
  console.log(`Test file size: ${TEST_FILE_SIZE_MB} MB\n`);

  await fsp.mkdir(TEST_DIR, { recursive: true });

  const srcPath = path.join(TEST_DIR, 'source.dat');
  await generateTestFile(srcPath, TEST_FILE_SIZE_MB);

  const results = {};

  // Test 1: fs.copyFile()
  results.copyFile = await runTest('fs.copyFile()', async (dest) => {
    await fsp.copyFile(srcPath, dest);
  });

  // Test 2: fs.rename() (need to copy source first)
  const srcForRename = path.join(TEST_DIR, 'source-for-rename.dat');
  await fsp.copyFile(srcPath, srcForRename);

  results.rename = await runTest('fs.rename()', async (dest) => {
    await fsp.rename(srcForRename, dest);
  });

  // Test 3: Atomic pattern (copy to temp, then rename)
  results.atomicPattern = await runTest('Atomic Pattern (temp + rename)', async (dest) => {
    const tempPath = dest + '.tmp';
    await fsp.copyFile(srcPath, tempPath);
    await fsp.rename(tempPath, dest);
  });

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log(`
┌─────────────────────────────────┬──────────┬─────────────┐
│ Operation                       │ Atomic?  │ Partial Rds │
├─────────────────────────────────┼──────────┼─────────────┤
│ fs.copyFile() ${TEST_FILE_SIZE_MB}MB             │ ${results.copyFile?.isAtomic ? '✅ Yes*  ' : '❌ NO    '} │ ${String(results.copyFile?.partialReads ?? '?').padStart(11)} │
│ fs.rename() ${TEST_FILE_SIZE_MB}MB               │ ${results.rename?.isAtomic ? '✅ YES   ' : '❌ No    '} │ ${String(results.rename?.partialReads ?? '?').padStart(11)} │
│ Atomic pattern (temp + rename)  │ ${results.atomicPattern?.isAtomic ? '✅ YES   ' : '❌ No    '} │ ${String(results.atomicPattern?.partialReads ?? '?').padStart(11)} │
└─────────────────────────────────┴──────────┴─────────────┘
`);

  if (!results.copyFile?.isAtomic) {
    console.log(`🔴 CONFIRMED: fs.copyFile() is NOT atomic!`);
    console.log(`   File is visible at destination before fully written.`);
    console.log(`   This affects copyUploadedAssets() in React on Rails Pro.\n`);
  }

  if (results.rename?.isAtomic) {
    console.log(`🟢 CONFIRMED: fs.rename() IS atomic (same filesystem).\n`);
  }

  if (results.atomicPattern?.isAtomic) {
    console.log(`🟢 SOLUTION: Atomic write pattern works!`);
    console.log(`   Write to temp file, then atomic rename.\n`);
  }

  console.log(`Cleanup: rm -rf ${TEST_DIR}`);
}

main().catch(console.error);
