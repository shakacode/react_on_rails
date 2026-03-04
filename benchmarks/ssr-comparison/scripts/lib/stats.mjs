/**
 * Statistical helper functions for benchmark analysis.
 */

export function mean(values) {
  if (values.length === 0) return 0;
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

export function stddev(values) {
  if (values.length < 2) return 0;
  const m = mean(values);
  const variance = values.reduce((sum, v) => sum + (v - m) ** 2, 0) / (values.length - 1);
  return Math.sqrt(variance);
}

export function percentile(values, p) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = (p / 100) * (sorted.length - 1);
  const lower = Math.floor(index);
  const upper = Math.ceil(index);
  if (lower === upper) return sorted[lower];
  return sorted[lower] + (sorted[upper] - sorted[lower]) * (index - lower);
}

export function p50(values) {
  return percentile(values, 50);
}

export function p95(values) {
  return percentile(values, 95);
}

export function p99(values) {
  return percentile(values, 99);
}

export function summarize(values) {
  return {
    mean: mean(values),
    stddev: stddev(values),
    min: Math.min(...values),
    max: Math.max(...values),
    p50: p50(values),
    p95: p95(values),
    p99: p99(values),
    count: values.length,
  };
}
