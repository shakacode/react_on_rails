#!/usr/bin/env node
/**
 * Real HTTP upload interruption test - Version 2
 * Uses TCP cork/uncork to ensure data is flushed to server
 */

import http from 'node:http';
import net from 'node:net';
import crypto from 'node:crypto';
import path from 'node:path';
import os from 'node:os';
import fsp from 'node:fs/promises';

const PORT = 3222;
const HOST = '127.0.0.1';
const BUNDLE_SIZE_MB = 10;
const TEST_DIR = path.join(os.tmpdir(), `real-http-test-v2-${Date.now()}`);

console.log('='.repeat(60));
console.log('REAL HTTP UPLOAD INTERRUPTION TEST v2');
console.log('='.repeat(60));
console.log(`Test directory: ${TEST_DIR}`);
console.log('');

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

// Send request using raw TCP for more control
async function sendInterruptedRequestRaw(interruptPercent) {
  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);
  const multipart = createMultipartBody(bundleBuffer, bundleFilename);
  const totalSize = multipart.header.length + multipart.bundle.length + multipart.footer.length;
  const interruptAt = Math.floor(totalSize * (interruptPercent / 100));

  console.log(`  Bundle: ${bundleFilename}`);
  console.log(`  Total size: ${(totalSize / 1024 / 1024).toFixed(2)}MB`);
  console.log(`  Interrupt at: ${interruptPercent}% (${(interruptAt / 1024 / 1024).toFixed(2)}MB)`);

  return new Promise((resolve) => {
    const socket = new net.Socket();

    socket.connect(PORT, HOST, async () => {
      // Build HTTP request
      const requestLine = `POST /bundles/${bundleTimestamp}/render/test-digest HTTP/1.1\r\n`;
      const headers = [
        `Host: ${HOST}:${PORT}`,
        `Content-Type: multipart/form-data; boundary=${multipart.boundary}`,
        `Content-Length: ${totalSize}`,
        'Connection: close',
      ].join('\r\n') + '\r\n\r\n';

      // Send HTTP headers
      socket.write(requestLine + headers);

      // Send multipart header
      socket.write(multipart.header);
      await sleep(10);

      // Send bundle in chunks
      const chunkSize = 64 * 1024; // 64KB
      let position = 0;
      let bytesSent = multipart.header.length;

      while (position < multipart.bundle.length) {
        const chunk = multipart.bundle.slice(position, position + chunkSize);
        position += chunk.length;
        bytesSent += chunk.length;

        // Write and wait for it to drain
        const canContinue = socket.write(chunk);
        if (!canContinue) {
          await new Promise(r => socket.once('drain', r));
        }

        // Progress
        if (position % (1024 * 1024) < chunkSize) {
          process.stdout.write(`  Sent: ${(bytesSent / 1024 / 1024).toFixed(1)}MB / ${(totalSize / 1024 / 1024).toFixed(1)}MB\r`);
        }

        // Check if we should interrupt
        if (bytesSent >= interruptAt) {
          console.log(`\n  🔴 Interrupting at ${(bytesSent / 1024 / 1024).toFixed(2)}MB`);

          // Wait to ensure data is flushed to server
          console.log('  Waiting for data to reach server...');
          await sleep(200);

          // Destroy the socket (simulating network failure)
          socket.destroy();
          console.log('  Socket destroyed');

          await sleep(500);
          resolve({ interrupted: true, bytesSent });
          return;
        }

        // Small delay for realism
        await sleep(1);
      }

      // Send footer
      socket.write(multipart.footer);
      socket.end();
    });

    socket.on('error', (err) => {
      console.log(`  Socket error: ${err.message}`);
    });

    socket.on('data', (data) => {
      const response = data.toString();
      const statusMatch = response.match(/HTTP\/\d\.\d (\d+)/);
      if (statusMatch) {
        console.log(`  Response status: ${statusMatch[1]}`);
      }
    });

    socket.on('close', () => {
      resolve({ closed: true });
    });
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
    logHttpLevel: 'info',  // Enable logging to see what happens
  });

  await app.listen({ port: PORT, host: HOST });
  console.log(`Server listening on http://${HOST}:${PORT}\n`);

  // Test scenarios
  const scenarios = [
    { name: 'Interrupt at 50%', percent: 50 },
    { name: 'Interrupt at 75%', percent: 75 },
    { name: 'Interrupt at 90%', percent: 90 },
  ];

  const results = [];

  for (const scenario of scenarios) {
    console.log('─'.repeat(60));
    console.log(`TEST: ${scenario.name}`);
    console.log('─'.repeat(60));

    const filesBefore = await listFilesRecursive(TEST_DIR);
    const result = await sendInterruptedRequestRaw(scenario.percent);
    await sleep(1000); // Wait for server to process

    const filesAfter = await listFilesRecursive(TEST_DIR);
    const newFiles = filesAfter.filter(f => !filesBefore.some(b => b.path === f.path));

    let partialFound = false;
    for (const file of newFiles) {
      if (file.name.endsWith('.lock')) continue; // Skip lock files
      const status = await isFileComplete(file.path);
      const isPartial = status.hasStart && !status.hasMarker;
      if (isPartial) {
        partialFound = true;
        console.log(`  🔴 PARTIAL FILE: ${file.name} (${(file.size / 1024 / 1024).toFixed(2)}MB)`);
      } else if (status.hasMarker) {
        console.log(`  ✅ Complete file: ${file.name}`);
      }
    }

    if (newFiles.filter(f => !f.name.endsWith('.lock')).length === 0) {
      console.log(`  ℹ️  No bundle files created`);
    }

    results.push({
      scenario: scenario.name,
      percent: scenario.percent,
      partialFound,
      newFiles: newFiles.filter(f => !f.name.endsWith('.lock')).length
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
  } else if (results.some(r => r.newFiles > 0)) {
    console.log('ℹ️  Files were created - check if they are complete.');
  } else {
    console.log('ℹ️  No files created - connection closed before data was saved.');
  }

  // Show test directory contents
  console.log('');
  console.log('Test directory contents:');
  const allFiles = await listFilesRecursive(TEST_DIR);
  if (allFiles.length === 0) {
    console.log('  (empty)');
  } else {
    for (const f of allFiles) {
      if (!f.name.endsWith('.lock')) {
        console.log(`  ${f.path} (${(f.size / 1024 / 1024).toFixed(2)}MB)`);
      }
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
