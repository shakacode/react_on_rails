#!/usr/bin/env node
/**
 * Upload Interruption Test using Fastify inject()
 *
 * This test simulates upload interruption by directly testing the
 * Fastify app without needing the full server running.
 *
 * Usage:
 *   node scripts/test-upload-interruption-inject.mjs
 */

import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { Readable, PassThrough } from 'node:stream';
import crypto from 'node:crypto';

// Dynamically import the worker (ESM)
const TEST_DIR = path.join(os.tmpdir(), `upload-interrupt-test-${Date.now()}`);
const UPLOADS_DIR = path.join(TEST_DIR, 'uploads');
const BUNDLE_SIZE_MB = 10;

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

// Create a readable stream that will abort mid-way
function createInterruptingStream(buffer, interruptAtPercent) {
  const interruptAt = Math.floor(buffer.length * (interruptAtPercent / 100));
  let position = 0;
  let interrupted = false;

  const stream = new Readable({
    read(size) {
      if (interrupted) {
        return;
      }

      if (position >= buffer.length) {
        this.push(null);
        return;
      }

      const chunkSize = Math.min(size || 16384, buffer.length - position);
      const chunk = buffer.slice(position, position + chunkSize);
      position += chunkSize;

      // Check if we should interrupt
      if (position >= interruptAt && !interrupted) {
        interrupted = true;
        console.log(`  [Stream] Interrupting at ${position} bytes (${((position / buffer.length) * 100).toFixed(1)}%)`);

        // Just end the stream prematurely without error
        // This simulates a clean but premature close
        process.nextTick(() => {
          this.push(null);  // Signal end of stream
        });
        return;
      }

      this.push(chunk);
    }
  });

  // Suppress error events
  stream.on('error', () => {});

  return stream;
}

// Create multipart form data with a stream
function createMultipartPayload(bundleStream, bundleFilename, bundleSize) {
  const boundary = '----FormBoundary' + crypto.randomBytes(16).toString('hex');

  const renderingRequest = 'ReactOnRails.dummy()';

  // Include required protocol fields in the multipart body
  const headerPart =
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="protocolVersion"\r\n\r\n` +
    `2.0.0\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="gemVersion"\r\n\r\n` +
    `16.2.0-beta.20\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="railsEnv"\r\n\r\n` +
    `test\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="renderingRequest"\r\n\r\n` +
    `${renderingRequest}\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="bundle"; filename="${bundleFilename}"\r\n` +
    `Content-Type: application/javascript\r\n\r\n`;

  const footerPart = `\r\n--${boundary}--\r\n`;

  // Create a combined stream
  const headerBuffer = Buffer.from(headerPart, 'utf8');
  const footerBuffer = Buffer.from(footerPart, 'utf8');

  const combinedStream = new PassThrough();

  // Write header
  combinedStream.write(headerBuffer);

  // Pipe bundle stream
  bundleStream.on('data', (chunk) => {
    combinedStream.write(chunk);
  });

  bundleStream.on('end', () => {
    combinedStream.write(footerBuffer);
    combinedStream.end();
  });

  bundleStream.on('error', (err) => {
    // Pass the error through
    combinedStream.destroy(err);
  });

  return {
    boundary,
    stream: combinedStream,
    contentType: `multipart/form-data; boundary=${boundary}`,
    // Note: Content-Length would be wrong due to interruption - that's the point!
  };
}

// List files in a directory recursively
async function listFilesRecursive(dir) {
  const files = [];
  try {
    const entries = await fsp.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        files.push(...await listFilesRecursive(fullPath));
      } else {
        const stats = await fsp.stat(fullPath);
        files.push({ path: fullPath, name: entry.name, size: stats.size });
      }
    }
  } catch (err) {
    // Ignore errors
  }
  return files;
}

// Check if file contains complete marker
async function isFileComplete(filePath) {
  try {
    const content = await fsp.readFile(filePath, 'utf8');
    return {
      hasStart: content.includes('BUNDLE START'),
      hasEnd: content.includes('BUNDLE END'),
      hasMarker: content.includes('COMPLETE_MARKER'),
      size: content.length
    };
  } catch {
    return { error: true };
  }
}

async function main() {
  console.log('='.repeat(60));
  console.log('UPLOAD INTERRUPTION TEST (via Fastify inject)');
  console.log('='.repeat(60));
  console.log(`Test directory: ${TEST_DIR}`);
  console.log(`Bundle size: ${BUNDLE_SIZE_MB}MB\n`);

  // Create test directories
  await fsp.mkdir(UPLOADS_DIR, { recursive: true });

  // Import the worker module (CommonJS)
  console.log('Loading worker module...');
  let worker, disableHttp2;
  try {
    const { createRequire } = await import('module');
    const require = createRequire(import.meta.url);
    const workerModule = require('../lib/worker.js');
    worker = workerModule.default;
    disableHttp2 = workerModule.disableHttp2;
    console.log('Worker loaded:', typeof worker);
  } catch (err) {
    console.error('Failed to import worker:', err.message);
    console.error(err.stack);
    console.error('\nMake sure to run: pnpm run build');
    process.exit(1);
  }

  // Disable HTTP/2 for inject() compatibility
  disableHttp2();

  // Create the Fastify app
  console.log('Creating Fastify app...');
  const app = worker({
    serverBundleCachePath: TEST_DIR,
    logHttpLevel: 'silent',
  });

  await app.ready();
  console.log('App ready.\n');

  // Test scenarios
  const scenarios = [
    { name: 'Interrupt at 10%', percent: 10 },
    { name: 'Interrupt at 25%', percent: 25 },
    { name: 'Interrupt at 50%', percent: 50 },
    { name: 'Interrupt at 75%', percent: 75 },
    { name: 'Interrupt at 90%', percent: 90 },
  ];

  const results = [];

  for (const scenario of scenarios) {
    console.log('='.repeat(60));
    console.log(`TEST: ${scenario.name}`);
    console.log('='.repeat(60));

    const bundleTimestamp = Date.now();
    const bundleFilename = `${bundleTimestamp}.js`;

    // Generate bundle
    const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);
    console.log(`Bundle size: ${(bundleBuffer.length / 1024 / 1024).toFixed(2)}MB`);

    // Create interrupting stream
    const bundleStream = createInterruptingStream(bundleBuffer, scenario.percent);
    const multipart = createMultipartPayload(bundleStream, bundleFilename, bundleBuffer.length);

    // List files before
    const filesBefore = await listFilesRecursive(TEST_DIR);
    console.log(`Files before: ${filesBefore.length}`);

    // Make request
    console.log(`Sending request to /bundles/${bundleTimestamp}/render/test...`);

    let response;
    let requestError = null;

    try {
      response = await app.inject({
        method: 'POST',
        url: `/bundles/${bundleTimestamp}/render/test-digest`,
        headers: {
          'content-type': multipart.contentType,
        },
        payload: multipart.stream,
      });

      console.log(`Response status: ${response.statusCode}`);
      console.log(`Response body: ${response.payload.substring(0, 100)}...`);
    } catch (err) {
      requestError = err;
      console.log(`Request error (expected): ${err.message}`);
    }

    // Wait a moment for async cleanup
    await new Promise(r => setTimeout(r, 500));

    // List files after
    const filesAfter = await listFilesRecursive(TEST_DIR);
    console.log(`\nFiles after: ${filesAfter.length}`);

    let partialFound = false;
    for (const file of filesAfter) {
      // Skip if file existed before
      if (filesBefore.some(f => f.path === file.path)) continue;

      const status = await isFileComplete(file.path);
      const isPartial = status.hasStart && !status.hasMarker;

      console.log(`  - ${file.name}`);
      console.log(`    Size: ${(file.size / 1024 / 1024).toFixed(2)}MB`);
      console.log(`    Has start marker: ${status.hasStart ? 'YES' : 'NO'}`);
      console.log(`    Has end marker: ${status.hasEnd ? 'YES' : 'NO'}`);
      console.log(`    Complete: ${status.hasMarker ? 'YES ✅' : 'NO ❌'}`);

      if (isPartial) {
        partialFound = true;
        console.log(`    🔴 PARTIAL FILE LEFT ON DISK!`);
      }
    }

    if (filesAfter.length === filesBefore.length) {
      console.log(`  ✅ No new files created (properly rejected/cleaned up)`);
    }

    results.push({
      scenario: scenario.name,
      percent: scenario.percent,
      statusCode: response?.statusCode,
      error: requestError?.message,
      partialFound,
      newFiles: filesAfter.length - filesBefore.length
    });

    console.log('');
  }

  // Summary
  console.log('='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log('');
  console.log('┌────────────────────┬────────┬───────────────┬─────────────┐');
  console.log('│ Scenario           │ Status │ New Files     │ Partial?    │');
  console.log('├────────────────────┼────────┼───────────────┼─────────────┤');

  for (const r of results) {
    const status = r.error ? 'ERROR' : String(r.statusCode);
    const partial = r.partialFound ? '❌ YES' : '✅ NO';
    console.log(`│ ${r.scenario.padEnd(18)} │ ${status.padEnd(6)} │ ${String(r.newFiles).padStart(13)} │ ${partial.padEnd(11)} │`);
  }

  console.log('└────────────────────┴────────┴───────────────┴─────────────┘');

  const anyPartial = results.some(r => r.partialFound);

  if (anyPartial) {
    console.log(`
🔴 PARTIAL FILES WERE LEFT ON DISK!

When upload is interrupted:
- The partial file remains in the uploads directory
- Another request could potentially find and use it
- This could cause syntax errors if the file is executed

The fix should:
1. Clean up partial files on stream error
2. Or use atomic write pattern (write to temp, rename when complete)
`);
  } else {
    console.log(`
✅ No partial files detected.

The upload interruption was handled properly:
- Stream errors caused request to fail
- No partial files were left on disk
`);
  }

  // Cleanup
  await app.close();
  console.log(`\nTest directory: ${TEST_DIR}`);
  console.log(`Cleanup: rm -rf ${TEST_DIR}`);
}

main().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
