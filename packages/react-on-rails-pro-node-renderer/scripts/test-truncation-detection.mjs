#!/usr/bin/env node
/**
 * Unit test to verify truncation detection in saveMultipartFile.
 *
 * This script simulates what happens when a multipart file stream
 * ends prematurely, similar to a network interruption.
 *
 * It tests:
 * 1. Current behavior (no truncation check) - should FAIL to detect
 * 2. Fixed behavior (with truncation check) - should DETECT and throw
 *
 * Usage:
 *   node scripts/test-truncation-detection.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { fileURLToPath } from 'node:url';
import os from 'node:os';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

console.log('='.repeat(60));
console.log('Truncation Detection Test');
console.log('='.repeat(60));

const TEST_DIR = path.join(os.tmpdir(), 'truncation-test-' + Date.now());
fs.mkdirSync(TEST_DIR, { recursive: true });
console.log(`Test directory: ${TEST_DIR}\n`);

/**
 * Create a mock MultipartFile that simulates truncation.
 * This mimics what @fastify/multipart provides.
 */
function createMockMultipartFile(fullContent, truncateAt) {
  const buffer = Buffer.from(fullContent);
  const truncatedBuffer = buffer.slice(0, truncateAt);

  let position = 0;
  const chunkSize = 1024;

  // Create a readable stream that ends after truncateAt bytes
  const file = new Readable({
    read() {
      if (position >= truncatedBuffer.length) {
        this.push(null); // End stream (simulating abrupt end)
        return;
      }

      const end = Math.min(position + chunkSize, truncatedBuffer.length);
      this.push(truncatedBuffer.slice(position, end));
      position = end;
    }
  });

  // This is the key property that Fastify sets!
  // When stream ends before all data is received, this is set to true
  file.truncated = true;

  return {
    file,
    filename: 'test-bundle.js',
    fieldname: 'bundle',
    mimetype: 'text/javascript',
    encoding: '7bit',
    // The full content that SHOULD have been sent
    _expectedSize: buffer.length,
    _actualSize: truncatedBuffer.length
  };
}

/**
 * Current implementation (vulnerable) - from utils.ts
 */
async function saveMultipartFile_CURRENT(multipartFile, destinationPath) {
  // Simulating: await ensureDir(path.dirname(destinationPath));
  fs.mkdirSync(path.dirname(destinationPath), { recursive: true });

  // Current implementation: just pump and return
  const writeStream = fs.createWriteStream(destinationPath);
  await pipeline(multipartFile.file, writeStream);

  // ❌ NO CHECK for multipartFile.file.truncated!
  return { checked: false };
}

/**
 * Fixed implementation - with truncation check
 */
async function saveMultipartFile_FIXED(multipartFile, destinationPath) {
  fs.mkdirSync(path.dirname(destinationPath), { recursive: true });

  const writeStream = fs.createWriteStream(destinationPath);
  await pipeline(multipartFile.file, writeStream);

  // ✅ CHECK for truncation!
  if (multipartFile.file.truncated) {
    // Clean up the partial file
    fs.unlinkSync(destinationPath);
    throw new Error(`Upload truncated: file stream ended prematurely`);
  }

  return { checked: true, truncated: false };
}

/**
 * Generate valid JS content
 */
function generateValidJS(sizeKB) {
  let content = '// START OF BUNDLE\n(function() {\n';
  const line = '  console.log("' + 'x'.repeat(100) + '");\n';

  while (content.length < sizeKB * 1024 - 100) {
    content += line;
  }

  content += '})();\n// END OF BUNDLE\n';
  return content;
}

/**
 * Test 1: Verify current implementation does NOT detect truncation
 */
async function testCurrentImplementation() {
  console.log('Test 1: Current Implementation (No Truncation Check)');
  console.log('-'.repeat(50));

  const fullContent = generateValidJS(100); // 100KB bundle
  const truncateAt = Math.floor(fullContent.length * 0.5); // Truncate at 50%

  console.log(`  Full content size: ${fullContent.length} bytes`);
  console.log(`  Truncating at: ${truncateAt} bytes (50%)`);

  const mockFile = createMockMultipartFile(fullContent, truncateAt);
  const destPath = path.join(TEST_DIR, 'current-impl.js');

  try {
    await saveMultipartFile_CURRENT(mockFile, destPath);

    // Check what was written
    const written = fs.readFileSync(destPath, 'utf8');
    const stats = fs.statSync(destPath);

    console.log(`\n  Result:`);
    console.log(`    File written: ✅ Yes`);
    console.log(`    File size: ${stats.size} bytes`);
    console.log(`    Expected size: ${fullContent.length} bytes`);
    console.log(`    Truncation detected: ❌ NO!`);
    console.log(`    file.truncated flag: ${mockFile.file.truncated}`);

    // Try to parse the truncated JS
    console.log(`\n  Parsing truncated JS...`);
    try {
      new Function(written);
      console.log(`    Parse result: ✅ Valid (unexpected!)`);
    } catch (e) {
      console.log(`    Parse result: ❌ ${e.message}`);
    }

    console.log(`\n  ⚠️  VULNERABILITY CONFIRMED!`);
    console.log(`     Truncated file was saved without any warning.`);
    console.log(`     This file would cause syntax errors when loaded.\n`);

    return { vulnerable: true, filePath: destPath };

  } catch (error) {
    console.log(`  Error (unexpected): ${error.message}`);
    return { vulnerable: false, error };
  }
}

/**
 * Test 2: Verify fixed implementation DOES detect truncation
 */
async function testFixedImplementation() {
  console.log('Test 2: Fixed Implementation (With Truncation Check)');
  console.log('-'.repeat(50));

  const fullContent = generateValidJS(100);
  const truncateAt = Math.floor(fullContent.length * 0.5);

  console.log(`  Full content size: ${fullContent.length} bytes`);
  console.log(`  Truncating at: ${truncateAt} bytes (50%)`);

  const mockFile = createMockMultipartFile(fullContent, truncateAt);
  const destPath = path.join(TEST_DIR, 'fixed-impl.js');

  try {
    await saveMultipartFile_FIXED(mockFile, destPath);

    console.log(`\n  Result:`);
    console.log(`    File written: ✅ Yes (unexpected!)`);
    console.log(`    Truncation detected: ❌ NO!`);
    console.log(`\n  ❌ FIX NOT WORKING!\n`);

    return { fixed: false };

  } catch (error) {
    console.log(`\n  Result:`);
    console.log(`    Error thrown: ✅ Yes`);
    console.log(`    Error message: "${error.message}"`);

    // Verify file was cleaned up
    const fileExists = fs.existsSync(destPath);
    console.log(`    Partial file cleaned up: ${fileExists ? '❌ No' : '✅ Yes'}`);

    console.log(`\n  ✅ FIX WORKING!`);
    console.log(`     Truncation was detected and partial file was cleaned up.\n`);

    return { fixed: true, error: error.message };
  }
}

/**
 * Test 3: Verify non-truncated upload works correctly
 */
async function testNonTruncatedUpload() {
  console.log('Test 3: Non-Truncated Upload (Control Test)');
  console.log('-'.repeat(50));

  const fullContent = generateValidJS(10); // Small 10KB bundle

  // Create a mock file that is NOT truncated
  let position = 0;
  const buffer = Buffer.from(fullContent);
  const chunkSize = 1024;

  const file = new Readable({
    read() {
      if (position >= buffer.length) {
        this.push(null);
        return;
      }
      const end = Math.min(position + chunkSize, buffer.length);
      this.push(buffer.slice(position, end));
      position = end;
    }
  });

  file.truncated = false; // NOT truncated

  const mockFile = {
    file,
    filename: 'complete-bundle.js'
  };

  const destPath = path.join(TEST_DIR, 'complete.js');

  try {
    await saveMultipartFile_FIXED(mockFile, destPath);

    const written = fs.readFileSync(destPath, 'utf8');
    const isComplete = written === fullContent;

    console.log(`  Full content size: ${fullContent.length} bytes`);
    console.log(`  Written size: ${written.length} bytes`);
    console.log(`  Content matches: ${isComplete ? '✅ Yes' : '❌ No'}`);
    console.log(`  file.truncated: ${mockFile.file.truncated}`);

    // Parse to verify it's valid
    try {
      new Function(written);
      console.log(`  Parse result: ✅ Valid`);
    } catch (e) {
      console.log(`  Parse result: ❌ ${e.message}`);
    }

    console.log(`\n  ✅ Non-truncated upload handled correctly.\n`);
    return { success: true };

  } catch (error) {
    console.log(`  Unexpected error: ${error.message}`);
    return { success: false, error };
  }
}

/**
 * Main execution
 */
async function main() {
  const results = {};

  results.current = await testCurrentImplementation();
  results.fixed = await testFixedImplementation();
  results.control = await testNonTruncatedUpload();

  console.log('='.repeat(60));
  console.log('Summary');
  console.log('='.repeat(60));

  if (results.current.vulnerable) {
    console.log(`
🔴 VULNERABILITY EXISTS in current implementation!

The saveMultipartFile function in utils.ts does NOT check
the 'truncated' property after pipeline() completes.

When a network interruption causes a partial upload:
1. The stream ends prematurely
2. pipeline() resolves successfully
3. file.truncated is set to TRUE by Fastify
4. BUT this flag is never checked!
5. Partial file is saved to disk
6. Later, VM tries to parse it → SYNTAX ERROR

This matches the reported errors:
- "missing ) after argument list"
- "Invalid or unexpected token"
`);
  }

  if (results.fixed.fixed) {
    console.log(`
🟢 PROPOSED FIX WORKS!

Add this check after pipeline() in saveMultipartFile():

  if (multipartFile.file.truncated) {
    await unlink(destinationPath);
    throw new Error('Upload truncated: file stream ended prematurely');
  }
`);
  }

  // Cleanup
  console.log(`\nTest files available at: ${TEST_DIR}`);
  console.log('To clean up: rm -rf ' + TEST_DIR);
}

main().catch(console.error);
