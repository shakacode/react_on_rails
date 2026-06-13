import os from 'node:os';
import vm from 'node:vm';
import { performance } from 'node:perf_hooks';

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
}

function measure(callback, samples) {
  const values = [];

  for (let index = 0; index < 100; index += 1) {
    callback(-index - 1);
  }

  for (let index = 0; index < samples; index += 1) {
    const startedAt = performance.now();
    callback(index);
    values.push((performance.now() - startedAt) * 1000);
  }

  return median(values);
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
  { name: 'tiny', samples: 5000, source: '(() => { globalThis.sink = values[0] + values[1]; })()' },
  { name: 'small', samples: 3000, source: makeScript(16) },
  { name: 'medium', samples: 1000, source: makeScript(400) },
  { name: 'large', samples: 300, source: makeScript(3500) },
  { name: 'huge', samples: 80, source: makeScript(32000) },
];

const context = vm.createContext({
  values: Array.from({ length: 32 }, (_, index) => index + 1),
});

console.log('vm.Script caching reproduction');
console.log('==============================');
console.log(`Node: ${process.version}`);
console.log(`Platform: ${process.platform} ${process.arch}`);
console.log(`CPU: ${os.cpus()[0]?.model ?? 'unknown'}`);
console.log();
console.log(
  '| Size | Code Len | Samples | Same-source Compile | Unique-source Compile | Cached Med | Uncached Med | Speedup |',
);
console.log(
  '| ---- | -------- | ------- | ------------------- | --------------------- | ---------- | ------------ | ------- |',
);

for (const benchmarkCase of cases) {
  const { name, samples, source } = benchmarkCase;
  const compiled = new vm.Script(source);

  const sameSourceCompileMedian = measure(() => {
    return new vm.Script(source);
  }, samples);
  const uniqueSourceCompileMedian = measure((index) => {
    return new vm.Script(`${source}\n// unique compile ${index}`);
  }, samples);
  const cachedMedian = measure(() => {
    compiled.runInContext(context);
  }, samples);
  const uncachedMedian = measure(() => {
    vm.runInContext(source, context);
  }, samples);

  console.log(
    `| ${name.padEnd(6)} | ${String(source.length).padStart(8)} | ${String(samples).padStart(
      7,
    )} | ${sameSourceCompileMedian.toFixed(2).padStart(17)}us | ${uniqueSourceCompileMedian
      .toFixed(2)
      .padStart(19)}us | ${cachedMedian
      .toFixed(2)
      .padStart(8)}us | ${uncachedMedian.toFixed(2).padStart(10)}us | ${(
      uncachedMedian / cachedMedian
    ).toFixed(2)}x |`,
  );
}

console.log();
console.log('Note: Same-source compile uses V8/Node compilation-cache behavior by default.');
console.log('Unique-source compile varies the source text each sample to show a colder path.');
console.log('Run with `node --no-compilation-cache` to compare with V8 compilation caching disabled.');
