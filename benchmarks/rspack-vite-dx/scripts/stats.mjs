export function summarize(samples) {
  if (samples.length === 0) throw new Error('cannot summarize an empty sample set');

  const sorted = [...samples].sort((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);
  const median = sorted.length % 2 === 0 ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle];
  const min = sorted[0];
  const max = sorted.at(-1);

  return {
    samples: sorted.length,
    median_ms: round(median),
    min_ms: round(min),
    max_ms: round(max),
    spread_ms: round(max - min),
    spread_percent_of_median: round(((max - min) / median) * 100),
  };
}

export function classify(left, right) {
  if (left.spread_percent_of_median > 50 || right.spread_percent_of_median > 50) {
    return 'ambiguous';
  }

  const medianDelta = right.median_ms - left.median_ms;
  const observedNoise = Math.max(left.spread_ms, right.spread_ms);

  if (Math.abs(medianDelta) <= observedNoise) return 'wash';
  return medianDelta > 0 ? 'regression' : 'improvement';
}

function round(value) {
  return Math.round(value * 10) / 10;
}
