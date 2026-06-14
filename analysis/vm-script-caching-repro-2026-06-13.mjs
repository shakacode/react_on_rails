import os from 'node:os';
import vm from 'node:vm';
import { performance } from 'node:perf_hooks';

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);

  if (sorted.length % 2 === 0) {
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  return sorted[middle];
}

function formatMicroseconds(value, width) {
  return `${value.toFixed(2).padStart(width)}us`;
}

function formatRatio(value) {
  return `${value.toFixed(2)}x`;
}

function measure(callback, samples) {
  const timings = [];
  const warmupSamples = Math.min(100, Math.max(10, Math.ceil(samples * 0.1)));

  for (let index = 0; index < warmupSamples; index += 1) {
    // Use negative warmup indexes so unique-source callbacks do not reuse measured source strings.
    callback(-index - 1);
  }

  for (let index = 0; index < samples; index += 1) {
    const startedAt = performance.now();
    callback(index);
    timings.push((performance.now() - startedAt) * 1000);
  }

  return median(timings);
}

function makeScript(statementCount) {
  const statements = Array.from(
    { length: statementCount },
    (_, index) => `total += values[${index % 32}];`,
  ).join('\n');

  return `(() => {
let total = 0;
${statements}
globalThis.sink = total;
})()`;
}

const cases = [
  // Intentionally not makeScript(): tests a minimal two-operand IIFE, not the loop-accumulator pattern.
  { name: 'tiny', samples: 5000, source: '(() => { globalThis.sink = values[0] + values[1]; })()' },
  { name: 'small', samples: 3000, source: makeScript(16) },
  { name: 'medium', samples: 1000, source: makeScript(400) },
  { name: 'large', samples: 300, source: makeScript(3500) },
  { name: 'huge', samples: 80, source: makeScript(32000) },
];

const context = vm.createContext({
  values: Array.from({ length: 32 }, (_, index) => index + 1),
});
// Sink for compile measurements so new vm.Script() results remain reachable during each sample.
const measurementSink = {};

console.log('vm.Script caching reproduction');
console.log('==============================');
console.log(`Node: ${process.version}`);
console.log(`Platform: ${process.platform} ${process.arch}`);
console.log(`CPU: ${os.cpus()[0]?.model ?? 'unknown'}`);
console.log();
console.log(
  '| Size   | Code Len | Samples | Same-source Compile | Unique-source Compile | Cached Exec | Same-source Run | Unique-source Run | Same/Precompiled | Unique/Precompiled |',
);
console.log(
  '| ------ | -------- | ------- | ------------------- | --------------------- | ----------- | --------------- | ----------------- | ---------------- | ------------------ |',
);

for (const benchmarkCase of cases) {
  const { name, samples, source } = benchmarkCase;
  const compiled = new vm.Script(source);

  const cachedMedian = measure(() => {
    compiled.runInContext(context);
  }, samples);
  // Intentionally after cachedMedian: this shared context has already warmed this script body.
  const sameSourceRunMedian = measure(() => {
    vm.runInContext(source, context);
  }, samples);
  const uniqueSourceRunMedian = measure((index) => {
    vm.runInContext(`${source}\n// unique run ${index}`, context);
  }, samples);
  // Intentionally after sameSourceRunMedian so this measures a same-source compilation-cache hit.
  const sameSourceCompileMedian = measure(() => {
    measurementSink.script = new vm.Script(source);
  }, samples);
  const uniqueSourceCompileMedian = measure((index) => {
    measurementSink.script = new vm.Script(`${source}\n// unique compile ${index}`);
  }, samples);

  // Same-source ratio is the renderer-relevant stable-source comparison; unique-source ratio is colder-path contrast.
  const sameSourceRatio = sameSourceRunMedian / cachedMedian;
  const uniqueSourceRatio = uniqueSourceRunMedian / cachedMedian;

  console.log(
    `| ${name.padEnd(6)} | ${String(source.length).padStart(8)} | ${String(samples).padStart(
      7,
    )} | ${formatMicroseconds(sameSourceCompileMedian, 17)} | ${formatMicroseconds(
      uniqueSourceCompileMedian,
      19,
    )} | ${formatMicroseconds(cachedMedian, 9)} | ${formatMicroseconds(
      sameSourceRunMedian,
      13,
    )} | ${formatMicroseconds(uniqueSourceRunMedian, 15)} | ${formatRatio(sameSourceRatio).padStart(
      16,
    )} | ${formatRatio(uniqueSourceRatio).padStart(18)} |`,
  );
}

console.log();
console.log('Note: Same-source compile uses V8/Node compilation-cache behavior by default.');
console.log('Same-source run also benefits from that cache after warmup.');
console.log('Cached exec runs before same-source run, so the shared-context JIT is already warmer.');
console.log('Unique-source compile/run varies the source text each sample to show a colder path.');
console.log('Same/Precompiled compares stable source text; Unique/Precompiled is colder-path contrast.');
console.log('Run with `node --no-compilation-cache` to compare with V8 compilation caching disabled.');
