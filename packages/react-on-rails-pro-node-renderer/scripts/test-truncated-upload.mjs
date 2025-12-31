#!/usr/bin/env node
/**
 * Test script to reproduce truncated bundle upload issue.
 *
 * This script:
 * 1. Creates a valid JavaScript bundle
 * 2. Starts uploading it to the Node renderer
 * 3. Aborts mid-upload to simulate network failure
 * 4. Checks if a partial file was written to disk
 * 5. Optionally tests if the renderer would try to use the truncated file
 *
 * Usage:
 *   node scripts/test-truncated-upload.mjs [options]
 *
 * Options:
 *   --renderer-url    URL of the Node renderer (default: http://localhost:3800)
 *   --bundle-size     Size of test bundle in KB (default: 1000)
 *   --abort-at        Percentage of upload to abort at (default: 50)
 *   --cache-path      Path to serverBundleCachePath (default: /tmp/react-on-rails-pro)
 *   --password        Renderer password (default: none)
 *   --check-only      Only check for existing truncated files, don't upload
 */

import http2 from 'node:http2';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { Readable } from 'node:stream';

// Parse command line arguments
const args = process.argv.slice(2);
const getArg = (name, defaultValue) => {
  const index = args.indexOf(`--${name}`);
  return index !== -1 && args[index + 1] ? args[index + 1] : defaultValue;
};

const CONFIG = {
  rendererUrl: getArg('renderer-url', 'http://localhost:3800'),
  bundleSizeKB: parseInt(getArg('bundle-size', '1000'), 10),
  abortAtPercent: parseInt(getArg('abort-at', '50'), 10),
  cachePath: getArg('cache-path', '/tmp/react-on-rails-pro'),
  password: getArg('password', ''),
  checkOnly: args.includes('--check-only'),
};

console.log('='.repeat(60));
console.log('Truncated Upload Reproduction Test');
console.log('='.repeat(60));
console.log('Configuration:');
console.log(`  Renderer URL: ${CONFIG.rendererUrl}`);
console.log(`  Bundle Size: ${CONFIG.bundleSizeKB} KB`);
console.log(`  Abort At: ${CONFIG.abortAtPercent}%`);
console.log(`  Cache Path: ${CONFIG.cachePath}`);
console.log(`  Password: ${CONFIG.password ? '***' : '(none)'}`);
console.log('');

/**
 * Generate a valid JavaScript bundle of specified size.
 * The bundle will have valid syntax so we can verify truncation causes syntax errors.
 */
function generateTestBundle(sizeKB) {
  const targetSize = sizeKB * 1024;

  // Create a bundle with recognizable structure
  let bundle = `
// ==== START OF TEST BUNDLE ====
// Generated at: ${new Date().toISOString()}
// Target size: ${sizeKB} KB

(function() {
  'use strict';

  // Component registry
  var components = {};

  // Register a test component
  components['TestComponent'] = function(props) {
    return {
      type: 'div',
      props: {
        className: 'test-component',
        children: [
`;

  // Add content to reach target size
  // Use valid JS that will break if truncated mid-way
  let contentCount = 0;
  while (bundle.length < targetSize - 500) {
    contentCount++;
    bundle += `          { type: 'span', props: { key: ${contentCount}, children: 'Item ${contentCount}: ${'x'.repeat(100)}' } },\n`;
  }

  // Close the bundle properly
  bundle += `
        ]
      }
    };
  };

  // Export
  if (typeof window !== 'undefined') {
    window.TestComponents = components;
  }
  if (typeof global !== 'undefined') {
    global.TestComponents = components;
  }

  console.log('Test bundle loaded successfully with ' + Object.keys(components).length + ' components');
})();

// ==== END OF TEST BUNDLE ====
// Total items: ${contentCount}
// Bundle hash: ${crypto.randomBytes(16).toString('hex')}
`;

  return bundle;
}

/**
 * Create a readable stream that aborts after sending a percentage of data.
 */
function createAbortingStream(data, abortAtPercent) {
  const buffer = Buffer.from(data);
  const abortAt = Math.floor(buffer.length * (abortAtPercent / 100));
  let position = 0;
  const chunkSize = 1024; // 1KB chunks

  console.log(`  Total size: ${buffer.length} bytes`);
  console.log(`  Will abort at: ${abortAt} bytes (${abortAtPercent}%)`);

  return new Readable({
    read() {
      if (position >= abortAt) {
        console.log(`  [${new Date().toISOString()}] Aborting stream at position ${position}!`);
        // Simulate abrupt connection close - destroy without ending properly
        this.destroy(new Error('Simulated network failure'));
        return;
      }

      const end = Math.min(position + chunkSize, abortAt);
      const chunk = buffer.slice(position, end);
      position = end;

      if (position % (100 * 1024) === 0 || position === end) {
        console.log(`  [${new Date().toISOString()}] Sent ${position} bytes (${Math.round(position / buffer.length * 100)}%)`);
      }

      this.push(chunk);
    }
  });
}

/**
 * Build multipart form data manually.
 */
function buildMultipartFormData(bundleContent, bundleHash, password) {
  const boundary = `----FormBoundary${crypto.randomBytes(16).toString('hex')}`;
  const CRLF = '\r\n';

  let formParts = [];

  // Add protocol version
  formParts.push(
    `--${boundary}${CRLF}`,
    `Content-Disposition: form-data; name="protocolVersion"${CRLF}${CRLF}`,
    `2.0.0${CRLF}`
  );

  // Add gem version
  formParts.push(
    `--${boundary}${CRLF}`,
    `Content-Disposition: form-data; name="gemVersion"${CRLF}${CRLF}`,
    `1.0.0${CRLF}`
  );

  // Add password if provided
  if (password) {
    formParts.push(
      `--${boundary}${CRLF}`,
      `Content-Disposition: form-data; name="password"${CRLF}${CRLF}`,
      `${password}${CRLF}`
    );
  }

  // Add rendering request (minimal)
  const renderingRequest = `ReactOnRails.serverRenderReactComponent({})`;
  formParts.push(
    `--${boundary}${CRLF}`,
    `Content-Disposition: form-data; name="renderingRequest"${CRLF}${CRLF}`,
    `${renderingRequest}${CRLF}`
  );

  // Add bundle file header
  formParts.push(
    `--${boundary}${CRLF}`,
    `Content-Disposition: form-data; name="bundle_${bundleHash}"; filename="${bundleHash}.js"${CRLF}`,
    `Content-Type: text/javascript${CRLF}${CRLF}`
  );

  const header = formParts.join('');
  const footer = `${CRLF}--${boundary}--${CRLF}`;

  return { header, footer, boundary, bundleContent };
}

/**
 * Check for truncated files in the cache directory.
 */
function checkForTruncatedFiles() {
  console.log('\n📁 Checking for files in cache directory...');

  const uploadsDir = path.join(CONFIG.cachePath, 'uploads');
  const bundlesDir = CONFIG.cachePath;

  const checkDir = (dir, label) => {
    console.log(`\n  ${label}: ${dir}`);
    if (!fs.existsSync(dir)) {
      console.log('    Directory does not exist');
      return [];
    }

    const files = [];
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isFile() && entry.name.endsWith('.js')) {
        const stats = fs.statSync(fullPath);
        const content = fs.readFileSync(fullPath, 'utf8');

        // Check for truncation indicators
        const hasStart = content.includes('START OF TEST BUNDLE');
        const hasEnd = content.includes('END OF TEST BUNDLE');
        const isTruncated = hasStart && !hasEnd;

        files.push({
          path: fullPath,
          name: entry.name,
          size: stats.size,
          hasStart,
          hasEnd,
          isTruncated,
          lastModified: stats.mtime
        });

        console.log(`    📄 ${entry.name}`);
        console.log(`       Size: ${stats.size} bytes`);
        console.log(`       Has start marker: ${hasStart}`);
        console.log(`       Has end marker: ${hasEnd}`);
        console.log(`       TRUNCATED: ${isTruncated ? '⚠️  YES!' : '✅ No'}`);

        if (isTruncated) {
          // Try to parse it to show the syntax error
          console.log('       Attempting to parse...');
          try {
            new Function(content);
            console.log('       Parse result: ✅ Valid (unexpected!)');
          } catch (e) {
            console.log(`       Parse result: ❌ ${e.message}`);
          }
        }
      } else if (entry.isDirectory() && entry.name.match(/^[a-f0-9]/)) {
        // Check bundle subdirectories
        const subFiles = checkDir(fullPath, `Bundle dir: ${entry.name}`);
        files.push(...subFiles);
      }
    }

    return files;
  };

  const allFiles = [];
  allFiles.push(...checkDir(uploadsDir, 'Uploads directory'));
  allFiles.push(...checkDir(bundlesDir, 'Bundles directory'));

  const truncatedFiles = allFiles.filter(f => f.isTruncated);

  console.log('\n' + '='.repeat(60));
  console.log(`Summary: Found ${truncatedFiles.length} truncated file(s) out of ${allFiles.length} total`);

  return truncatedFiles;
}

/**
 * Perform the truncated upload test.
 */
async function performTruncatedUpload() {
  console.log('\n🚀 Starting truncated upload test...\n');

  // Generate test bundle
  console.log('1. Generating test bundle...');
  const bundleContent = generateTestBundle(CONFIG.bundleSizeKB);
  const bundleHash = crypto.createHash('md5').update(bundleContent).digest('hex');
  console.log(`   Bundle hash: ${bundleHash}`);
  console.log(`   Bundle size: ${bundleContent.length} bytes`);

  // Build form data
  console.log('\n2. Building multipart form data...');
  const { header, footer, boundary } = buildMultipartFormData(
    bundleContent,
    bundleHash,
    CONFIG.password
  );

  const totalSize = header.length + bundleContent.length + footer.length;
  console.log(`   Total form size: ${totalSize} bytes`);
  console.log(`   Boundary: ${boundary}`);

  // Parse renderer URL
  const url = new URL(CONFIG.rendererUrl);
  const isHttps = url.protocol === 'https:';

  console.log('\n3. Connecting to renderer...');
  console.log(`   URL: ${CONFIG.rendererUrl}/bundles/${bundleHash}/render/test-digest`);

  return new Promise((resolve, reject) => {
    const client = http2.connect(CONFIG.rendererUrl, {
      // Allow self-signed certs for local testing
      rejectUnauthorized: false
    });

    client.on('error', (err) => {
      console.log(`   Connection error: ${err.message}`);
      // This is expected when we abort
    });

    client.on('connect', () => {
      console.log('   Connected!');
    });

    const req = client.request({
      ':method': 'POST',
      ':path': `/bundles/${bundleHash}/render/test-digest`,
      'content-type': `multipart/form-data; boundary=${boundary}`,
      'content-length': totalSize.toString()
    });

    let responseData = '';

    req.on('response', (headers) => {
      console.log(`\n4. Response received:`);
      console.log(`   Status: ${headers[':status']}`);
    });

    req.on('data', (chunk) => {
      responseData += chunk.toString();
    });

    req.on('end', () => {
      console.log(`   Response body: ${responseData.substring(0, 200)}...`);
      client.close();
      resolve(responseData);
    });

    req.on('error', (err) => {
      console.log(`   Request error (expected): ${err.message}`);
      client.close();
      // Don't reject - this is expected behavior
      resolve(null);
    });

    // Send the header
    console.log('\n4. Sending form data (will abort mid-stream)...');
    req.write(header);

    // Create aborting stream for bundle content
    const abortingStream = createAbortingStream(bundleContent, CONFIG.abortAtPercent);

    abortingStream.on('data', (chunk) => {
      req.write(chunk);
    });

    abortingStream.on('error', (err) => {
      console.log(`\n5. Stream aborted: ${err.message}`);
      // Destroy the request without sending footer
      req.destroy();
      client.close();

      // Give the server a moment to write the partial file
      setTimeout(() => {
        resolve(null);
      }, 1000);
    });

    abortingStream.on('end', () => {
      // This shouldn't happen in our test
      req.write(footer);
      req.end();
    });
  });
}

/**
 * Alternative test: Use fetch with AbortController (simpler but may not work with HTTP/2)
 */
async function performTruncatedUploadFetch() {
  console.log('\n🚀 Starting truncated upload test (using fetch)...\n');

  // Generate test bundle
  console.log('1. Generating test bundle...');
  const bundleContent = generateTestBundle(CONFIG.bundleSizeKB);
  const bundleHash = crypto.createHash('md5').update(bundleContent).digest('hex');
  console.log(`   Bundle hash: ${bundleHash}`);
  console.log(`   Bundle size: ${bundleContent.length} bytes`);

  const abortController = new AbortController();
  const abortAt = Math.floor(bundleContent.length * (CONFIG.abortAtPercent / 100));

  // Create a custom ReadableStream that aborts
  let bytesSent = 0;
  const stream = new ReadableStream({
    start(controller) {
      const boundary = `----FormBoundary${crypto.randomBytes(16).toString('hex')}`;
      const CRLF = '\r\n';

      // Build header
      let header = '';
      header += `--${boundary}${CRLF}`;
      header += `Content-Disposition: form-data; name="protocolVersion"${CRLF}${CRLF}`;
      header += `2.0.0${CRLF}`;
      header += `--${boundary}${CRLF}`;
      header += `Content-Disposition: form-data; name="gemVersion"${CRLF}${CRLF}`;
      header += `1.0.0${CRLF}`;
      header += `--${boundary}${CRLF}`;
      header += `Content-Disposition: form-data; name="renderingRequest"${CRLF}${CRLF}`;
      header += `test${CRLF}`;
      header += `--${boundary}${CRLF}`;
      header += `Content-Disposition: form-data; name="bundle_${bundleHash}"; filename="${bundleHash}.js"${CRLF}`;
      header += `Content-Type: text/javascript${CRLF}${CRLF}`;

      controller.enqueue(new TextEncoder().encode(header));

      // Stream bundle content in chunks
      const chunkSize = 1024;
      let position = 0;

      const sendNextChunk = () => {
        if (position >= bundleContent.length) {
          const footer = `${CRLF}--${boundary}--${CRLF}`;
          controller.enqueue(new TextEncoder().encode(footer));
          controller.close();
          return;
        }

        if (bytesSent >= abortAt) {
          console.log(`\n   Aborting at ${bytesSent} bytes!`);
          abortController.abort();
          controller.error(new Error('Simulated abort'));
          return;
        }

        const end = Math.min(position + chunkSize, bundleContent.length);
        const chunk = bundleContent.slice(position, end);
        controller.enqueue(new TextEncoder().encode(chunk));
        bytesSent += chunk.length;
        position = end;

        if (bytesSent % (100 * 1024) < chunkSize) {
          console.log(`   Sent ${bytesSent} bytes...`);
        }

        // Small delay to make abortion more realistic
        setTimeout(sendNextChunk, 1);
      };

      sendNextChunk();
    }
  });

  try {
    const response = await fetch(
      `${CONFIG.rendererUrl}/bundles/${bundleHash}/render/test-digest`,
      {
        method: 'POST',
        body: stream,
        signal: abortController.signal,
        duplex: 'half', // Required for streaming body
        headers: {
          'Content-Type': 'multipart/form-data; boundary=----FormBoundary' + crypto.randomBytes(16).toString('hex')
        }
      }
    );
    console.log(`   Response status: ${response.status}`);
  } catch (err) {
    console.log(`   Request aborted (expected): ${err.message}`);
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    if (CONFIG.checkOnly) {
      checkForTruncatedFiles();
      return;
    }

    // Perform the upload test
    await performTruncatedUpload();

    // Wait a moment for file system operations
    console.log('\n⏳ Waiting for file system to settle...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Check for truncated files
    const truncatedFiles = checkForTruncatedFiles();

    console.log('\n' + '='.repeat(60));
    if (truncatedFiles.length > 0) {
      console.log('🔴 VULNERABILITY CONFIRMED!');
      console.log('   Truncated files were written to disk without validation.');
      console.log('   These files would cause syntax errors if loaded into the VM.');
    } else {
      console.log('🟢 No truncated files found.');
      console.log('   Either:');
      console.log('   1. The upload was rejected before any file was written');
      console.log('   2. The truncation check is working (check for recent changes)');
      console.log('   3. The cache path is incorrect');
    }
    console.log('='.repeat(60));

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
