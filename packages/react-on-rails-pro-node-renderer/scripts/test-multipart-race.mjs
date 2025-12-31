#!/usr/bin/env node
/**
 * Test: Multipart upload race condition causing null bytes
 * 
 * Simulates two concurrent requests uploading the same bundle,
 * where one truncates while the other is mid-write.
 */

import fsp from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { Readable } from 'node:stream';
import path from 'node:path';
import os from 'node:os';

const TEST_DIR = path.join(os.tmpdir(), `multipart-race-${Date.now()}`);
const UPLOAD_FILE = path.join(TEST_DIR, 'uploads', 'abc123.js');

console.log('='.repeat(70));
console.log('MULTIPART UPLOAD RACE CONDITION TEST');
console.log('='.repeat(70));
console.log(`Upload file: ${UPLOAD_FILE}\n`);

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

// Simulates saveMultipartFile - streams content with delays
async function simulateMultipartSave(id, content, startDelay = 0, chunkDelay = 2) {
  await new Promise(r => setTimeout(r, startDelay));
  
  console.log(`[${Date.now()}] Request ${id}: Starting multipart save`);
  
  const chunkSize = 64 * 1024;
  let position = 0;
  let chunkCount = 0;
  
  const readable = new Readable({
    read() {
      if (position >= content.length) {
        this.push(null);
        return;
      }
      
      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;
      chunkCount++;
      
      // Simulate network/processing delay
      setTimeout(() => {
        this.push(chunk);
      }, chunkDelay);
    }
  });
  
  // This is what saveMultipartFile does
  const writeStream = createWriteStream(UPLOAD_FILE);
  
  await pipeline(readable, writeStream);
  
  console.log(`[${Date.now()}] Request ${id}: Finished (${chunkCount} chunks)`);
  return chunkCount;
}

async function analyzeFile() {
  const content = await fsp.readFile(UPLOAD_FILE);
  
  const hasNullBytes = content.includes(0);
  const nullByteCount = content.filter(b => b === 0).length;
  const hasStart = content.toString().includes('BUNDLE START');
  const hasEnd = content.toString().includes('COMPLETE_MARKER');
  
  let jsValid = false;
  let jsError = null;
  try {
    new Function(content.toString());
    jsValid = true;
  } catch (e) {
    jsError = e.message;
  }
  
  return { 
    size: content.length, 
    hasNullBytes, 
    nullByteCount,
    hasStart,
    hasEnd,
    jsValid,
    jsError
  };
}

async function runTest(name, delayA, delayB) {
  console.log(`\n--- ${name} ---`);
  
  // Clean up
  await fsp.mkdir(path.dirname(UPLOAD_FILE), { recursive: true });
  try { await fsp.unlink(UPLOAD_FILE); } catch {}
  
  const bundle = generateBundle(2); // 2MB
  
  // Simulate two concurrent multipart saves
  await Promise.all([
    simulateMultipartSave('A', bundle, delayA),
    simulateMultipartSave('B', bundle, delayB),
  ]);
  
  const result = await analyzeFile();
  
  if (result.hasNullBytes) {
    console.log(`🔴 CORRUPTED: ${result.nullByteCount} null bytes, JS error: ${result.jsError?.substring(0, 50)}`);
  } else if (!result.jsValid) {
    console.log(`🔴 INVALID JS: ${result.jsError?.substring(0, 50)}`);
  } else if (!result.hasEnd) {
    console.log(`⚠️ TRUNCATED: Missing end marker`);
  } else {
    console.log(`✅ VALID: ${result.size} bytes`);
  }
  
  return result;
}

async function main() {
  const results = [];
  
  // Test various timing scenarios
  results.push(await runTest('B starts 20ms after A', 0, 20));
  results.push(await runTest('B starts 50ms after A', 0, 50));
  results.push(await runTest('A and B start together', 0, 0));
  results.push(await runTest('A starts 30ms after B', 30, 0));
  
  // Run multiple iterations of most likely race scenario
  console.log('\n--- Running 20 iterations of staggered start ---');
  let corrupted = 0;
  let valid = 0;
  
  for (let i = 0; i < 20; i++) {
    const r = await runTest(`Iteration ${i+1}`, 0, 30);
    if (r.hasNullBytes || !r.jsValid) corrupted++;
    else valid++;
  }
  
  console.log('\n' + '='.repeat(70));
  console.log('SUMMARY');
  console.log('='.repeat(70));
  console.log(`Corrupted: ${corrupted}/20, Valid: ${valid}/20`);
  
  if (corrupted > 0) {
    console.log(`
🔴 UPLOAD RACE CORRUPTION CONFIRMED!

When two requests upload the same bundle simultaneously:
1. Request A opens /uploads/{hash}.js, starts writing
2. Request B opens /uploads/{hash}.js with O_TRUNC (truncates!)
3. Request A continues writing at ITS position (not file position)
4. Result: NULL BYTES between B's end and A's continued position!

This causes "Invalid or unexpected token" in the VM.

WHY TRANSIENT?
- The corrupted file is moved to /bundles/
- BUT if you have multiple node renderer pods:
  - Pod 1 might get the corrupted file
  - Pod 2 might get a clean file (won the race differently)
  - Load balancer distributes: some fail, some succeed
  - After Pod 1 restarts → all work

OR:
- First bundle upload corrupts
- Error returned to Rails
- Rails' fallback (if enabled) serves the request via ExecJS
- Next request might retry upload and get clean file
`);
  }

  console.log(`\nTest directory: ${TEST_DIR}`);
}

main().catch(console.error);
