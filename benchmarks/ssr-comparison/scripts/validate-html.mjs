/**
 * Validation script: Renders via both SSR paths and compares the HTML output.
 * Checks:
 * 1. Both produce valid, non-empty HTML
 * 2. Expected elements are present (products, reviews, comments, etc.)
 * 3. Element counts match expectations
 * 4. Both produce similar HTML structures
 */

import { createRequire } from 'module';
import { Worker } from 'worker_threads';
import { PassThrough } from 'stream';
import ReactDOMServer from 'react-dom/server';
import React from 'react';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const { renderToString } = ReactDOMServer;
const { renderToPipeableStream: renderToHtmlStream } = ReactDOMServer;
const { createElement } = React;
const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Load traditional bundle
const { default: App } = require('../dist/traditional/server-bundle.cjs');

// Load server bundle (sets up __webpack_require__)
require('../dist/rsc/server-bundle.cjs');

// Load manifests
function loadManifest(filePath) {
  if (fs.existsSync(filePath)) return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  return { filePathToModuleMetadata: {}, moduleLoading: { prefix: '', crossOrigin: null } };
}
const clientManifest = loadManifest(path.resolve(__dirname, '../dist/rsc/react-client-manifest.json'));
const serverManifest = loadManifest(path.resolve(__dirname, '../dist/rsc/react-server-client-manifest.json'));

let passed = 0;
let failed = 0;

function check(label, condition, detail = '') {
  if (condition) {
    console.log(`  PASS: ${label}`);
    passed++;
  } else {
    console.log(`  FAIL: ${label}${detail ? ' — ' + detail : ''}`);
    failed++;
  }
}

function countOccurrences(html, pattern) {
  const matches = html.match(new RegExp(pattern, 'g'));
  return matches ? matches.length : 0;
}

// ── Path A: renderToString ──────────────────────────────────────────
console.log('\n=== Path A: renderToString (traditional) ===\n');

const htmlString = renderToString(createElement(App));
const strSize = Buffer.byteLength(htmlString, 'utf8');

check('HTML is non-empty', htmlString.length > 0, `got ${htmlString.length} chars`);
check('HTML size > 80KB', strSize > 80000, `got ${strSize} bytes`);
check('Contains <div class="app-root">', htmlString.includes('class="app-root"'));
check('Contains navigation', htmlString.includes('class="navigation-bar"'));
check('Contains hero section', htmlString.includes('class="hero-section"'));
check('Contains breadcrumb', htmlString.includes('class="breadcrumb"'));
check('Contains sidebar', htmlString.includes('class="sidebar"'));
check('Contains product grid', htmlString.includes('class="product-grid"'));
check('Contains data table', htmlString.includes('class="data-table"'));
check('Contains reviews section', htmlString.includes('class="reviews-section"'));
check('Contains comment section', htmlString.includes('class="comment-section"'));
check('Contains accordion section', htmlString.includes('class="accordion-section"'));
check('Contains tab panel', htmlString.includes('class="tab-panel"'));
check('Contains pagination', htmlString.includes('class="pagination-bar"'));
check('Contains footer', htmlString.includes('class="site-footer"'));

// Count key elements
const productCards = countOccurrences(htmlString, 'class="product-card"');
check('24 product cards', productCards === 24, `got ${productCards}`);

const reviewItems = countOccurrences(htmlString, 'class="review-item"');
check('15 review items', reviewItems === 15, `got ${reviewItems}`);

const commentThreads = countOccurrences(htmlString, 'class="comment-thread"');
check('Comment threads > 30', commentThreads > 30, `got ${commentThreads}`);

const dataRows = countOccurrences(htmlString, 'class="row-even"|class="row-odd"');
check('20 data rows', dataRows === 20, `got ${dataRows}`);

const accordionItems = countOccurrences(htmlString, 'class="accordion-item');
check('8 accordion items', accordionItems === 8, `got ${accordionItems}`);

const filterCheckboxes = countOccurrences(htmlString, 'class="filter-checkbox"');
check('Filter checkboxes present', filterCheckboxes > 10, `got ${filterCheckboxes}`);

// Check interactive elements are SSR'd (useState components render initial state)
check('Add to Cart buttons present', htmlString.includes('Add to Cart'));
check('Star ratings present', countOccurrences(htmlString, 'class="star ') > 50, `got ${countOccurrences(htmlString, 'class="star ')}`);
check('Vote buttons present', htmlString.includes('btn-helpful'));
check('Search input present', htmlString.includes('class="search-input"'));

// Save for comparison
fs.writeFileSync(path.resolve(__dirname, '../dist/html-string.html'), htmlString);

// ── Path B: RSC + Streaming SSR ─────────────────────────────────────
console.log('\n=== Path B: RSC + Streaming SSR ===\n');

async function renderRSCPath() {
  // Generate RSC payload via worker
  const worker = await new Promise((resolve, reject) => {
    const w = new Worker(path.resolve(__dirname, 'lib/rsc-worker.mjs'), {
      execArgv: ['--conditions=react-server'],
      env: { ...process.env, NODE_ENV: 'production' },
    });
    w.on('message', (msg) => {
      if (msg.type === 'ready') resolve(w);
      else if (msg.type === 'error') reject(new Error(msg.error));
    });
    w.on('error', reject);
  });

  const payload = await new Promise((resolve, reject) => {
    const handler = (msg) => {
      if (msg.type === 'payload') {
        worker.off('message', handler);
        resolve(Buffer.from(msg.payload));
      } else if (msg.type === 'error') {
        worker.off('message', handler);
        reject(new Error(msg.error));
      }
    };
    worker.on('message', handler);
    worker.postMessage({ type: 'generate', id: 'validate' });
  });

  check('RSC payload is non-empty', payload.length > 0, `got ${payload.length} bytes`);
  check('RSC payload size > 50KB', payload.length > 50000, `got ${payload.length} bytes`);

  // Consume RSC payload
  const { buildClientRenderer } = await import('react-on-rails-rsc/client.node');
  const { createFromNodeStream } = buildClientRenderer(clientManifest, serverManifest);

  const payloadStream = new PassThrough();
  payloadStream.end(payload);
  const element = await createFromNodeStream(payloadStream);

  check('createFromNodeStream returned element', element != null);

  // SSR render
  const htmlRsc = await new Promise((resolve, reject) => {
    const { pipe } = renderToHtmlStream(element, {
      onAllReady() {
        const pt = new PassThrough();
        pipe(pt);
        const chunks = [];
        pt.on('data', (c) => chunks.push(c));
        pt.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
        pt.on('error', reject);
      },
      onError: reject,
    });
  });

  worker.postMessage({ type: 'exit' });
  return htmlRsc;
}

const htmlRsc = await renderRSCPath();
const rscSize = Buffer.byteLength(htmlRsc, 'utf8');

check('RSC HTML is non-empty', htmlRsc.length > 0, `got ${htmlRsc.length} chars`);
check('RSC HTML size > 80KB', rscSize > 80000, `got ${rscSize} bytes`);
check('Contains <div class="app-root">', htmlRsc.includes('class="app-root"'));
check('Contains navigation', htmlRsc.includes('class="navigation-bar"'));
check('Contains hero section', htmlRsc.includes('class="hero-section"'));
check('Contains breadcrumb', htmlRsc.includes('class="breadcrumb"'));
check('Contains sidebar', htmlRsc.includes('class="sidebar"'));
check('Contains product grid', htmlRsc.includes('class="product-grid"'));
check('Contains data table', htmlRsc.includes('class="data-table"'));
check('Contains reviews section', htmlRsc.includes('class="reviews-section"'));
check('Contains comment section', htmlRsc.includes('class="comment-section"'));
check('Contains accordion section', htmlRsc.includes('class="accordion-section"'));
check('Contains tab panel', htmlRsc.includes('class="tab-panel"'));
check('Contains pagination', htmlRsc.includes('class="pagination-bar"'));
check('Contains footer', htmlRsc.includes('class="site-footer"'));

// Count elements
const rscProductCards = countOccurrences(htmlRsc, 'class="product-card"');
check('24 product cards', rscProductCards === 24, `got ${rscProductCards}`);

const rscReviewItems = countOccurrences(htmlRsc, 'class="review-item"');
check('15 review items', rscReviewItems === 15, `got ${rscReviewItems}`);

const rscCommentThreads = countOccurrences(htmlRsc, 'class="comment-thread"');
check('Comment threads > 30', rscCommentThreads > 30, `got ${rscCommentThreads}`);

const rscDataRows = countOccurrences(htmlRsc, 'class="row-even"|class="row-odd"');
check('20 data rows', rscDataRows === 20, `got ${rscDataRows}`);

const rscAccordionItems = countOccurrences(htmlRsc, 'class="accordion-item');
check('8 accordion items', rscAccordionItems === 8, `got ${rscAccordionItems}`);

// Check client component SSR
check('Add to Cart buttons present', htmlRsc.includes('Add to Cart'));
check('Star ratings present', countOccurrences(htmlRsc, 'class="star ') > 50, `got ${countOccurrences(htmlRsc, 'class="star ')}`);
check('Vote buttons present', htmlRsc.includes('btn-helpful'));
check('Search input present', htmlRsc.includes('class="search-input"'));

fs.writeFileSync(path.resolve(__dirname, '../dist/html-rsc.html'), htmlRsc);

// ── Comparison ──────────────────────────────────────────────────────
console.log('\n=== Comparison ===\n');

check('Both produce similar sizes', Math.abs(strSize - rscSize) / strSize < 0.15,
  `string=${strSize}B, rsc=${rscSize}B, diff=${Math.abs(strSize - rscSize)}B (${(Math.abs(strSize - rscSize) / strSize * 100).toFixed(1)}%)`);
check('Same product card count', productCards === rscProductCards);
check('Same review item count', reviewItems === rscReviewItems);
check('Similar comment thread count', Math.abs(commentThreads - rscCommentThreads) <= 2,
  `string=${commentThreads}, rsc=${rscCommentThreads}`);
check('Same data row count', dataRows === rscDataRows);
check('Same accordion count', accordionItems === rscAccordionItems);

// ── Summary ─────────────────────────────────────────────────────────
console.log(`\n${'='.repeat(50)}`);
console.log(`  Results: ${passed} passed, ${failed} failed`);
console.log(`  String HTML: ${strSize.toLocaleString()} bytes`);
console.log(`  RSC HTML:    ${rscSize.toLocaleString()} bytes`);
console.log(`  HTML files saved to dist/html-string.html and dist/html-rsc.html`);
console.log(`${'='.repeat(50)}\n`);

if (failed > 0) process.exit(1);
