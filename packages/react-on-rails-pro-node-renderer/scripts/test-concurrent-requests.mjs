#!/usr/bin/env node
/**
 * Test TRANSIENT errors with concurrent requests to the actual node renderer
 *
 * Scenario:
 * - Request A: sends bundle (triggers move/copy)
 * - Request B: does NOT send bundle (uses existing file)
 * - If B reads during A's copy → SyntaxError (transient)
 * - After A completes → subsequent requests work
 */

import path from 'node:path';
import os from 'node:os';
import fsp from 'node:fs/promises';
import { Readable, PassThrough } from 'node:stream';
import crypto from 'node:crypto';

const TEST_DIR = path.join(os.tmpdir(), `concurrent-test-${Date.now()}`);
const BUNDLE_SIZE_MB = 5;

console.log('='.repeat(70));
console.log('CONCURRENT REQUESTS TEST: Transient Error Reproduction');
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

// Create a SLOW stream to simulate large upload
function createSlowStream(buffer, chunkDelayMs = 10) {
  let position = 0;
  const chunkSize = 64 * 1024;

  return new Readable({
    read() {
      if (position >= buffer.length) {
        this.push(null);
        return;
      }

      const chunk = buffer.slice(position, position + chunkSize);
      position += chunk.length;

      setTimeout(() => {
        this.push(chunk);
      }, chunkDelayMs);
    }
  });
}

function createMultipartWithBundle(bundleStream, bundleFilename) {
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

  return { boundary, stream: combinedStream, contentType: `multipart/form-data; boundary=${boundary}` };
}

function createMultipartWithoutBundle() {
  const boundary = '----FormBoundary' + crypto.randomBytes(16).toString('hex');

  const body =
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="protocolVersion"\r\n\r\n2.0.0\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="gemVersion"\r\n\r\n16.2.0-beta.20\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="railsEnv"\r\n\r\ntest\r\n` +
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="renderingRequest"\r\n\r\nReactOnRails.dummy()\r\n` +
    `--${boundary}--\r\n`;

  return { boundary, body, contentType: `multipart/form-data; boundary=${boundary}` };
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

  const app = worker({
    serverBundleCachePath: TEST_DIR,
    logHttpLevel: 'silent',
  });

  await app.ready();

  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);

  console.log(`Bundle timestamp: ${bundleTimestamp}`);
  console.log(`Bundle size: ${(bundleBuffer.length / 1024 / 1024).toFixed(2)}MB\n`);

  console.log('─'.repeat(70));
  console.log('TEST: Concurrent requests - one with bundle, others without');
  console.log('─'.repeat(70));

  const results = [];

  // Request A: Upload bundle (slow)
  console.log(`\n[${Date.now()}] Starting Request A (with slow bundle upload)...`);

  const bundleStream = createSlowStream(bundleBuffer, 5); // 5ms per 64KB chunk
  const multipartA = createMultipartWithBundle(bundleStream, bundleFilename);

  const requestAPromise = app.inject({
    method: 'POST',
    url: `/bundles/${bundleTimestamp}/render/test-digest`,
    headers: { 'content-type': multipartA.contentType },
    payload: multipartA.stream,
  }).then(res => {
    console.log(`[${Date.now()}] Request A completed: ${res.statusCode}`);
    return { name: 'A (upload)', status: res.statusCode, time: Date.now() };
  });

  // Wait a bit for A to start, then send concurrent requests WITHOUT bundle
  await new Promise(r => setTimeout(r, 100));

  const concurrentRequests = [];
  for (let i = 1; i <= 5; i++) {
    await new Promise(r => setTimeout(r, 100)); // Stagger requests

    const multipartB = createMultipartWithoutBundle();

    console.log(`[${Date.now()}] Starting Request B${i} (without bundle, expects existing file)...`);

    const requestPromise = app.inject({
      method: 'POST',
      url: `/bundles/${bundleTimestamp}/render/test-digest`,
      headers: { 'content-type': multipartB.contentType },
      payload: multipartB.body,
    }).then(res => {
      const isError = res.statusCode >= 400;
      console.log(`[${Date.now()}] Request B${i} completed: ${res.statusCode} ${isError ? '❌' : '✅'}`);
      return { name: `B${i} (no upload)`, status: res.statusCode, time: Date.now() };
    });

    concurrentRequests.push(requestPromise);
  }

  // Wait for all requests
  const allResults = await Promise.all([requestAPromise, ...concurrentRequests]);
  results.push(...allResults);

  // Additional requests after A completes (should all work)
  console.log(`\n[${Date.now()}] Sending requests AFTER upload complete...`);

  for (let i = 1; i <= 3; i++) {
    const multipartC = createMultipartWithoutBundle();

    const res = await app.inject({
      method: 'POST',
      url: `/bundles/${bundleTimestamp}/render/test-digest`,
      headers: { 'content-type': multipartC.contentType },
      payload: multipartC.body,
    });

    const isError = res.statusCode >= 400;
    console.log(`[${Date.now()}] Request C${i} (after upload): ${res.statusCode} ${isError ? '❌' : '✅'}`);
    results.push({ name: `C${i} (after)`, status: res.statusCode, time: Date.now() });
  }

  // Summary
  console.log('\n' + '─'.repeat(70));
  console.log('SUMMARY');
  console.log('─'.repeat(70));

  const errors = results.filter(r => r.status >= 400 && r.name.startsWith('B'));
  const successes = results.filter(r => r.status < 400 || r.name === 'A (upload)');

  console.log(`\nTotal requests: ${results.length}`);
  console.log(`Errors during upload: ${errors.length}`);
  console.log(`Successes: ${successes.length}`);

  console.log('\nResults by request:');
  for (const r of results) {
    const symbol = r.status < 400 ? '✅' : '❌';
    console.log(`  ${symbol} ${r.name}: ${r.status}`);
  }

  if (errors.length > 0) {
    console.log(`
🔴 TRANSIENT ERRORS DETECTED!

Requests sent DURING the bundle upload got errors (likely 410 or 400).
Requests sent AFTER the upload completed succeeded.

This matches the "first few requests fail, then works" pattern.
`);
  } else {
    console.log(`
✅ No transient errors detected.
(The timing may need adjustment to trigger the race condition)
`);
  }

  await app.close();
  console.log(`Test directory: ${TEST_DIR}`);
}

main().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
