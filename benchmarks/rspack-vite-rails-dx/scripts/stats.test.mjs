import assert from 'node:assert/strict';
import test from 'node:test';
import { buildSummary, classify, summarize } from './stats.mjs';

test('summarize reports median and spread', () => {
  assert.deepEqual(summarize([12, 8, 10, 11, 9]), {
    samples: 5,
    median_ms: 10,
    min_ms: 8,
    max_ms: 12,
    spread_ms: 4,
    spread_percent_of_median: 40,
  });
});

test('classification fails closed on noisy samples', () => {
  assert.equal(classify(summarize([10, 10, 10]), summarize([5, 5, 10])), 'ambiguous');
});

test('summary classifies changes outside the observed noise band', () => {
  const summary = buildSummary({
    cold_start: { rspack: [100, 101, 102], vite: [70, 71, 72] },
    fast_refresh: { rspack: [10, 11, 12], vite: [10, 11, 12] },
  });
  assert.equal(summary.cold_start.vite_relative_to_rspack, 'improvement');
  assert.equal(summary.fast_refresh.vite_relative_to_rspack, 'wash');
});
