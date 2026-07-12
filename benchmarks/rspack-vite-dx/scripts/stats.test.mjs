import assert from 'node:assert/strict';
import test from 'node:test';
import { buildSummary, classify, summarize, verifySummary } from './stats.mjs';

test('summarize reports median and observed spread', () => {
  assert.deepEqual(summarize([30, 10, 40, 20, 50]), {
    samples: 5,
    median_ms: 30,
    min_ms: 10,
    max_ms: 50,
    spread_ms: 40,
    spread_percent_of_median: 133.3,
  });
});

test('classification calls overlapping observed noise a wash', () => {
  assert.equal(classify({ median_ms: 100, spread_ms: 20 }, { median_ms: 110, spread_ms: 15 }), 'wash');
});

test('classification reports the right-hand control direction beyond noise', () => {
  assert.equal(classify({ median_ms: 100, spread_ms: 5 }, { median_ms: 120, spread_ms: 5 }), 'regression');
  assert.equal(classify({ median_ms: 100, spread_ms: 5 }, { median_ms: 80, spread_ms: 5 }), 'improvement');
});

test('classification is ambiguous when either sample spread exceeds half its median', () => {
  assert.equal(
    classify(
      { median_ms: 100, spread_ms: 5, spread_percent_of_median: 5 },
      { median_ms: 80, spread_ms: 60, spread_percent_of_median: 75 },
    ),
    'ambiguous',
  );
});

test('verifySummary rejects a mutated recorded median or verdict', () => {
  const rawSamples = {
    cold_start: { rspack: [10, 11, 12, 13, 14], vite: [20, 21, 22, 23, 24] },
    hmr: { rspack: [30, 31, 32, 33, 34], vite: [40, 41, 42, 43, 44] },
  };
  const result = { raw_samples_ms: rawSamples, summary: buildSummary(rawSamples) };

  result.summary.cold_start.rspack.median_ms = 999;
  assert.throws(() => verifySummary(result), /does not match raw samples/);

  result.summary = buildSummary(rawSamples);
  result.summary.hmr.vite_relative_to_rspack = 'wash';
  assert.throws(() => verifySummary(result), /does not match raw samples/);
});
