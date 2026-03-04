/**
 * Script 3: Full RSC -> streaming SSR pipeline benchmark
 *
 * Phase A: Generate RSC payload (in worker thread with react-server condition)
 * Phase B: Consume RSC payload -> React element (createFromNodeStream)
 * Phase C: SSR render to HTML stream (renderToPipeableStream from react-dom/server)
 *
 * Measures: RSC gen time, RSC consume time, SSR time, TTFB, total time, HTML size, memory.
 */

import { Worker } from 'worker_threads';
import { createRequire } from 'module';
import { PassThrough } from 'stream';
import ReactDOMServer from 'react-dom/server';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { summarize } from './lib/stats.mjs';
import { printSingleTable, outputJson } from './lib/reporter.mjs';

const require = createRequire(import.meta.url);
const { renderToPipeableStream: renderToHtmlStream } = ReactDOMServer;
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Load the server bundle to set up globalThis.__webpack_require__
// This is needed for client reference resolution during SSR
require('../dist/rsc/server-bundle.cjs');

// Load manifests for client renderer
const clientManifestPath = path.resolve(__dirname, '../dist/rsc/react-client-manifest.json');
const serverManifestPath = path.resolve(__dirname, '../dist/rsc/react-server-client-manifest.json');

function loadManifest(filePath) {
  if (fs.existsSync(filePath)) {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  }
  return { filePathToModuleMetadata: {}, moduleLoading: { prefix: '', crossOrigin: null } };
}

const clientManifest = loadManifest(clientManifestPath);
const serverManifest = loadManifest(serverManifestPath);

const WARMUP = 10;
const ITERATIONS = parseInt(process.env.ITERATIONS || '100', 10);
const JSON_OUTPUT = process.argv.includes('--json');

/**
 * Create a worker that runs with --conditions=react-server for RSC payload generation.
 */
function createRSCWorker() {
  return new Promise((resolve, reject) => {
    const worker = new Worker(
      path.resolve(__dirname, 'lib/rsc-worker.mjs'),
      { execArgv: ['--conditions=react-server'], env: { ...process.env, NODE_ENV: 'production' } }
    );
    worker.on('message', (msg) => {
      if (msg.type === 'ready') resolve(worker);
      else if (msg.type === 'error') reject(new Error(msg.error));
    });
    worker.on('error', reject);
  });
}

/**
 * Request RSC payload from worker.
 */
function generateRSCPayload(worker, id) {
  return new Promise((resolve, reject) => {
    const handler = (msg) => {
      if (msg.id !== id) return;
      worker.off('message', handler);
      if (msg.type === 'payload') {
        resolve({ payload: Buffer.from(msg.payload), timeNs: msg.timeNs });
      } else if (msg.type === 'error') {
        reject(new Error(msg.error));
      }
    };
    worker.on('message', handler);
    worker.postMessage({ type: 'generate', id });
  });
}

async function run() {
  // Build client renderer (one-time cost, excluded from benchmark)
  const { buildClientRenderer } = await import('react-on-rails-rsc/client.node');
  const { createFromNodeStream } = buildClientRenderer(clientManifest, serverManifest);

  // Start RSC worker
  const worker = await createRSCWorker();

  console.log(`RSC + Streaming SSR benchmark: ${WARMUP} warmup + ${ITERATIONS} iterations\n`);

  // Warmup
  for (let i = 0; i < WARMUP; i++) {
    const { payload } = await generateRSCPayload(worker, `warmup-${i}`);
    const payloadStream = new PassThrough();
    payloadStream.end(payload);
    const element = await createFromNodeStream(payloadStream);
    await new Promise((resolve, reject) => {
      const { pipe } = renderToHtmlStream(element, {
        onShellReady() {
          const pt = new PassThrough();
          pipe(pt);
          const chunks = [];
          pt.on('data', (c) => chunks.push(c));
          pt.on('end', resolve);
          pt.on('error', reject);
        },
        onError: reject,
      });
    });
  }

  if (global.gc) global.gc();

  const rscGenTimes = [];
  const rscConsumeTimes = [];
  const ssrTimes = [];
  const ttfbs = [];
  const totalTimes = [];
  const heapValues = [];
  const rssValues = [];
  let htmlSize = 0;

  for (let i = 0; i < ITERATIONS; i++) {
    const memBefore = process.memoryUsage();
    const totalStart = process.hrtime.bigint();

    // Phase A: Generate RSC payload (in worker)
    const { payload: rscPayload, timeNs: rscGenTime } = await generateRSCPayload(worker, `iter-${i}`);

    // Phase B: Consume RSC payload -> React element
    const rscConsumeStart = process.hrtime.bigint();
    const payloadStream = new PassThrough();
    payloadStream.end(rscPayload);
    const element = await createFromNodeStream(payloadStream);
    const rscConsumeEnd = process.hrtime.bigint();

    // Phase C: SSR render
    const ssrStart = process.hrtime.bigint();
    const ssrResult = await new Promise((resolve, reject) => {
      let shellReadyTime = null;
      const { pipe } = renderToHtmlStream(element, {
        onShellReady() {
          shellReadyTime = Number(process.hrtime.bigint() - ssrStart);
          const pt = new PassThrough();
          pipe(pt);
          const chunks = [];
          pt.on('data', (c) => chunks.push(c));
          pt.on('end', () => resolve({ html: Buffer.concat(chunks), shellReadyTime }));
          pt.on('error', reject);
        },
        onError: reject,
      });
    });
    const ssrEnd = process.hrtime.bigint();

    const totalEnd = process.hrtime.bigint();
    const memAfter = process.memoryUsage();

    rscGenTimes.push(rscGenTime);
    rscConsumeTimes.push(Number(rscConsumeEnd - rscConsumeStart));
    ssrTimes.push(Number(ssrEnd - ssrStart));
    ttfbs.push(ssrResult.shellReadyTime);
    totalTimes.push(Number(totalEnd - totalStart));
    heapValues.push(Math.max(memAfter.heapUsed, memBefore.heapUsed));
    rssValues.push(Math.max(memAfter.rss, memBefore.rss));

    if (i === 0) {
      htmlSize = ssrResult.html.length;
    }
  }

  // Shut down worker
  worker.postMessage({ type: 'exit' });

  const results = {
    rscGenTime: summarize(rscGenTimes),
    rscConsumeTime: summarize(rscConsumeTimes),
    ssrTime: summarize(ssrTimes),
    ttfb: summarize(ttfbs),
    totalTime: summarize(totalTimes),
    htmlSize,
    peakHeap: summarize(heapValues),
    peakRss: summarize(rssValues),
    iterations: ITERATIONS,
  };

  if (JSON_OUTPUT) {
    outputJson(results);
  } else {
    printSingleTable('RSC + Streaming SSR Results', results);
  }

  return results;
}

run().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
