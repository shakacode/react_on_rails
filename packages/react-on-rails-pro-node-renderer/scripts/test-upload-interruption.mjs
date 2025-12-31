#!/usr/bin/env node
/**
 * Real HTTP Upload Interruption Test
 *
 * This script makes REAL HTTP requests to the Node renderer and tests
 * what happens when the upload is interrupted mid-stream.
 *
 * Usage:
 *   # First, start the renderer in another terminal:
 *   node dist/index.js
 *
 *   # Then run this test:
 *   node scripts/test-upload-interruption.mjs
 *
 *   # Or with custom settings:
 *   RENDERER_URL=http://localhost:3500 RENDERER_SECRET=your-secret node scripts/test-upload-interruption.mjs
 */

import http2 from 'node:http2';
import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { Buffer } from 'node:buffer';

// Configuration
const RENDERER_URL = process.env.RENDERER_URL || 'http://localhost:3500';
const RENDERER_SECRET = process.env.RENDERER_SECRET || 'test-secret';
const BUNDLE_SIZE_MB = 50; // Large enough to give time to interrupt
const UPLOADS_DIR = process.env.UPLOADS_DIR || '/tmp/react-on-rails-pro/uploads';
const BUNDLE_CACHE_DIR = process.env.BUNDLE_CACHE_DIR || '/tmp/react-on-rails-pro';

// Generate a valid JS bundle of specified size
function generateBundle(sizeMB) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = '// BUNDLE START\n(function() {\n';

  const line = '  console.log("' + 'x'.repeat(100) + '");\n';
  while (content.length < targetSize - 500) {
    content += line;
  }

  content += '  return { success: true, marker: "BUNDLE_COMPLETE_MARKER" };\n';
  content += '})();\n// BUNDLE END\n';

  return Buffer.from(content, 'utf8');
}

// Create multipart form data manually for precise control
function createMultipartData(bundleBuffer, bundleFilename, bundleTimestamp) {
  const boundary = '----FormBoundary' + crypto.randomBytes(16).toString('hex');

  const parts = [];

  // Add renderingRequest field
  const renderingRequest = JSON.stringify({
    serverSide: true,
    componentName: 'TestComponent',
    props: {}
  });

  parts.push(
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="renderingRequest"\r\n\r\n` +
    `${renderingRequest}\r\n`
  );

  // Add bundle file
  parts.push(
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="bundle"; filename="${bundleFilename}"\r\n` +
    `Content-Type: application/javascript\r\n\r\n`
  );

  const header = Buffer.from(parts.join(''), 'utf8');
  const footer = Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8');

  return {
    boundary,
    header,
    body: bundleBuffer,
    footer,
    totalLength: header.length + bundleBuffer.length + footer.length
  };
}

// List files in uploads directory
async function listUploadsDir() {
  try {
    await fsp.mkdir(UPLOADS_DIR, { recursive: true });
    const files = await fsp.readdir(UPLOADS_DIR);
    const fileStats = await Promise.all(
      files.map(async (f) => {
        const filePath = path.join(UPLOADS_DIR, f);
        const stats = await fsp.stat(filePath);
        return { name: f, size: stats.size, path: filePath };
      })
    );
    return fileStats;
  } catch (err) {
    return [];
  }
}

// Clean uploads directory
async function cleanUploadsDir() {
  try {
    const files = await fsp.readdir(UPLOADS_DIR);
    for (const f of files) {
      await fsp.unlink(path.join(UPLOADS_DIR, f));
    }
  } catch (err) {
    // Ignore
  }
}

// Check if a file contains complete bundle marker
async function checkFileComplete(filePath) {
  try {
    const content = await fsp.readFile(filePath, 'utf8');
    return {
      hasStartMarker: content.includes('BUNDLE START'),
      hasEndMarker: content.includes('BUNDLE END'),
      hasCompleteMarker: content.includes('BUNDLE_COMPLETE_MARKER'),
      size: content.length,
      isComplete: content.includes('BUNDLE_COMPLETE_MARKER') && content.includes('BUNDLE END')
    };
  } catch (err) {
    return { error: err.message };
  }
}

// Test 1: HTTP/1.1 upload with socket destruction mid-stream
async function testHttp1Interruption(interruptAtPercent) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`TEST: HTTP/1.1 Upload Interrupted at ${interruptAtPercent}%`);
  console.log('='.repeat(60));

  const url = new URL(RENDERER_URL);
  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;

  console.log(`Generating ${BUNDLE_SIZE_MB}MB bundle...`);
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);
  console.log(`Bundle size: ${(bundleBuffer.length / 1024 / 1024).toFixed(2)}MB`);

  const multipart = createMultipartData(bundleBuffer, bundleFilename, bundleTimestamp);
  const interruptAfterBytes = Math.floor(multipart.totalLength * (interruptAtPercent / 100));

  console.log(`Total upload size: ${multipart.totalLength} bytes`);
  console.log(`Will interrupt after: ${interruptAfterBytes} bytes (${interruptAtPercent}%)`);

  // Clean uploads dir before test
  await cleanUploadsDir();
  const filesBefore = await listUploadsDir();
  console.log(`Files in uploads dir before: ${filesBefore.length}`);

  return new Promise((resolve) => {
    const options = {
      hostname: url.hostname,
      port: url.port || 80,
      path: `/bundles/${bundleTimestamp}/render/test-digest`,
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${multipart.boundary}`,
        'Content-Length': multipart.totalLength,
        'Authorization': `Bearer ${RENDERER_SECRET}`,
        'X-React-On-Rails-Pro-Protocol-Version': '2.0.0'
      }
    };

    console.log(`\nConnecting to ${url.hostname}:${url.port}...`);

    const req = http.request(options);

    let bytesSent = 0;
    let interrupted = false;

    req.on('error', (err) => {
      console.log(`Request error (expected after interrupt): ${err.code || err.message}`);
    });

    req.on('response', (res) => {
      console.log(`Response status: ${res.statusCode}`);
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        console.log(`Response body: ${body.substring(0, 200)}...`);
      });
    });

    // Write header
    console.log(`\nSending multipart header (${multipart.header.length} bytes)...`);
    req.write(multipart.header);
    bytesSent += multipart.header.length;

    // Write body in chunks with interrupt
    const chunkSize = 64 * 1024; // 64KB chunks
    let offset = 0;

    const writeNextChunk = () => {
      if (interrupted) return;

      if (offset >= multipart.body.length) {
        // Write footer
        console.log(`Sending footer...`);
        req.write(multipart.footer);
        req.end();

        // Check results after a delay
        setTimeout(async () => {
          const filesAfter = await listUploadsDir();
          console.log(`\nFiles in uploads dir after: ${filesAfter.length}`);
          for (const f of filesAfter) {
            console.log(`  - ${f.name}: ${(f.size / 1024 / 1024).toFixed(2)}MB`);
            const status = await checkFileComplete(f.path);
            console.log(`    Complete: ${status.isComplete ? 'YES ✅' : 'NO ❌'}`);
          }
          resolve({ interrupted: false, filesAfter });
        }, 1000);
        return;
      }

      const end = Math.min(offset + chunkSize, multipart.body.length);
      const chunk = multipart.body.slice(offset, end);

      req.write(chunk);
      bytesSent += chunk.length;
      offset = end;

      // Check if we should interrupt
      if (bytesSent >= interruptAfterBytes && !interrupted) {
        interrupted = true;
        console.log(`\n>>> INTERRUPTING CONNECTION at ${bytesSent} bytes <<<`);

        // Destroy the socket abruptly
        req.destroy();

        // Check for partial files after a delay
        setTimeout(async () => {
          const filesAfter = await listUploadsDir();
          console.log(`\nFiles in uploads dir after interrupt: ${filesAfter.length}`);

          let foundPartial = false;
          for (const f of filesAfter) {
            console.log(`  - ${f.name}: ${(f.size / 1024 / 1024).toFixed(2)}MB`);
            const status = await checkFileComplete(f.path);
            console.log(`    Has start marker: ${status.hasStartMarker ? 'YES' : 'NO'}`);
            console.log(`    Has end marker: ${status.hasEndMarker ? 'YES' : 'NO'}`);
            console.log(`    Is complete: ${status.isComplete ? 'YES ✅' : 'NO ❌ (PARTIAL FILE!)'}`);

            if (!status.isComplete && status.hasStartMarker) {
              foundPartial = true;
              console.log(`\n  🔴 PARTIAL FILE DETECTED!`);
              console.log(`     Size: ${(f.size / 1024 / 1024).toFixed(2)}MB of ${(bundleBuffer.length / 1024 / 1024).toFixed(2)}MB expected`);
            }
          }

          if (filesAfter.length === 0) {
            console.log(`\n  ✅ No partial files left (properly cleaned up)`);
          }

          resolve({ interrupted: true, filesAfter, foundPartial });
        }, 1000);
        return;
      }

      // Continue writing
      setImmediate(writeNextChunk);
    };

    console.log(`Sending bundle data...`);
    writeNextChunk();
  });
}

// Test 2: HTTP/2 upload with stream reset
async function testHttp2Interruption(interruptAtPercent) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`TEST: HTTP/2 Upload Interrupted at ${interruptAtPercent}%`);
  console.log('='.repeat(60));

  const url = new URL(RENDERER_URL);
  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;

  console.log(`Generating ${BUNDLE_SIZE_MB}MB bundle...`);
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);
  console.log(`Bundle size: ${(bundleBuffer.length / 1024 / 1024).toFixed(2)}MB`);

  const multipart = createMultipartData(bundleBuffer, bundleFilename, bundleTimestamp);
  const interruptAfterBytes = Math.floor(multipart.totalLength * (interruptAtPercent / 100));

  console.log(`Total upload size: ${multipart.totalLength} bytes`);
  console.log(`Will interrupt after: ${interruptAfterBytes} bytes (${interruptAtPercent}%)`);

  // Clean uploads dir before test
  await cleanUploadsDir();

  return new Promise((resolve, reject) => {
    const client = http2.connect(`http://${url.hostname}:${url.port}`, {
      // Allow self-signed certs for testing
      rejectUnauthorized: false
    });

    client.on('error', (err) => {
      console.log(`HTTP/2 client error: ${err.message}`);
      // This might be expected if server doesn't support HTTP/2
      if (err.code === 'ERR_HTTP2_ERROR') {
        console.log('Server may not support HTTP/2, try HTTP/1.1 test');
        resolve({ skipped: true, reason: 'HTTP/2 not supported' });
      }
    });

    const headers = {
      ':method': 'POST',
      ':path': `/bundles/${bundleTimestamp}/render/test-digest`,
      'content-type': `multipart/form-data; boundary=${multipart.boundary}`,
      'content-length': multipart.totalLength,
      'authorization': `Bearer ${RENDERER_SECRET}`,
      'x-react-on-rails-pro-protocol-version': '2.0.0'
    };

    const req = client.request(headers);

    let bytesSent = 0;
    let interrupted = false;

    req.on('error', (err) => {
      console.log(`Stream error (may be expected): ${err.message}`);
    });

    req.on('response', (headers) => {
      console.log(`Response status: ${headers[':status']}`);
    });

    req.on('data', (chunk) => {
      console.log(`Response data: ${chunk.toString().substring(0, 100)}...`);
    });

    req.on('end', () => {
      client.close();
    });

    // Write header
    req.write(multipart.header);
    bytesSent += multipart.header.length;

    // Write body in chunks
    const chunkSize = 64 * 1024;
    let offset = 0;

    const writeNextChunk = () => {
      if (interrupted) return;

      if (offset >= multipart.body.length) {
        req.write(multipart.footer);
        req.end();

        setTimeout(async () => {
          client.close();
          const filesAfter = await listUploadsDir();
          console.log(`\nFiles in uploads dir after: ${filesAfter.length}`);
          resolve({ interrupted: false, filesAfter });
        }, 1000);
        return;
      }

      const end = Math.min(offset + chunkSize, multipart.body.length);
      const chunk = multipart.body.slice(offset, end);

      req.write(chunk);
      bytesSent += chunk.length;
      offset = end;

      if (bytesSent >= interruptAfterBytes && !interrupted) {
        interrupted = true;
        console.log(`\n>>> INTERRUPTING HTTP/2 STREAM at ${bytesSent} bytes <<<`);

        // Close the stream abruptly
        req.close(http2.constants.NGHTTP2_CANCEL);
        client.close();

        setTimeout(async () => {
          const filesAfter = await listUploadsDir();
          console.log(`\nFiles in uploads dir after interrupt: ${filesAfter.length}`);

          let foundPartial = false;
          for (const f of filesAfter) {
            console.log(`  - ${f.name}: ${(f.size / 1024 / 1024).toFixed(2)}MB`);
            const status = await checkFileComplete(f.path);
            console.log(`    Is complete: ${status.isComplete ? 'YES ✅' : 'NO ❌'}`);
            if (!status.isComplete && f.size > 0) {
              foundPartial = true;
            }
          }

          resolve({ interrupted: true, filesAfter, foundPartial });
        }, 1000);
        return;
      }

      setImmediate(writeNextChunk);
    };

    console.log(`\nSending via HTTP/2...`);
    writeNextChunk();
  });
}

// Test 3: Slow upload with connection timeout
async function testSlowUpload() {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`TEST: Slow Upload (simulating network issues)`);
  console.log('='.repeat(60));

  const url = new URL(RENDERER_URL);
  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;

  console.log(`Generating ${BUNDLE_SIZE_MB}MB bundle...`);
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);

  const multipart = createMultipartData(bundleBuffer, bundleFilename, bundleTimestamp);

  // Clean uploads dir before test
  await cleanUploadsDir();

  return new Promise((resolve) => {
    const options = {
      hostname: url.hostname,
      port: url.port || 80,
      path: `/bundles/${bundleTimestamp}/render/test-digest`,
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${multipart.boundary}`,
        'Content-Length': multipart.totalLength,
        'Authorization': `Bearer ${RENDERER_SECRET}`,
        'X-React-On-Rails-Pro-Protocol-Version': '2.0.0'
      }
    };

    const req = http.request(options);

    req.on('error', (err) => {
      console.log(`Request error: ${err.message}`);
    });

    // Write header
    req.write(multipart.header);

    // Write first 25% of body
    const firstPart = multipart.body.slice(0, Math.floor(multipart.body.length * 0.25));
    req.write(firstPart);
    console.log(`Sent 25% of data, now pausing for 5 seconds...`);

    // Pause to simulate slow network
    setTimeout(async () => {
      console.log(`Checking uploads dir during pause...`);
      const filesDuring = await listUploadsDir();

      for (const f of filesDuring) {
        console.log(`  - ${f.name}: ${(f.size / 1024 / 1024).toFixed(2)}MB (file exists during upload!)`);
        const status = await checkFileComplete(f.path);
        console.log(`    Complete: ${status.isComplete ? 'YES' : 'NO - PARTIAL FILE VISIBLE!'}`);
      }

      // Now abort
      console.log(`\nAborting connection...`);
      req.destroy();

      setTimeout(async () => {
        const filesAfter = await listUploadsDir();
        console.log(`\nFiles after abort: ${filesAfter.length}`);
        for (const f of filesAfter) {
          console.log(`  - ${f.name}: ${(f.size / 1024 / 1024).toFixed(2)}MB`);
        }
        resolve({ filesDuring, filesAfter });
      }, 1000);
    }, 5000);
  });
}

// Main execution
async function main() {
  console.log('='.repeat(60));
  console.log('REAL HTTP UPLOAD INTERRUPTION TEST');
  console.log('='.repeat(60));
  console.log(`Renderer URL: ${RENDERER_URL}`);
  console.log(`Uploads dir: ${UPLOADS_DIR}`);
  console.log(`Bundle size: ${BUNDLE_SIZE_MB}MB`);
  console.log('');

  // Create uploads dir if needed
  await fsp.mkdir(UPLOADS_DIR, { recursive: true });

  // Check if renderer is running
  console.log('Checking if renderer is running...');
  try {
    const url = new URL(RENDERER_URL);
    await new Promise((resolve, reject) => {
      const req = http.get(`${RENDERER_URL}/info`, (res) => {
        let body = '';
        res.on('data', (chunk) => body += chunk);
        res.on('end', () => {
          console.log(`Renderer info: ${body}`);
          resolve(body);
        });
      });
      req.on('error', reject);
      req.setTimeout(5000, () => {
        req.destroy();
        reject(new Error('Connection timeout'));
      });
    });
  } catch (err) {
    console.error(`\n❌ Cannot connect to renderer at ${RENDERER_URL}`);
    console.error(`   Error: ${err.message}`);
    console.error(`\nPlease start the renderer first:`);
    console.error(`   cd packages/react-on-rails-pro-node-renderer`);
    console.error(`   npm run build && node dist/index.js`);
    console.error(`\nOr set RENDERER_URL environment variable.`);
    process.exit(1);
  }

  const results = {};

  // Test 1: Interrupt at 25%
  try {
    results.http1_25 = await testHttp1Interruption(25);
  } catch (err) {
    console.error(`Test failed: ${err.message}`);
    results.http1_25 = { error: err.message };
  }

  // Test 2: Interrupt at 50%
  try {
    results.http1_50 = await testHttp1Interruption(50);
  } catch (err) {
    console.error(`Test failed: ${err.message}`);
    results.http1_50 = { error: err.message };
  }

  // Test 3: Interrupt at 75%
  try {
    results.http1_75 = await testHttp1Interruption(75);
  } catch (err) {
    console.error(`Test failed: ${err.message}`);
    results.http1_75 = { error: err.message };
  }

  // Test 4: Slow upload test
  try {
    results.slow = await testSlowUpload();
  } catch (err) {
    console.error(`Test failed: ${err.message}`);
    results.slow = { error: err.message };
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));

  const partialFilesFound = Object.values(results).some(r => r.foundPartial);

  if (partialFilesFound) {
    console.log(`
🔴 PARTIAL FILES WERE CREATED!

This means that when an upload is interrupted:
1. The partial file remains on disk
2. It could potentially be used by another worker
3. This could cause "Invalid or unexpected token" errors

The fix should ensure:
- Partial uploads are cleaned up
- Or uploads are written to temp files first
`);
  } else {
    console.log(`
✅ No partial files detected after interruption.

Either:
1. The server properly cleans up partial uploads
2. The server rejects partial uploads with errors
3. Our test didn't catch the race condition

Note: The cross-device move (EXDEV) issue is separate and was
proven in our earlier atomicity tests.
`);
  }

  // Clean up
  await cleanUploadsDir();
}

main().catch(console.error);
