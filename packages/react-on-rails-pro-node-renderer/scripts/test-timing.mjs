#!/usr/bin/env node
/**
 * Test to prove the timing of file save vs move operations
 *
 * Question: Can the bundle get moved BEFORE the file is fully uploaded?
 *
 * This test traces the exact sequence of operations.
 */

import path from 'node:path';
import os from 'node:os';
import fsp from 'node:fs/promises';
import { Readable, PassThrough } from 'node:stream';
import crypto from 'node:crypto';

const TEST_DIR = path.join(os.tmpdir(), `timing-test-${Date.now()}`);
const BUNDLE_SIZE_MB = 5;

console.log('='.repeat(70));
console.log('TIMING TEST: When does the bundle get moved?');
console.log('='.repeat(70));
console.log(`Test directory: ${TEST_DIR}\n`);

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

function createSlowInterruptingStream(buffer, interruptAtPercent, chunkDelayMs = 10) {
  const interruptAt = Math.floor(buffer.length * (interruptAtPercent / 100));
  let position = 0;
  let chunkCount = 0;

  const stream = new Readable({
    async read(size) {
      if (position >= buffer.length) {
        console.log(`  [${new Date().toISOString()}] Stream: push(null) - END OF STREAM`);
        this.push(null);
        return;
      }

      const chunkSize = Math.min(size || 16384, buffer.length - position);
      const chunk = buffer.slice(position, position + chunkSize);
      position += chunkSize;
      chunkCount++;

      // Check if we should interrupt
      if (position >= interruptAt) {
        console.log(`  [${new Date().toISOString()}] Stream: INTERRUPTING at ${position} bytes (${((position / buffer.length) * 100).toFixed(1)}%)`);
        console.log(`  [${new Date().toISOString()}] Stream: push(null) - PREMATURE END`);

        // End stream prematurely but cleanly
        setTimeout(() => {
          this.push(null);
        }, 10);
        return;
      }

      // Log every 50 chunks
      if (chunkCount % 50 === 0) {
        console.log(`  [${new Date().toISOString()}] Stream: sent ${(position / 1024 / 1024).toFixed(2)}MB`);
      }

      this.push(chunk);

      // Small delay to simulate network
      await new Promise(r => setTimeout(r, chunkDelayMs));
    }
  });

  stream.on('error', () => {});
  return stream;
}

function createMultipartPayload(bundleStream, bundleFilename) {
  const boundary = '----FormBoundary' + crypto.randomBytes(16).toString('hex');

  const headerPart =
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="protocolVersion"\r\n\r\n2.0.0\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="gemVersion"\r\n\r\n16.2.0-beta.20\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="railsEnv"\r\n\r\ntest\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="renderingRequest"\r\n\r\nReactOnRails.dummy()\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="bundle"; filename="${bundleFilename}"\r\n` +
    `Content-Type: application/javascript\r\n\r\n`;

  const footerPart = `\r\n--${boundary}--\r\n`;
  const combinedStream = new PassThrough();

  combinedStream.write(Buffer.from(headerPart, 'utf8'));

  bundleStream.on('data', (chunk) => combinedStream.write(chunk));
  bundleStream.on('end', () => {
    combinedStream.write(Buffer.from(footerPart, 'utf8'));
    combinedStream.end();
  });
  bundleStream.on('error', (err) => combinedStream.destroy(err));

  return {
    boundary,
    stream: combinedStream,
    contentType: `multipart/form-data; boundary=${boundary}`,
  };
}

async function fileExists(filePath) {
  try {
    await fsp.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function getFileSize(filePath) {
  try {
    const stats = await fsp.stat(filePath);
    return stats.size;
  } catch {
    return -1;
  }
}

async function main() {
  await fsp.mkdir(path.join(TEST_DIR, 'uploads'), { recursive: true });

  // Load the worker module
  console.log('Loading worker module...');
  const { createRequire } = await import('module');
  const require = createRequire(import.meta.url);
  const workerModule = require('../lib/worker.js');
  const worker = workerModule.default;
  const disableHttp2 = workerModule.disableHttp2;

  disableHttp2();

  // Patch the worker to add timing logs
  const originalWorker = worker;

  console.log('Creating Fastify app with timing instrumentation...\n');
  const app = originalWorker({
    serverBundleCachePath: TEST_DIR,
    logHttpLevel: 'silent',
  });

  await app.ready();

  // Test with 50% interruption
  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);

  const uploadPath = path.join(TEST_DIR, 'uploads', bundleFilename);
  const bundlePath = path.join(TEST_DIR, String(bundleTimestamp), `${bundleTimestamp}.js`);

  console.log('─'.repeat(70));
  console.log('TEST: Interrupt upload at 50%');
  console.log('─'.repeat(70));
  console.log(`Bundle size: ${(bundleBuffer.length / 1024 / 1024).toFixed(2)}MB`);
  console.log(`Upload path: ${uploadPath}`);
  console.log(`Final bundle path: ${bundlePath}`);
  console.log('');

  // Start monitoring file existence in background
  let monitoring = true;
  const monitorFiles = async () => {
    while (monitoring) {
      const uploadExists = await fileExists(uploadPath);
      const bundleExists = await fileExists(bundlePath);
      const uploadSize = await getFileSize(uploadPath);
      const bundleSize = await getFileSize(bundlePath);

      if (uploadExists || bundleExists) {
        console.log(`  [${new Date().toISOString()}] FILES: upload=${uploadExists ? `${(uploadSize/1024/1024).toFixed(2)}MB` : 'NO'}, bundle=${bundleExists ? `${(bundleSize/1024/1024).toFixed(2)}MB` : 'NO'}`);
      }

      await new Promise(r => setTimeout(r, 100));
    }
  };

  const monitorPromise = monitorFiles();

  // Create the request
  console.log(`[${new Date().toISOString()}] Starting request...`);

  const bundleStream = createSlowInterruptingStream(bundleBuffer, 50, 5);
  const multipart = createMultipartPayload(bundleStream, bundleFilename);

  try {
    const response = await app.inject({
      method: 'POST',
      url: `/bundles/${bundleTimestamp}/render/test-digest`,
      headers: { 'content-type': multipart.contentType },
      payload: multipart.stream,
    });

    console.log(`\n[${new Date().toISOString()}] Response received: ${response.statusCode}`);
  } catch (err) {
    console.log(`\n[${new Date().toISOString()}] Request error: ${err.message}`);
  }

  // Stop monitoring
  monitoring = false;
  await new Promise(r => setTimeout(r, 200));

  // Final check
  console.log('\n' + '─'.repeat(70));
  console.log('FINAL STATE:');
  console.log('─'.repeat(70));

  const finalUploadExists = await fileExists(uploadPath);
  const finalBundleExists = await fileExists(bundlePath);
  const finalUploadSize = await getFileSize(uploadPath);
  const finalBundleSize = await getFileSize(bundlePath);

  console.log(`Upload file: ${finalUploadExists ? `EXISTS (${(finalUploadSize/1024/1024).toFixed(2)}MB)` : 'DOES NOT EXIST'}`);
  console.log(`Bundle file: ${finalBundleExists ? `EXISTS (${(finalBundleSize/1024/1024).toFixed(2)}MB)` : 'DOES NOT EXIST'}`);

  if (finalBundleExists) {
    const content = await fsp.readFile(bundlePath, 'utf8');
    const isComplete = content.includes('COMPLETE_MARKER');
    console.log(`Bundle complete: ${isComplete ? 'YES ✅' : 'NO ❌ (PARTIAL FILE!)'}`);

    if (!isComplete) {
      console.log(`\n🔴 VULNERABILITY CONFIRMED:`);
      console.log(`   The partial file was moved to the bundle directory!`);
      console.log(`   Expected size: ${(bundleBuffer.length/1024/1024).toFixed(2)}MB`);
      console.log(`   Actual size: ${(finalBundleSize/1024/1024).toFixed(2)}MB`);
      console.log(`   Missing: ${((bundleBuffer.length - finalBundleSize)/1024/1024).toFixed(2)}MB`);
    }
  }

  // Cleanup
  await app.close();
  console.log(`\nTest directory: ${TEST_DIR}`);
}

main().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
