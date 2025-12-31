#!/usr/bin/env node
/**
 * Test: What happens when file is truncated while another fd is writing?
 * 
 * Scenario:
 * 1. Process A opens file, starts writing at position 0
 * 2. Process A writes 100KB, position now at 100KB
 * 3. Process B opens file with O_TRUNC, file becomes 0 bytes
 * 4. Process B writes 50KB
 * 5. Process A continues writing at position 100KB
 * 
 * Question: What's in the file? A's data at 100KB, B's data at 0, zeros in between?
 */

import fsp from 'node:fs/promises';
import { createWriteStream, openSync, writeSync, closeSync } from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const TEST_DIR = path.join(os.tmpdir(), `fd-trunc-${Date.now()}`);
const TEST_FILE = path.join(TEST_DIR, 'test.txt');

console.log('='.repeat(70));
console.log('FILE DESCRIPTOR TRUNCATION TEST');
console.log('='.repeat(70));
console.log(`Test file: ${TEST_FILE}\n`);

async function main() {
  await fsp.mkdir(TEST_DIR, { recursive: true });

  // Use sync operations for precise control
  
  // Step 1: Process A opens file
  console.log('1. Process A opens file (O_CREAT | O_TRUNC | O_WRONLY)');
  const fdA = openSync(TEST_FILE, 'w');
  
  // Step 2: Process A writes 100KB of 'A's
  const chunkA1 = Buffer.alloc(100 * 1024, 'A');
  console.log('2. Process A writes 100KB of "A"s');
  writeSync(fdA, chunkA1);
  console.log(`   File size now: ${(await fsp.stat(TEST_FILE)).size} bytes`);
  
  // Step 3: Process B opens with O_TRUNC - this truncates the file!
  console.log('3. Process B opens file with O_TRUNC (truncates to 0!)');
  const fdB = openSync(TEST_FILE, 'w');
  console.log(`   File size now: ${(await fsp.stat(TEST_FILE)).size} bytes`);
  
  // Step 4: Process B writes 50KB of 'B's  
  const chunkB = Buffer.alloc(50 * 1024, 'B');
  console.log('4. Process B writes 50KB of "B"s');
  writeSync(fdB, chunkB);
  console.log(`   File size now: ${(await fsp.stat(TEST_FILE)).size} bytes`);
  
  // Step 5: Process A continues writing at ITS position (100KB)
  const chunkA2 = Buffer.alloc(50 * 1024, 'A');
  console.log('5. Process A writes 50KB more "A"s at its position (100KB)');
  writeSync(fdA, chunkA2);
  console.log(`   File size now: ${(await fsp.stat(TEST_FILE)).size} bytes`);
  
  // Close both
  closeSync(fdA);
  closeSync(fdB);
  
  // Analyze the result
  console.log('\n' + '─'.repeat(70));
  console.log('RESULT ANALYSIS');
  console.log('─'.repeat(70));
  
  const content = await fsp.readFile(TEST_FILE);
  console.log(`\nFinal file size: ${content.length} bytes`);
  
  // Count characters in different regions
  const regions = [
    { start: 0, end: 50 * 1024, name: 'First 50KB' },
    { start: 50 * 1024, end: 100 * 1024, name: '50KB-100KB' },
    { start: 100 * 1024, end: 150 * 1024, name: '100KB-150KB' },
  ];
  
  for (const region of regions) {
    if (region.start >= content.length) {
      console.log(`${region.name}: (beyond file end)`);
      continue;
    }
    
    const slice = content.slice(region.start, Math.min(region.end, content.length));
    const countA = slice.filter(b => b === 65).length; // 'A'
    const countB = slice.filter(b => b === 66).length; // 'B'
    const countZero = slice.filter(b => b === 0).length; // null bytes
    const countOther = slice.length - countA - countB - countZero;
    
    console.log(`${region.name}: ${countA} A's, ${countB} B's, ${countZero} zeros, ${countOther} other`);
  }
  
  // Check if file would be valid JS
  const contentStr = content.toString('utf8');
  const hasNullBytes = content.includes(0);
  
  console.log(`\nContains null bytes: ${hasNullBytes}`);
  
  if (hasNullBytes) {
    console.log(`
🔴 CORRUPTION CONFIRMED!

When Process B truncates the file while A's fd is still open:
- B writes at position 0
- A continues writing at its saved position (100KB)
- Gap between 50KB-100KB is filled with NULL BYTES!

This creates an INVALID JavaScript file that causes:
"Invalid or unexpected token" (null bytes are not valid JS)
`);
  }

  console.log(`\nTest directory: ${TEST_DIR}`);
}

main().catch(console.error);
