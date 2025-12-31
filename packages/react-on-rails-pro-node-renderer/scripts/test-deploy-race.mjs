#!/usr/bin/env node
/**
 * Test: DEPLOY RACE CONDITION
 * 
 * Hypothesis: If deployment process writes bundle directly to /bundles/ 
 * (not via HTTP upload), concurrent requests can read partial file.
 * 
 * This matches the pattern:
 * - Errors appear AFTER new deploy
 * - First few requests fail with SyntaxError
 * - Later requests succeed
 * 
 * The lock only protects the /uploads/ → /bundles/ move,
 * NOT direct reads of existing bundles.
 */

import path from 'node:path';
import os from 'node:os';
import fsp from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { Readable } from 'node:stream';

const TEST_DIR = path.join(os.tmpdir(), `deploy-race-${Date.now()}`);
const BUNDLE_SIZE_MB = 5;

console.log('='.repeat(70));
console.log('DEPLOY RACE CONDITION TEST');
console.log('='.repeat(70));
console.log(`Test directory: ${TEST_DIR}\n`);

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

// Simulate slow deployment file write (like rsync or docker copy)
async function slowWriteFile(content, destPath, delayPerChunkMs = 20) {
  await fsp.mkdir(path.dirname(destPath), { recursive: true });
  
  const chunkSize = 64 * 1024;
  let position = 0;

  const readStream = new Readable({
    read() {
      if (position >= content.length) {
        this.push(null);
        return;
      }

      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;

      setTimeout(() => {
        this.push(chunk);
      }, delayPerChunkMs);
    }
  });

  const writeStream = createWriteStream(destPath);
  return pipeline(readStream, writeStream);
}

// Simulate request that reads bundle (like buildVM does)
async function simulateRequest(bundlePath, requestId) {
  const startTime = Date.now();
  
  try {
    // Check if file exists (like fileExistsAsync)
    await fsp.access(bundlePath);
    
    // Read file (like readFileAsync in buildVM)
    const content = await fsp.readFile(bundlePath, 'utf8');
    
    // Try to execute as JS (like vm.runInContext)
    try {
      new Function(content);
      const isComplete = content.includes('COMPLETE_MARKER');
      return {
        id: requestId,
        success: true,
        complete: isComplete,
        size: content.length,
        elapsed: Date.now() - startTime
      };
    } catch (e) {
      return {
        id: requestId,
        success: false,
        error: e.message.substring(0, 50),
        size: content.length,
        elapsed: Date.now() - startTime
      };
    }
  } catch (e) {
    return {
      id: requestId,
      success: false,
      error: `File access: ${e.code}`,
      elapsed: Date.now() - startTime
    };
  }
}

async function main() {
  const bundleHash = 'abc123';
  const bundlePath = path.join(TEST_DIR, bundleHash, `${bundleHash}.js`);
  const bundleContent = generateBundle(BUNDLE_SIZE_MB);

  console.log(`Bundle path: ${bundlePath}`);
  console.log(`Bundle size: ${(bundleContent.length / 1024 / 1024).toFixed(2)}MB`);
  console.log('');
  console.log('─'.repeat(70));
  console.log('Simulating: Deploy writes bundle while requests arrive');
  console.log('─'.repeat(70));
  console.log('');

  let deployComplete = false;
  const results = [];

  // Start "deployment" - writing bundle directly to bundles directory
  console.log(`[${Date.now()}] DEPLOY: Starting to write bundle...`);
  const deployPromise = slowWriteFile(bundleContent, bundlePath, 10).then(() => {
    deployComplete = true;
    console.log(`[${Date.now()}] DEPLOY: Bundle write COMPLETE`);
  });

  // Wait a bit for file to be created
  await new Promise(r => setTimeout(r, 50));

  // Concurrent requests during deployment
  const concurrentRequests = [];
  for (let i = 1; i <= 15; i++) {
    await new Promise(r => setTimeout(r, 100));
    
    const reqPromise = simulateRequest(bundlePath, `R${i}`).then(result => {
      result.deployComplete = deployComplete;
      const status = result.success && result.complete 
        ? '✅ SUCCESS' 
        : result.success && !result.complete 
          ? '⚠️ PARTIAL' 
          : '❌ ERROR';
      console.log(`[${Date.now()}] Request ${result.id}: ${status}${result.error ? ` (${result.error})` : ''} [deploy=${deployComplete}]`);
      return result;
    });
    
    concurrentRequests.push(reqPromise);
  }

  // Wait for all requests and deployment
  const allResults = await Promise.all([deployPromise, ...concurrentRequests]);
  results.push(...allResults.slice(1)); // Skip deploy promise result

  // Requests after deployment complete
  console.log('');
  console.log(`[${Date.now()}] Sending requests AFTER deploy complete...`);
  for (let i = 1; i <= 3; i++) {
    const result = await simulateRequest(bundlePath, `POST-${i}`);
    result.deployComplete = true;
    const status = result.success && result.complete ? '✅ SUCCESS' : '❌ ERROR';
    console.log(`[${Date.now()}] Request ${result.id}: ${status}`);
    results.push(result);
  }

  // Summary
  console.log('');
  console.log('─'.repeat(70));
  console.log('SUMMARY');
  console.log('─'.repeat(70));

  const errorsDuringDeploy = results.filter(r => (!r.success || !r.complete) && !r.deployComplete);
  const successDuringDeploy = results.filter(r => r.success && r.complete && !r.deployComplete);
  const errorsAfterDeploy = results.filter(r => (!r.success || !r.complete) && r.deployComplete);
  const successAfterDeploy = results.filter(r => r.success && r.complete && r.deployComplete);

  console.log('');
  console.log(`During deploy:   ${errorsDuringDeploy.length} errors, ${successDuringDeploy.length} success`);
  console.log(`After deploy:    ${errorsAfterDeploy.length} errors, ${successAfterDeploy.length} success`);

  if (errorsDuringDeploy.length > 0 && errorsAfterDeploy.length === 0) {
    console.log(`
🔴 DEPLOY RACE CONDITION CONFIRMED!

Pattern matches user report:
- Errors occur DURING bundle deployment (first few requests)
- Errors disappear AFTER deployment completes
- File exists but is incomplete → SyntaxError

This explains why:
- "first few requests fail, then works"
- Errors appear "after new deploy"
- Bundle timestamp is stable (same hash until deploy)

ROOT CAUSE:
The bundle file is written directly during deployment.
No lock protects reads of existing bundles.
Concurrent requests read partial file during write.
`);
  } else if (errorsDuringDeploy.length === 0) {
    console.log(`
✅ No errors during deploy (timing may not have triggered the race).
Try increasing BUNDLE_SIZE_MB or decreasing delay.
`);
  }

  console.log(`Test directory: ${TEST_DIR}`);
}

main().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
