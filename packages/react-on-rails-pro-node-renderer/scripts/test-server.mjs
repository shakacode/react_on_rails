#!/usr/bin/env node
/**
 * Start the node renderer server for testing
 */

import path from 'node:path';
import os from 'node:os';

const TEST_DIR = path.join(os.tmpdir(), `upload-test-server-${Date.now()}`);

// Import the worker module (CommonJS)
console.log('Loading worker module...');
const { createRequire } = await import('module');
const require = createRequire(import.meta.url);
const workerModule = require('../lib/worker.js');
const worker = workerModule.default;

// Create the Fastify app
console.log('Creating Fastify app...');
console.log(`Test directory: ${TEST_DIR}`);

const app = worker({
  serverBundleCachePath: TEST_DIR,
  logHttpLevel: 'info',
});

// Start listening
const PORT = 3222;
await app.listen({ port: PORT, host: '127.0.0.1' });
console.log(`\n✅ Server listening on http://127.0.0.1:${PORT}`);
console.log(`\nTest directory: ${TEST_DIR}`);
console.log('\nPress Ctrl+C to stop the server\n');
