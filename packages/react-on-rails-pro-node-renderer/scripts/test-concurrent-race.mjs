#!/usr/bin/env node
/**
 * Test for TRANSIENT errors caused by concurrent request race condition
 *
 * Hypothesis: If bundle copy is non-atomic (cross-device), a concurrent
 * request could read a partially-written file, causing a transient error.
 *
 * This simulates:
 * 1. Request A starts copying bundle (slow)
 * 2. Request B sees file exists, skips upload, reads partial file
 * 3. Request B gets SyntaxError
 * 4. Request A completes
 * 5. Request C reads complete file, works
 */

import path from 'node:path';
import os from 'node:os';
import fsp from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { Readable } from 'node:stream';

const TEST_DIR = path.join(os.tmpdir(), `race-test-${Date.now()}`);
const BUNDLE_DIR = path.join(TEST_DIR, 'bundles', '12345');
const BUNDLE_PATH = path.join(BUNDLE_DIR, '12345.js');

console.log('='.repeat(70));
console.log('RACE CONDITION TEST: Concurrent Request During Non-Atomic Copy');
console.log('='.repeat(70));
console.log(`Test directory: ${TEST_DIR}\n`);

// Generate a valid JS bundle
function generateBundle(sizeMB) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = '// BUNDLE START\nvar ReactOnRails = { dummy: function() { return { html: "test" }; } };\n';
  const line = 'console.log("' + 'x'.repeat(100) + '");\n';
  while (content.length < targetSize - 200) {
    content += line;
  }
  content += 'ReactOnRails.COMPLETE_MARKER = true;\n// BUNDLE END\n';
  return Buffer.from(content, 'utf8');
}

// Simulate slow copy (like cross-device copy under load)
async function slowCopyFile(content, destPath, delayPerChunkMs = 50) {
  const chunkSize = 64 * 1024; // 64KB chunks
  let position = 0;

  const readStream = new Readable({
    read() {
      if (position >= content.length) {
        this.push(null);
        return;
      }

      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;

      // Simulate slow I/O
      setTimeout(() => {
        this.push(chunk);
      }, delayPerChunkMs);
    }
  });

  const writeStream = createWriteStream(destPath);
  return pipeline(readStream, writeStream);
}

// Check if bundle is valid JavaScript
async function validateBundle(filePath) {
  try {
    const content = await fsp.readFile(filePath, 'utf8');

    // Try to parse as JavaScript
    new Function(content);

    return {
      valid: true,
      size: content.length,
      hasMarker: content.includes('COMPLETE_MARKER')
    };
  } catch (error) {
    const content = await fsp.readFile(filePath, 'utf8').catch(() => '');
    return {
      valid: false,
      error: error.message,
      size: content.length,
      hasMarker: content.includes('COMPLETE_MARKER')
    };
  }
}

async function main() {
  await fsp.mkdir(BUNDLE_DIR, { recursive: true });

  const bundleContent = generateBundle(2); // 2MB bundle
  console.log(`Bundle size: ${(bundleContent.length / 1024 / 1024).toFixed(2)}MB\n`);

  console.log('─'.repeat(70));
  console.log('Simulating race condition:');
  console.log('─'.repeat(70));

  const results = [];
  let copyComplete = false;

  // Start slow copy (Request A)
  console.log(`[${Date.now()}] Request A: Starting slow copy...`);
  const copyPromise = slowCopyFile(bundleContent, BUNDLE_PATH, 20).then(() => {
    copyComplete = true;
    console.log(`[${Date.now()}] Request A: Copy COMPLETE`);
  });

  // Wait a bit for copy to start and create the file
  await new Promise(r => setTimeout(r, 100));

  // Concurrent requests trying to read the bundle
  const readAttempts = [];

  for (let i = 0; i < 10; i++) {
    await new Promise(r => setTimeout(r, 100));

    const attemptNum = i + 1;
    const timestamp = Date.now();

    // Check if file exists (like the renderer does)
    const exists = await fsp.access(BUNDLE_PATH).then(() => true).catch(() => false);

    if (exists) {
      const result = await validateBundle(BUNDLE_PATH);
      const status = result.valid ? '✅ VALID' : '❌ INVALID';
      console.log(`[${timestamp}] Request B${attemptNum}: File exists, ${status} (${(result.size/1024).toFixed(0)}KB, complete=${result.hasMarker})`);

      if (!result.valid) {
        console.log(`           Error: ${result.error.substring(0, 60)}...`);
      }

      readAttempts.push({
        attempt: attemptNum,
        copyComplete,
        ...result
      });
    } else {
      console.log(`[${timestamp}] Request B${attemptNum}: File does not exist yet`);
    }
  }

  // Wait for copy to finish
  await copyPromise;

  // Final read after copy complete
  await new Promise(r => setTimeout(r, 100));
  const finalResult = await validateBundle(BUNDLE_PATH);
  console.log(`\n[${Date.now()}] Final check: ${finalResult.valid ? '✅ VALID' : '❌ INVALID'}`);

  // Summary
  console.log('\n' + '─'.repeat(70));
  console.log('SUMMARY');
  console.log('─'.repeat(70));

  const invalidDuringCopy = readAttempts.filter(r => !r.valid && !r.copyComplete);
  const validDuringCopy = readAttempts.filter(r => r.valid && !r.copyComplete);
  const invalidAfterCopy = readAttempts.filter(r => !r.valid && r.copyComplete);
  const validAfterCopy = readAttempts.filter(r => r.valid && r.copyComplete);

  console.log(`\nReads during copy:  ${invalidDuringCopy.length} invalid, ${validDuringCopy.length} valid`);
  console.log(`Reads after copy:   ${invalidAfterCopy.length} invalid, ${validAfterCopy.length} valid`);

  if (invalidDuringCopy.length > 0) {
    console.log(`
🔴 RACE CONDITION CONFIRMED!

During non-atomic copy:
- File EXISTS but is INCOMPLETE
- Concurrent requests read partial file
- Get "Invalid or unexpected token" or similar errors
- After copy completes, subsequent requests succeed

This explains TRANSIENT errors that appear on "first few requests"
and then disappear once the bundle is fully written.
`);
  } else {
    console.log(`
✅ No race condition detected in this test run.
(May need to adjust timing or run multiple times)
`);
  }

  console.log(`Test directory: ${TEST_DIR}`);
}

main().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
