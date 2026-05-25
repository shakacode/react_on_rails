# frozen_string_literal: true

module RendererHarness
  module Metrics
    module_function

    MIN_RPS_ELAPSED_SECONDS = 0.001

    def percentile(samples, pct)
      return nil if samples.empty?

      sorted = samples.sort
      rank = (pct / 100.0) * (sorted.length - 1)
      lower = rank.floor
      upper = rank.ceil
      return sorted[lower] if lower == upper

      sorted[lower] + ((sorted[upper] - sorted[lower]) * (rank - lower))
    end

    def rps(count:, elapsed_seconds:)
      return 0.0 if count.zero?

      count.to_f / [elapsed_seconds.to_f, MIN_RPS_ELAPSED_SECONDS].max
    end

    # series: Array of [time_seconds, rss_kb] pairs
    # Returns slope in MB/min using simple least-squares regression.
    def slope_mb_per_min(series)
      return 0.0 if series.length < 2

      n = series.length
      sx = series.sum { |x, _| x }
      sy = series.sum { |_, y| y }
      sxx = series.sum { |x, _| x * x }
      sxy = series.sum { |x, y| x * y }
      denom = (n * sxx) - (sx * sx)
      return 0.0 if denom.zero?

      slope_kb_per_sec = ((n * sxy) - (sx * sy)) / denom
      (slope_kb_per_sec / 1024.0) * 60.0
    end

    def summarize_latencies(results)
      ok = results.select(&:ok)
      latencies = ok.map(&:latency_ms)
      {
        count: results.length,
        ok_count: ok.length,
        failures: results.length - ok.length,
        mean: latencies.empty? ? 0.0 : latencies.sum / latencies.length,
        p50: percentile(latencies, 50),
        p90: percentile(latencies, 90),
        p95: percentile(latencies, 95),
        p99: percentile(latencies, 99),
        p99_9: percentile(latencies, 99.9),
        max: latencies.max || 0.0
      }
    end
  end
end
