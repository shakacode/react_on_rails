/**
 * Console table and JSON output for benchmark results.
 */

function fmtMs(ns) {
  return (Number(ns) / 1e6).toFixed(2) + ' ms';
}

function fmtBytes(bytes) {
  if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return bytes.toLocaleString() + ' B';
}

function pad(str, len, align = 'right') {
  const s = String(str);
  if (align === 'right') return s.padStart(len);
  return s.padEnd(len);
}

/**
 * Print a comparison table between renderToString and RSC+streaming results.
 *
 * @param {object} stringResults - Results from bench-string-ssr
 * @param {object} rscResults - Results from bench-rsc-ssr (optional)
 */
export function printComparisonTable(stringResults, rscResults) {
  const colW = 14;
  const labelW = 24;
  const border = (l, m, r, fill = '\u2500') =>
    l + fill.repeat(labelW + 2) + m + fill.repeat(colW + 2) + m + fill.repeat(colW + 2) + r;

  const row = (label, col1, col2) =>
    '\u2502 ' + pad(label, labelW, 'left') + ' \u2502 ' + pad(col1, colW) + ' \u2502 ' + pad(col2, colW) + ' \u2502';

  console.log();
  console.log(border('\u250C', '\u252C', '\u2510'));
  console.log(row('Metric', 'renderToStr', 'RSC+Stream'));
  console.log(border('\u251C', '\u253C', '\u2524'));

  // Render times
  console.log(row('Total render (mean)', fmtMs(stringResults.renderTime.mean), rscResults ? fmtMs(rscResults.totalTime.mean) : 'N/A'));
  console.log(row('Total render (p50)', fmtMs(stringResults.renderTime.p50), rscResults ? fmtMs(rscResults.totalTime.p50) : 'N/A'));
  console.log(row('Total render (p95)', fmtMs(stringResults.renderTime.p95), rscResults ? fmtMs(rscResults.totalTime.p95) : 'N/A'));
  console.log(row('Total render (p99)', fmtMs(stringResults.renderTime.p99), rscResults ? fmtMs(rscResults.totalTime.p99) : 'N/A'));

  // TTFB
  console.log(row('TTFB (mean)', 'N/A', rscResults ? fmtMs(rscResults.ttfb.mean) : 'N/A'));
  console.log(row('TTFB (p50)', 'N/A', rscResults ? fmtMs(rscResults.ttfb.p50) : 'N/A'));

  // RSC phases
  console.log(row('RSC gen (mean)', 'N/A', rscResults ? fmtMs(rscResults.rscGenTime.mean) : 'N/A'));
  console.log(row('RSC consume (mean)', 'N/A', rscResults ? fmtMs(rscResults.rscConsumeTime.mean) : 'N/A'));
  console.log(row('SSR render (mean)', fmtMs(stringResults.renderTime.mean), rscResults ? fmtMs(rscResults.ssrTime.mean) : 'N/A'));

  console.log(border('\u251C', '\u253C', '\u2524'));

  // Size
  console.log(row('HTML size', fmtBytes(stringResults.htmlSize), rscResults ? fmtBytes(rscResults.htmlSize) : 'N/A'));

  // Memory
  console.log(row('Peak heap (mean)', fmtBytes(stringResults.peakHeap.mean), rscResults ? fmtBytes(rscResults.peakHeap.mean) : 'N/A'));
  console.log(row('Peak RSS (mean)', fmtBytes(stringResults.peakRss.mean), rscResults ? fmtBytes(rscResults.peakRss.mean) : 'N/A'));

  console.log(border('\u2514', '\u2534', '\u2518'));
  console.log();
}

/**
 * Print a single benchmark result table.
 */
export function printSingleTable(label, results) {
  const colW = 14;
  const labelW = 24;
  const border = (l, m, r, fill = '\u2500') =>
    l + fill.repeat(labelW + 2) + m + fill.repeat(colW + 2) + r;

  const row = (metric, value) =>
    '\u2502 ' + pad(metric, labelW, 'left') + ' \u2502 ' + pad(value, colW) + ' \u2502';

  console.log();
  console.log(`  ${label}`);
  console.log(border('\u250C', '\u252C', '\u2510'));
  console.log(row('Metric', 'Value'));
  console.log(border('\u251C', '\u253C', '\u2524'));

  const isMemoryKey = (k) => /heap|rss|memory/i.test(k);

  for (const [key, val] of Object.entries(results)) {
    if (val && typeof val === 'object' && 'mean' in val) {
      const fmt = isMemoryKey(key) ? fmtBytes : fmtMs;
      console.log(row(`${key} (mean)`, fmt(val.mean)));
      console.log(row(`${key} (p50)`, fmt(val.p50)));
      console.log(row(`${key} (p95)`, fmt(val.p95)));
    } else if (key.toLowerCase().includes('size')) {
      console.log(row(key, fmtBytes(val)));
    } else {
      console.log(row(key, String(val)));
    }
  }

  console.log(border('\u2514', '\u2534', '\u2518'));
  console.log();
}

/**
 * Write JSON results to stdout for programmatic consumption.
 */
export function outputJson(results) {
  console.log(JSON.stringify(results, null, 2));
}
