#!/usr/bin/env node
import fsp from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const TEST_DIR = path.join(os.tmpdir(), `upload-race-detail-${Date.now()}`);
const UPLOAD_FILE = path.join(TEST_DIR, 'bundle.js');

function generateBundle(id, sizeMB = 0.5) {
  const targetSize = sizeMB * 1024 * 1024;
  let content = `// BUNDLE FROM WRITER ${id}\n`;
  content += `var WRITER_ID = "${id}";\n`;
  const line = `console.log("Writer ${id}: ${'x'.repeat(80)}");\n`;
  while (content.length < targetSize - 100) {
    content += line;
  }
  content += `// END BUNDLE ${id}\n`;
  return Buffer.from(content, 'utf8');
}

async function writeBundle(id, content) {
  return new Promise((resolve, reject) => {
    const stream = createWriteStream(UPLOAD_FILE);
    let position = 0;
    const chunkSize = 64 * 1024;

    const writeNext = () => {
      if (position >= content.length) {
        stream.end();
        return;
      }
      const chunk = content.slice(position, position + chunkSize);
      position += chunk.length;
      setTimeout(() => {
        stream.write(chunk, writeNext);
      }, Math.random() * 10);
    };

    stream.on('finish', () => resolve());
    stream.on('error', reject);
    writeNext();
  });
}

async function main() {
  await fsp.mkdir(TEST_DIR, { recursive: true });

  const bundle1 = generateBundle('A', 0.5);
  const bundle2 = generateBundle('B', 0.5);
  const bundle3 = generateBundle('C', 0.5);

  await Promise.all([
    writeBundle('A', bundle1),
    writeBundle('B', bundle2),
    writeBundle('C', bundle3),
  ]);

  const result = await fsp.readFile(UPLOAD_FILE, 'utf8');
  
  // Count how many times each writer's line appears
  const countA = (result.match(/Writer A:/g) || []).length;
  const countB = (result.match(/Writer B:/g) || []).length;
  const countC = (result.match(/Writer C:/g) || []).length;
  
  const hasHeaderA = result.includes('WRITER_ID = "A"');
  const hasHeaderB = result.includes('WRITER_ID = "B"');
  const hasHeaderC = result.includes('WRITER_ID = "C"');
  const hasEndA = result.includes('END BUNDLE A');
  const hasEndB = result.includes('END BUNDLE B');
  const hasEndC = result.includes('END BUNDLE C');
  
  const mixed = (countA > 0 && countB > 0) || (countA > 0 && countC > 0) || (countB > 0 && countC > 0);
  
  if (mixed) {
    console.log(`INTERLEAVED: A=${countA} B=${countB} C=${countC} lines`);
    // Try to parse as JS
    try {
      new Function(result);
      console.log('JS: VALID (but corrupted content)');
    } catch (e) {
      console.log(`JS: INVALID - ${e.message.substring(0, 50)}`);
    }
  } else {
    const header = hasHeaderA ? 'A' : hasHeaderB ? 'B' : 'C';
    const footer = hasEndA ? 'A' : hasEndB ? 'B' : hasEndC ? 'C' : '?';
    if (header !== footer) {
      console.log(`TRUNCATED: Header=${header} Footer=${footer}`);
    } else {
      console.log(`CLEAN: ${header}`);
    }
  }
}

main().catch(console.error);
