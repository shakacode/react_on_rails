import assert from 'node:assert/strict';
import test from 'node:test';
import { classify, summarize } from './stats.mjs';

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
