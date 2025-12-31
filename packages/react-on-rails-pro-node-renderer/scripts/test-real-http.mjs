#!/usr/bin/env node
/**
 * Complete HTTP upload interruption test
 * Starts server, sends interrupted request, checks for partial files
 */

import http from 'node:http';
import crypto from 'node:crypto';
import path from 'node:path';
import os from 'node:os';
import fsp from 'node:fs/promises';

const PORT = 3222;
const HOST = '127.0.0.1';
const BUNDLE_SIZE_MB = 10;
const TEST_DIR = path.join(os.tmpdir(), `real-http-test-${Date.now()}`);

console.log('='.repeat(60));
console.log('REAL HTTP UPLOAD INTERRUPTION TEST');
console.log('='.repeat(60));
console.log(`Test directory: ${TEST_DIR}`);
console.log('');

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

// Create multipart form body
function createMultipartBody(bundleBuffer, bundleFilename) {
  const boundary = '----FormBoundary' + crypto.randomBytes(16).toString('hex');
  const fields = [
    { name: 'protocolVersion', value: '2.0.0' },
    { name: 'gemVersion', value: '16.2.0-beta.20' },
    { name: 'railsEnv', value: 'test' },
    { name: 'renderingRequest', value: 'ReactOnRails.dummy()' },
  ];

  let body = '';
  for (const field of fields) {
    body += `--${boundary}\r\n`;
    body += `Content-Disposition: form-data; name="${field.name}"\r\n\r\n`;
    body += `${field.value}\r\n`;
  }
  body += `--${boundary}\r\n`;
  body += `Content-Disposition: form-data; name="bundle"; filename="${bundleFilename}"\r\n`;
  body += `Content-Type: application/javascript\r\n\r\n`;

  const header = Buffer.from(body, 'utf8');
  const footer = Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8');

  return { boundary, header, footer, bundle: bundleBuffer };
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

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
  } catch (err) { /* ignore */ }
  return files;
}

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

async function sendInterruptedRequest(interruptPercent) {
  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);
  const multipart = createMultipartBody(bundleBuffer, bundleFilename);
  const totalSize = multipart.header.length + multipart.bundle.length + multipart.footer.length;
  const interruptAt = Math.floor(totalSize * (interruptPercent / 100));

  console.log(`  Bundle: ${bundleFilename}`);
  console.log(`  Interrupt at: ${interruptPercent}% (${(interruptAt / 1024 / 1024).toFixed(2)}MB)`);

  return new Promise((resolve) => {
    const req = http.request({
      hostname: HOST,
      port: PORT,
      path: `/bundles/${bundleTimestamp}/render/test-digest`,
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${multipart.boundary}`,
        'Content-Length': totalSize,
      },
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        console.log(`  Response: ${res.statusCode}`);
        resolve({ statusCode: res.statusCode, body });
      });
    });

    req.on('error', (err) => {
      console.log(`  Request error: ${err.message}`);
      resolve({ error: err.message });
    });

    // Send data
    (async () => {
      req.write(multipart.header);
      await sleep(5);

      const chunkSize = 256 * 1024;
      let position = 0;
      let bytesSent = multipart.header.length;

      while (position < multipart.bundle.length) {
        const chunk = multipart.bundle.slice(position, position + chunkSize);
        position += chunk.length;
        bytesSent += chunk.length;

        if (bytesSent >= interruptAt) {
          console.log(`  🔴 Interrupting connection...`);
          await sleep(50); // Let data flush
          req.destroy();
          await sleep(200);
          resolve({ interrupted: true });
          return;
        }

        req.write(chunk);
        await sleep(1);
      }

      req.write(multipart.footer);
      req.end();
    })();
  });
}

async function main() {
  // Load the worker module
  console.log('Loading worker module...');
  const { createRequire } = await import('module');
  const require = createRequire(import.meta.url);
  const workerModule = require('../lib/worker.js');
  const worker = workerModule.default;

  // Create and start the server
  console.log('Starting server...');
  const app = worker({
    serverBundleCachePath: TEST_DIR,
    logHttpLevel: 'silent',
  });

  await app.listen({ port: PORT, host: HOST });
  console.log(`Server listening on http://${HOST}:${PORT}\n`);

  // Test scenarios
  const scenarios = [
    { name: 'Interrupt at 25%', percent: 25 },
    { name: 'Interrupt at 50%', percent: 50 },
    { name: 'Interrupt at 75%', percent: 75 },
  ];

  const results = [];

  for (const scenario of scenarios) {
    console.log('─'.repeat(60));
    console.log(`TEST: ${scenario.name}`);
    console.log('─'.repeat(60));

    const filesBefore = await listFilesRecursive(TEST_DIR);
    const result = await sendInterruptedRequest(scenario.percent);
    await sleep(500); // Wait for cleanup

    const filesAfter = await listFilesRecursive(TEST_DIR);
    const newFiles = filesAfter.filter(f => !filesBefore.some(b => b.path === f.path));

    let partialFound = false;
    for (const file of newFiles) {
      const status = await isFileComplete(file.path);
      const isPartial = status.hasStart && !status.hasMarker;
      if (isPartial) {
        partialFound = true;
        console.log(`  🔴 PARTIAL FILE: ${file.name} (${(file.size / 1024 / 1024).toFixed(2)}MB)`);
      }
    }

    if (newFiles.length === 0) {
      console.log(`  ✅ No files created`);
    }

    results.push({
      scenario: scenario.name,
      percent: scenario.percent,
      interrupted: result.interrupted,
      statusCode: result.statusCode,
      partialFound,
      newFiles: newFiles.length
    });

    console.log('');
  }

  // Summary
  console.log('='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log('');
  console.log('┌─────────────────────┬────────────┬─────────────┐');
  console.log('│ Scenario            │ New Files  │ Partial?    │');
  console.log('├─────────────────────┼────────────┼─────────────┤');
  for (const r of results) {
    const partial = r.partialFound ? '❌ YES' : '✅ NO';
    console.log(`│ ${r.scenario.padEnd(19)} │ ${String(r.newFiles).padStart(10)} │ ${partial.padEnd(11)} │`);
  }
  console.log('└─────────────────────┴────────────┴─────────────┘');

  const anyPartial = results.some(r => r.partialFound);
  console.log('');
  if (anyPartial) {
    console.log('🔴 PARTIAL FILES DETECTED!');
    console.log('Upload interruption leaves corrupted files on disk.');
  } else {
    console.log('✅ No partial files - upload interruption handled correctly.');
  }

  // Show test directory contents
  console.log('');
  console.log('Test directory contents:');
  const allFiles = await listFilesRecursive(TEST_DIR);
  for (const f of allFiles) {
    console.log(`  ${f.path} (${(f.size / 1024 / 1024).toFixed(2)}MB)`);
  }

  // Cleanup
  await app.close();
  console.log(`\nTest directory: ${TEST_DIR}`);
}

main().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
