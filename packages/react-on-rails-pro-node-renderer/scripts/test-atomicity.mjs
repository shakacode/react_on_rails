#!/usr/bin/env node
/**
 * Test script to verify if copy and move operations are atomic.
 *
 * This script demonstrates that:
 * 1. fs.copyFile() is NOT atomic - file is visible before fully written
 * 2. fs.rename() IS atomic (same filesystem) - file appears only when complete
 * 3. fs-extra move() falls back to copy on cross-device, making it non-atomic
 *
 * Usage:
 *   node scripts/test-atomicity.mjs
 */

import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Test configuration
const TEST_FILE_SIZE_MB = 50; // Large enough to observe the race
const TEST_DIR = path.join(os.tmpdir(), `atomicity-test-${Date.now()}`);
const POLL_INTERVAL_MS = 0; // Poll as fast as possible

/**
 * Generate a valid JavaScript file of specified size
 */
function generateTestBundle(sizeMB) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = '// START OF BUNDLE\n(function() {\n';

  const line = '  console.log("' + 'x'.repeat(100) + '");\n';

  while (content.length < targetSize - 200) {
    content += line;
  }

  content += '  return "COMPLETE_MARKER_12345";\n';
  content += '})();\n// END OF BUNDLE\n';

  return content;
}

/**
 * Reader that continuously polls and reads the destination file
 */
async function pollAndRead(destPath, results, stopSignal) {
  let readAttempts = 0;
  let partialReads = 0;
  let completeReads = 0;
  let fileNotFoundCount = 0;
  let firstPartialSize = null;
  let readSizes = [];

  while (!stopSignal.stopped) {
    readAttempts++;

    try {
      // Check if file exists
      const stats = await fsp.stat(destPath).catch(() => null);

      if (stats) {
        const content = await fsp.readFile(destPath, 'utf8');
        readSizes.push(content.length);

        // Check if we got complete content
        if (content.includes('COMPLETE_MARKER_12345') && content.includes('END OF BUNDLE')) {
          completeReads++;
        } else {
          partialReads++;
          if (firstPartialSize === null) {
            firstPartialSize = content.length;
          }
        }
      } else {
        fileNotFoundCount++;
      }
    } catch (err) {
      // Ignore read errors during concurrent access
      if (err.code !== 'ENOENT' && err.code !== 'EBUSY') {
        // Could be reading while write is in progress
      }
    }

    // Small delay to not overwhelm the system
    await new Promise(resolve => setImmediate(resolve));
  }

  results.readAttempts = readAttempts;
  results.partialReads = partialReads;
  results.completeReads = completeReads;
  results.fileNotFoundCount = fileNotFoundCount;
  results.firstPartialSize = firstPartialSize;
  results.uniqueReadSizes = [...new Set(readSizes)].sort((a, b) => a - b);
}

/**
 * Test 1: fs.copyFile() atomicity
 */
async function testCopyFileAtomicity() {
  console.log('\n' + '='.repeat(60));
  console.log('TEST 1: fs.copyFile() Atomicity');
  console.log('='.repeat(60));

  const srcPath = path.join(TEST_DIR, 'source-copy.js');
  const destPath = path.join(TEST_DIR, 'dest-copy.js');

  // Create source file
  const content = generateTestBundle(TEST_FILE_SIZE_MB);
  await fsp.writeFile(srcPath, content);
  console.log(`Source file: ${srcPath} (${(content.length / 1024 / 1024).toFixed(2)} MB)`);

  // Remove destination if exists
  await fsp.unlink(destPath).catch(() => {});

  const results = {};
  const stopSignal = { stopped: false };

  // Start reader in parallel
  const readerPromise = pollAndRead(destPath, results, stopSignal);

  // Perform copy
  const copyStart = Date.now();
  await fsp.copyFile(srcPath, destPath);
  const copyTime = Date.now() - copyStart;

  // Stop reader
  stopSignal.stopped = true;
  await readerPromise;

  // Verify final file
  const finalContent = await fsp.readFile(destPath, 'utf8');
  const isComplete = finalContent === content;

  console.log(`\nResults:`);
  console.log(`  Copy duration: ${copyTime}ms`);
  console.log(`  Read attempts: ${results.readAttempts}`);
  console.log(`  File not found: ${results.fileNotFoundCount}`);
  console.log(`  Partial reads: ${results.partialReads}`);
  console.log(`  Complete reads: ${results.completeReads}`);
  console.log(`  First partial size: ${results.firstPartialSize ? `${(results.firstPartialSize / 1024).toFixed(2)} KB` : 'N/A'}`);
  console.log(`  Unique sizes observed: ${results.uniqueReadSizes.length}`);
  console.log(`  Final file complete: ${isComplete ? '✅ Yes' : '❌ No'}`);

  if (results.partialReads > 0) {
    console.log(`\n  ❌ fs.copyFile() is NOT ATOMIC!`);
    console.log(`     Observed ${results.partialReads} partial reads during copy.`);
    console.log(`     File was visible at sizes: ${results.uniqueReadSizes.slice(0, 5).map(s => `${(s/1024).toFixed(0)}KB`).join(', ')}...`);
  } else if (results.fileNotFoundCount > 0 && results.completeReads > 0) {
    console.log(`\n  ✅ fs.copyFile() appeared atomic in this test`);
    console.log(`     (File was either not found or complete)`);
  } else {
    console.log(`\n  ⚠️  Inconclusive - try increasing file size`);
  }

  return { isAtomic: results.partialReads === 0, results };
}

/**
 * Test 2: fs.rename() atomicity (same filesystem)
 */
async function testRenameAtomicity() {
  console.log('\n' + '='.repeat(60));
  console.log('TEST 2: fs.rename() Atomicity (Same Filesystem)');
  console.log('='.repeat(60));

  const srcPath = path.join(TEST_DIR, 'source-rename.js');
  const destPath = path.join(TEST_DIR, 'dest-rename.js');

  // Create source file
  const content = generateTestBundle(TEST_FILE_SIZE_MB);
  await fsp.writeFile(srcPath, content);
  console.log(`Source file: ${srcPath} (${(content.length / 1024 / 1024).toFixed(2)} MB)`);

  // Remove destination if exists
  await fsp.unlink(destPath).catch(() => {});

  const results = {};
  const stopSignal = { stopped: false };

  // Start reader in parallel
  const readerPromise = pollAndRead(destPath, results, stopSignal);

  // Small delay to ensure reader is polling
  await new Promise(resolve => setTimeout(resolve, 10));

  // Perform rename
  const renameStart = Date.now();
  await fsp.rename(srcPath, destPath);
  const renameTime = Date.now() - renameStart;

  // Give reader a moment to see the file
  await new Promise(resolve => setTimeout(resolve, 50));

  // Stop reader
  stopSignal.stopped = true;
  await readerPromise;

  // Verify final file
  const finalContent = await fsp.readFile(destPath, 'utf8');
  const isComplete = finalContent === content;

  console.log(`\nResults:`);
  console.log(`  Rename duration: ${renameTime}ms`);
  console.log(`  Read attempts: ${results.readAttempts}`);
  console.log(`  File not found: ${results.fileNotFoundCount}`);
  console.log(`  Partial reads: ${results.partialReads}`);
  console.log(`  Complete reads: ${results.completeReads}`);
  console.log(`  Unique sizes observed: ${results.uniqueReadSizes.length}`);
  console.log(`  Final file complete: ${isComplete ? '✅ Yes' : '❌ No'}`);

  if (results.partialReads === 0) {
    console.log(`\n  ✅ fs.rename() IS ATOMIC!`);
    console.log(`     File was either not found (${results.fileNotFoundCount}x) or complete (${results.completeReads}x).`);
    console.log(`     No partial reads observed.`);
  } else {
    console.log(`\n  ❌ Unexpected: fs.rename() showed partial reads!`);
  }

  return { isAtomic: results.partialReads === 0, results };
}

/**
 * Test 3: fs-extra move() with simulated cross-device (copy + unlink)
 */
async function testMoveAcrossDevice() {
  console.log('\n' + '='.repeat(60));
  console.log('TEST 3: Simulated Cross-Device Move (copy + unlink)');
  console.log('='.repeat(60));

  const srcPath = path.join(TEST_DIR, 'source-move.js');
  const destPath = path.join(TEST_DIR, 'dest-move.js');

  // Create source file
  const content = generateTestBundle(TEST_FILE_SIZE_MB);
  await fsp.writeFile(srcPath, content);
  console.log(`Source file: ${srcPath} (${(content.length / 1024 / 1024).toFixed(2)} MB)`);

  // Remove destination if exists
  await fsp.unlink(destPath).catch(() => {});

  const results = {};
  const stopSignal = { stopped: false };

  // Start reader in parallel
  const readerPromise = pollAndRead(destPath, results, stopSignal);

  // Simulate cross-device move (what fs-extra does on EXDEV)
  const moveStart = Date.now();
  await fsp.copyFile(srcPath, destPath);
  await fsp.unlink(srcPath);
  const moveTime = Date.now() - moveStart;

  // Stop reader
  stopSignal.stopped = true;
  await readerPromise;

  // Verify final file
  const finalContent = await fsp.readFile(destPath, 'utf8');
  const isComplete = finalContent === content;

  console.log(`\nResults:`);
  console.log(`  Move duration: ${moveTime}ms`);
  console.log(`  Read attempts: ${results.readAttempts}`);
  console.log(`  File not found: ${results.fileNotFoundCount}`);
  console.log(`  Partial reads: ${results.partialReads}`);
  console.log(`  Complete reads: ${results.completeReads}`);
  console.log(`  Unique sizes observed: ${results.uniqueReadSizes.length}`);
  console.log(`  Final file complete: ${isComplete ? '✅ Yes' : '❌ No'}`);

  if (results.partialReads > 0) {
    console.log(`\n  ❌ Cross-device move is NOT ATOMIC!`);
    console.log(`     This is what fs-extra move() does when EXDEV occurs.`);
    console.log(`     Observed ${results.partialReads} partial reads.`);
  } else {
    console.log(`\n  ⚠️  No partial reads observed (try larger file or faster polling)`);
  }

  return { isAtomic: results.partialReads === 0, results };
}

/**
 * Test 4: Atomic write pattern (write to temp, then rename)
 */
async function testAtomicWritePattern() {
  console.log('\n' + '='.repeat(60));
  console.log('TEST 4: Atomic Write Pattern (temp file + rename)');
  console.log('='.repeat(60));

  const srcPath = path.join(TEST_DIR, 'source-atomic.js');
  const destPath = path.join(TEST_DIR, 'dest-atomic.js');
  const tempPath = path.join(TEST_DIR, 'dest-atomic.js.tmp');

  // Create source file
  const content = generateTestBundle(TEST_FILE_SIZE_MB);
  await fsp.writeFile(srcPath, content);
  console.log(`Source file: ${srcPath} (${(content.length / 1024 / 1024).toFixed(2)} MB)`);

  // Remove destination if exists
  await fsp.unlink(destPath).catch(() => {});
  await fsp.unlink(tempPath).catch(() => {});

  const results = {};
  const stopSignal = { stopped: false };

  // Start reader in parallel (watching destPath, NOT tempPath)
  const readerPromise = pollAndRead(destPath, results, stopSignal);

  // Atomic write pattern
  const writeStart = Date.now();
  await fsp.copyFile(srcPath, tempPath);  // Write to temp (destPath not visible yet)
  await fsp.rename(tempPath, destPath);    // Atomic rename
  const writeTime = Date.now() - writeStart;

  // Give reader a moment
  await new Promise(resolve => setTimeout(resolve, 50));

  // Stop reader
  stopSignal.stopped = true;
  await readerPromise;

  // Verify final file
  const finalContent = await fsp.readFile(destPath, 'utf8');
  const isComplete = finalContent === content;

  console.log(`\nResults:`);
  console.log(`  Total duration: ${writeTime}ms`);
  console.log(`  Read attempts: ${results.readAttempts}`);
  console.log(`  File not found: ${results.fileNotFoundCount}`);
  console.log(`  Partial reads: ${results.partialReads}`);
  console.log(`  Complete reads: ${results.completeReads}`);
  console.log(`  Unique sizes observed: ${results.uniqueReadSizes.length}`);
  console.log(`  Final file complete: ${isComplete ? '✅ Yes' : '❌ No'}`);

  if (results.partialReads === 0) {
    console.log(`\n  ✅ ATOMIC WRITE PATTERN WORKS!`);
    console.log(`     File was either not found (${results.fileNotFoundCount}x) or complete (${results.completeReads}x).`);
    console.log(`     This is the recommended fix for React on Rails Pro.`);
  } else {
    console.log(`\n  ❌ Unexpected partial reads!`);
  }

  return { isAtomic: results.partialReads === 0, results };
}

/**
 * Main execution
 */
async function main() {
  console.log('='.repeat(60));
  console.log('FILE OPERATION ATOMICITY TEST');
  console.log('='.repeat(60));
  console.log(`Test directory: ${TEST_DIR}`);
  console.log(`Test file size: ${TEST_FILE_SIZE_MB} MB`);

  // Create test directory
  await fsp.mkdir(TEST_DIR, { recursive: true });

  const results = {};

  try {
    // Run tests
    results.copyFile = await testCopyFileAtomicity();
    results.rename = await testRenameAtomicity();
    results.crossDeviceMove = await testMoveAcrossDevice();
    results.atomicPattern = await testAtomicWritePattern();

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('SUMMARY');
    console.log('='.repeat(60));
    console.log(`
┌─────────────────────────────────────┬──────────┐
│ Operation                           │ Atomic?  │
├─────────────────────────────────────┼──────────┤
│ fs.copyFile()                       │ ${results.copyFile.isAtomic ? '✅ Yes*  ' : '❌ NO    '} │
│ fs.rename() (same filesystem)       │ ${results.rename.isAtomic ? '✅ YES   ' : '❌ No    '} │
│ Cross-device move (copy + unlink)   │ ${results.crossDeviceMove.isAtomic ? '✅ Yes*  ' : '❌ NO    '} │
│ Atomic pattern (temp + rename)      │ ${results.atomicPattern.isAtomic ? '✅ YES   ' : '❌ No    '} │
└─────────────────────────────────────┴──────────┘

* If marked "Yes" but expected "NO", try increasing TEST_FILE_SIZE_MB
  or running on a slower disk.

KEY FINDINGS:
`);

    if (!results.copyFile.isAtomic) {
      console.log(`
🔴 fs.copyFile() is NOT atomic!
   - File appears at destination BEFORE fully written
   - Readers can observe partial/truncated content
   - This affects copyUploadedAssets() in React on Rails Pro
`);
    }

    if (results.rename.isAtomic) {
      console.log(`
🟢 fs.rename() IS atomic (same filesystem)!
   - File appears only after operation completes
   - This is why moveUploadedAsset() works on same filesystem
`);
    }

    if (!results.crossDeviceMove.isAtomic) {
      console.log(`
🔴 Cross-device move is NOT atomic!
   - When EXDEV occurs, fs-extra falls back to copy + unlink
   - This affects moveUploadedAsset() in Docker/K8s environments
`);
    }

    if (results.atomicPattern.isAtomic) {
      console.log(`
🟢 RECOMMENDED FIX: Use atomic write pattern
   1. Write to temporary file: dest.tmp
   2. Atomic rename: dest.tmp → dest
   3. File only appears when complete!
`);
    }

  } finally {
    // Cleanup
    console.log(`\nTest files available at: ${TEST_DIR}`);
    console.log(`To clean up: rm -rf ${TEST_DIR}`);
  }
}

main().catch(console.error);
