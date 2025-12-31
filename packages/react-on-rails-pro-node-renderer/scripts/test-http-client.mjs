#!/usr/bin/env node
/**
 * HTTP Client that sends an interrupted upload to the node renderer
 *
 * Usage:
 *   node scripts/test-http-client.mjs [interrupt_percent]
 *
 * Example:
 *   node scripts/test-http-client.mjs 50
 */

import http from 'node:http';
import { Readable } from 'node:stream';
import crypto from 'node:crypto';

const PORT = 3222;
const HOST = '127.0.0.1';
const BUNDLE_SIZE_MB = 10;
const INTERRUPT_PERCENT = parseInt(process.argv[2] || '50', 10);

console.log('='.repeat(60));
console.log('HTTP UPLOAD INTERRUPTION TEST');
console.log('='.repeat(60));
console.log(`Target: http://${HOST}:${PORT}`);
console.log(`Bundle size: ${BUNDLE_SIZE_MB}MB`);
console.log(`Interrupt at: ${INTERRUPT_PERCENT}%`);
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

  // Add the bundle file
  body += `--${boundary}\r\n`;
  body += `Content-Disposition: form-data; name="bundle"; filename="${bundleFilename}"\r\n`;
  body += `Content-Type: application/javascript\r\n\r\n`;

  const header = Buffer.from(body, 'utf8');
  const footer = Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8');

  return {
    boundary,
    header,
    footer,
    bundle: bundleBuffer,
    totalSize: header.length + bundleBuffer.length + footer.length,
  };
}

async function main() {
  const bundleTimestamp = Date.now();
  const bundleFilename = `${bundleTimestamp}.js`;
  const bundleBuffer = generateBundle(BUNDLE_SIZE_MB);

  console.log(`Generated bundle: ${bundleFilename} (${(bundleBuffer.length / 1024 / 1024).toFixed(2)}MB)`);

  const multipart = createMultipartBody(bundleBuffer, bundleFilename);
  const interruptAt = Math.floor(multipart.totalSize * (INTERRUPT_PERCENT / 100));

  console.log(`Total payload size: ${(multipart.totalSize / 1024 / 1024).toFixed(2)}MB`);
  console.log(`Will interrupt at: ${(interruptAt / 1024 / 1024).toFixed(2)}MB (${INTERRUPT_PERCENT}%)`);
  console.log('');

  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: HOST,
      port: PORT,
      path: `/bundles/${bundleTimestamp}/render/test-digest`,
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${multipart.boundary}`,
        'Content-Length': multipart.totalSize,
      },
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        console.log(`\nResponse status: ${res.statusCode}`);
        console.log(`Response body (first 500 chars):\n${body.substring(0, 500)}`);
        resolve();
      });
    });

    req.on('error', (err) => {
      console.log(`\nRequest error: ${err.message}`);
      resolve(); // Don't reject, we expect this might happen
    });

    // Write header
    console.log('Sending header...');
    req.write(multipart.header);

    // Write bundle in chunks with interruption
    let bytesSent = multipart.header.length;
    const chunkSize = 64 * 1024; // 64KB chunks
    let position = 0;

    const sendNextChunk = () => {
      if (position >= multipart.bundle.length) {
        // Done with bundle, send footer
        console.log('Sending footer...');
        req.write(multipart.footer);
        req.end();
        return;
      }

      const chunk = multipart.bundle.slice(position, position + chunkSize);
      position += chunk.length;
      bytesSent += chunk.length;

      // Check if we should interrupt
      if (bytesSent >= interruptAt) {
        console.log(`\n🔴 INTERRUPTING CONNECTION at ${(bytesSent / 1024 / 1024).toFixed(2)}MB (${((bytesSent / multipart.totalSize) * 100).toFixed(1)}%)`);
        console.log('Destroying socket...');
        req.destroy();

        // Give server time to process, then resolve
        setTimeout(() => {
          console.log('\nConnection destroyed. Check server logs and test directory for partial files.');
          resolve();
        }, 1000);
        return;
      }

      req.write(chunk, () => {
        // Small delay to simulate realistic upload
        setImmediate(sendNextChunk);
      });
    };

    console.log('Sending bundle...');
    sendNextChunk();
  });
}

main().catch(console.error);
