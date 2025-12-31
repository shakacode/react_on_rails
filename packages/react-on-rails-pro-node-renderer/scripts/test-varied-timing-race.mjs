#!/usr/bin/env node
/**
 * Test with varied timing to trigger null byte corruption
 * 
 * The key is: Request A must be AHEAD in writing when B truncates.
 * Then A continues at its position, creating a gap.
 */

import fsp from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { Readable } from 'node:stream';
import path from 'node:path';
import os from 'node:os';

const TEST_DIR = path.join(os.tmpdir(), `varied-race-${Date.now()}`);
const UPLOAD_FILE = path.join(TEST_DIR, 'uploads', 'bundle.js');

function generateBundle(sizeMB) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = '// BUNDLE START\nvar ReactOnRails = { test: true };\n';
  const line = 'console.log("' + 'x'.repeat(100) + '");\n';
  while (content.length < targetSize - 100) {
    content += line;
  }
  content += '// BUNDLE END\n';
  return Buffer.from(content, 'utf8');
}

// Request A: Fast start, slow middle
// Request B: Slow start, fast finish
async function simulateSaveWithPattern(id, content, pattern) {
  console.log(`[${Date.now()}] ${id}: Starting upload`);
  
  const chunkSize = 64 * 1024;
  let position = 0;
  let chunkIndex = 0;
  const totalChunks = Math.ceil(content.length / chunkSize);
  
  const readable = new Readable({
    read() {
      if (position >= content.length) {
        this.push(null);
        return;
      }
      
      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;
      chunkIndex++;
      
      // Different delay patterns
      let delay;
      if (pattern === 'fast-then-slow') {
        // Fast first half, slow second half
        delay = chunkIndex < totalChunks / 2 ? 1 : 20;
      } else if (pattern === 'slow-then-fast') {
        // Slow first half, fast second half
        delay = chunkIndex < totalChunks / 2 ? 20 : 1;
      } else {
        delay = 5;
      }
      
      setTimeout(() => {
        if (chunkIndex === 1) {
          console.log(`[${Date.now()}] ${id}: First chunk written`);
        }
        this.push(chunk);
      }, delay);
    }
  });
  
  const writeStream = createWriteStream(UPLOAD_FILE);
  await pipeline(readable, writeStream);
  console.log(`[${Date.now()}] ${id}: Upload complete`);
}

async function analyzeFile(expectedSize) {
  const content = await fsp.readFile(UPLOAD_FILE);
  const hasNullBytes = content.includes(0);
  const nullByteCount = content.filter(b => b === 0).length;
  
  let jsValid = false;
  try {
    new Function(content.toString());
    jsValid = true;
  } catch (e) {}
  
  return { 
    size: content.length,
    expectedSize,
    hasNullBytes, 
    nullByteCount,
    jsValid,
    sizeMatch: content.length === expectedSize
  };
}

async function runTest(name, delayA, patternA, delayB, patternB) {
  console.log(`\n${'─'.repeat(60)}\n${name}\n${'─'.repeat(60)}`);
  
  await fsp.mkdir(path.dirname(UPLOAD_FILE), { recursive: true });
  try { await fsp.unlink(UPLOAD_FILE); } catch {}
  
  const bundle = generateBundle(2);
  
  await Promise.all([
    new Promise(r => setTimeout(r, delayA)).then(() => 
      simulateSaveWithPattern('A', bundle, patternA)
    ),
    new Promise(r => setTimeout(r, delayB)).then(() => 
      simulateSaveWithPattern('B', bundle, patternB)
    ),
  ]);
  
  const result = await analyzeFile(bundle.length);
  
  if (result.hasNullBytes) {
    console.log(`🔴 CORRUPTED: ${result.nullByteCount} null bytes in ${result.size} byte file`);
    return true;
  } else if (!result.jsValid) {
    console.log(`🔴 INVALID JS`);
    return true;
  } else if (!result.sizeMatch) {
    console.log(`⚠️ SIZE MISMATCH: ${result.size} vs expected ${result.expectedSize}`);
    return true;
  } else {
    console.log(`✅ VALID`);
    return false;
  }
}

async function main() {
  await fsp.mkdir(TEST_DIR, { recursive: true });
  
  console.log('='.repeat(60));
  console.log('VARIED TIMING RACE TEST');
  console.log('='.repeat(60));
  
  let corrupted = 0;
  const iterations = 10;
  
  // A starts fast, writes a lot, then B comes in and truncates
  for (let i = 0; i < iterations; i++) {
    if (await runTest(
      `Test ${i+1}: A fast-start, B slow-start`,
      0,  // A starts immediately
      'fast-then-slow',  // A writes fast initially
      100,  // B starts 100ms later (A already wrote ~500KB)
      'uniform'
    )) {
      corrupted++;
    }
  }
  
  console.log('\n' + '='.repeat(60));
  console.log(`SUMMARY: ${corrupted}/${iterations} corrupted`);
  console.log('='.repeat(60));
  
  if (corrupted > 0) {
    console.log('\n🔴 NULL BYTE CORRUPTION CONFIRMED IN REALISTIC SCENARIO!');
  } else {
    console.log('\n✅ No corruption detected (timing may not have triggered it)');
  }

  console.log(`\nTest directory: ${TEST_DIR}`);
}

main().catch(console.error);
