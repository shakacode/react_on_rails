#!/usr/bin/env node
/**
 * Test: Upload truncation race with O_TRUNC
 * 
 * When multiple workers open the same file with createWriteStream,
 * O_TRUNC truncates the file. This can cause corruption if:
 * 1. Worker A opens file, truncates, starts writing
 * 2. Worker B opens file, truncates (A's data lost!), starts writing
 * 3. Worker A continues writing at its internal position
 * 4. Result: corrupted file
 */

import fsp from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const TEST_DIR = path.join(os.tmpdir(), `trunc-race-${Date.now()}`);
const UPLOAD_FILE = path.join(TEST_DIR, 'bundle.js');

console.log('='.repeat(70));
console.log('UPLOAD O_TRUNC RACE TEST');
console.log('='.repeat(70));

function generateBundle(sizeMB) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = '// BUNDLE START\nvar ReactOnRails = { test: true };\n';
  const line = 'console.log("' + 'x'.repeat(100) + '");\n';
  while (content.length < targetSize - 100) {
    content += line;
  }
  content += '// BUNDLE END - COMPLETE_MARKER\n';
  return Buffer.from(content, 'utf8');
}

// Simulate saveMultipartFile - writes in chunks with delays
async function simulateUpload(id, content, startDelay = 0) {
  await new Promise(r => setTimeout(r, startDelay));
  
  console.log(`[${Date.now()}] Worker ${id}: Opening file (O_TRUNC)`);
  
  return new Promise((resolve, reject) => {
    const stream = createWriteStream(UPLOAD_FILE); // O_TRUNC by default
    let position = 0;
    const chunkSize = 64 * 1024;
    let chunksWritten = 0;

    stream.on('open', () => {
      console.log(`[${Date.now()}] Worker ${id}: File opened, starting write`);
    });

    const writeNext = () => {
      if (position >= content.length) {
        stream.end();
        return;
      }

      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;
      chunksWritten++;

      // Random delay to simulate network/disk variability
      setTimeout(() => {
        stream.write(chunk, writeNext);
      }, Math.random() * 5);
    };

    stream.on('finish', () => {
      console.log(`[${Date.now()}] Worker ${id}: Finished (${chunksWritten} chunks)`);
      resolve({ id, chunksWritten });
    });
    stream.on('error', reject);

    writeNext();
  });
}

async function runTest(description, delays) {
  console.log(`\n--- ${description} ---`);
  
  // Clean up
  try { await fsp.unlink(UPLOAD_FILE); } catch {}
  
  const bundle = generateBundle(2); // 2MB
  const expectedSize = bundle.length;
  
  // Start uploads with specified delays
  await Promise.all([
    simulateUpload('A', bundle, delays.A),
    simulateUpload('B', bundle, delays.B),
  ]);

  // Check result
  const stats = await fsp.stat(UPLOAD_FILE);
  const content = await fsp.readFile(UPLOAD_FILE, 'utf8');
  const hasStart = content.includes('BUNDLE START');
  const hasEnd = content.includes('COMPLETE_MARKER');
  
  let jsValid = false;
  try {
    new Function(content);
    jsValid = true;
  } catch (e) {
    console.log(`JS Error: ${e.message.substring(0, 60)}`);
  }

  const status = jsValid && hasEnd ? '✅ VALID' : '❌ CORRUPTED';
  console.log(`Result: ${status} (size: ${stats.size}/${expectedSize}, hasStart: ${hasStart}, hasEnd: ${hasEnd})`);
  
  return { valid: jsValid && hasEnd, size: stats.size, expectedSize };
}

async function main() {
  await fsp.mkdir(TEST_DIR, { recursive: true });

  const results = [];
  
  // Test 1: Worker B starts slightly after A (typical race)
  results.push(await runTest('B starts 50ms after A', { A: 0, B: 50 }));
  
  // Test 2: Worker B starts much later (A might be done)
  results.push(await runTest('B starts 500ms after A', { A: 0, B: 500 }));
  
  // Test 3: Both start simultaneously
  results.push(await runTest('A and B start simultaneously', { A: 0, B: 0 }));
  
  // Test 4: A starts after B
  results.push(await runTest('A starts 100ms after B', { A: 100, B: 0 }));

  // Run multiple times for test 1 to catch probabilistic races
  console.log('\n--- Running 10 iterations of 50ms delay test ---');
  let corrupted = 0;
  for (let i = 0; i < 10; i++) {
    const r = await runTest(`Iteration ${i+1}`, { A: 0, B: 50 });
    if (!r.valid) corrupted++;
  }
  
  console.log(`\n${'='.repeat(70)}`);
  console.log('SUMMARY');
  console.log('='.repeat(70));
  console.log(`Corrupted in 10 iterations: ${corrupted}/10`);
  
  if (corrupted > 0) {
    console.log(`
🔴 O_TRUNC RACE CONDITION CONFIRMED!

When Worker B opens the file while Worker A is still writing,
O_TRUNC truncates the file, causing corruption.

This explains transient errors after deploy:
1. New deploy = new bundle hash
2. Multiple workers receive requests with new hash
3. All try to upload to /uploads/{hash}.js simultaneously  
4. O_TRUNC race corrupts the file
5. Corrupted file moved to /bundles/
6. SyntaxError on read!

Why transient?
- Only happens during the brief window when new hash appears
- Once one worker successfully writes and moves, others skip upload
- Subsequent requests use the (hopefully correct) cached file
`);
  }

  console.log(`\nTest directory: ${TEST_DIR}`);
}

main().catch(console.error);
