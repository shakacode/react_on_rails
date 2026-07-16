# frozen_string_literal: true

require "json"

require_relative "bencher_perf_url"

# Parses the report emitted by `bencher run --format json` (Bencher CLI v0.6.8;
# shape verified stable through current main). Exposes what benchmark reporting
# needs: active regression alerts, and per benchmark+measure t-test prediction
# intervals so the summary table can flag values that moved significantly vs
# baseline in EITHER direction.
#
# The report shape is not a documented stability contract, so accesses are guarded:
# anything that decides a regression or the table structure raises FormatError (fail
# loud rather than mis-report), while purely informational alert fields are read
# leniently (see #parse_alerts). The job fails loudly rather than silently rendering
# garbage or missing a regression.
class BencherReport # rubocop:disable Metrics/ClassLength
  class FormatError < StandardError; end

  # One benchmark+measure's value and its prediction interval. baseline/limits are
  # nil when Bencher has no boundary yet (new benchmark / insufficient history) or
  # for the unconfigured side of a one-sided threshold.
  Boundary = Struct.new(:value, :baseline, :lower_limit, :upper_limit, keyword_init: true) do
    # Classify `value` vs the interval given the measure's regression direction.
    #   :lower => higher-is-better (rps): regression = value drops below interval
    #   :upper => lower-is-better (latency/failed_pct): regression = value climbs above
    # Returns :regression, :improvement, or nil. Bencher configures one side only,
    # so the missing limit is the mirror about baseline (symmetric t-test interval).
    def significance(direction)
      return nil if value.nil? || baseline.nil?

      # For higher-is-better (:lower) a drop below the interval is a regression and
      # a climb above it an improvement; lower-is-better (:upper) is the mirror.
      if direction == :lower
        classify(below: :regression, above: :improvement)
      else
        classify(below: :improvement, above: :regression)
      end
    end

    private

    def classify(below:, above:)
      lower = effective_lower
      return below if lower && value < lower

      upper = effective_upper
      return above if upper && value > upper

      nil
    end

    # Bencher configures a threshold on one side only, so the opposite limit is the
    # mirror of the present one about baseline (the t-test interval is symmetric).
    def effective_lower
      lower_limit || mirror(upper_limit)
    end

    def effective_upper
      upper_limit || mirror(lower_limit)
    end

    # Bencher's t-test prediction interval is symmetric about the baseline by
    # construction, so the unconfigured side is the configured side mirrored across
    # baseline: a limit at distance d from baseline maps to baseline ∓ d. (Verified
    # for the pinned CLI; re-confirm when bumping the pin.)
    def mirror(limit)
      return nil if limit.nil?

      (2 * baseline) - limit
    end
  end

  Alert = Struct.new(:benchmark, :measure, :limit, keyword_init: true)

  def self.parse(json_string, tracked_measures: nil)
    new(JSON.parse(json_string), tracked_measures:)
  rescue JSON::ParserError => e
    raise FormatError, "Bencher report is not valid JSON: #{e.message}"
  end

  # tracked_measures: the measures the caller actually tracks (e.g. track_benchmarks.rb's
  # THRESHOLDS names). When given, an active alert on any *other* measure is treated as
  # filtered rather than a regression — this drops alerts from orphaned server-side Bencher
  # thresholds (e.g. a p90_latency threshold the code stopped passing but never deleted),
  # which otherwise file an issue that the summary table can't even flag. nil = track every
  # measure (backward-compatible default for callers that only need parsing/significance).
  def initialize(raw, tracked_measures: nil)
    raise FormatError, "report is not a JSON object (got #{raw.class})" unless raw.is_a?(Hash)

    @tracked_measures = tracked_measures&.map { |measure| normalize(measure) }
    @boundaries = index_boundaries(raw)
    @alerts, @filtered_alerts = parse_alerts(raw).partition { |alert| current_regression_alert?(alert) }
    # Per-benchmark perf links are informational (they only decide whether a name links
    # out), so they live in a separate, fully-lenient builder — a missing field yields an
    # unlinked name, never a FormatError that would fail the job over a cosmetic link.
    @perf_urls = BencherPerfUrl.new(raw)
  end

  attr_reader :alerts

  def regression? = !@alerts.empty?

  def filtered_alert? = !@filtered_alerts.empty?

  # Boundary for a benchmark+measure, or nil if absent from the report.
  def boundary(benchmark_name, measure_key)
    @boundaries.dig(benchmark_name, normalize(measure_key))
  end

  # :regression | :improvement | nil for benchmark+measure given its direction.
  def significance(benchmark_name, measure_key, direction)
    boundary(benchmark_name, measure_key)&.significance(direction)
  end

  # The Bencher perf-plot URL for one benchmark (all its measures), or nil when the
  # report is missing any required id (then the caller renders the name unlinked).
  def perf_url(benchmark_name)
    @perf_urls.for_benchmark(benchmark_name)
  end

  # True when the report lists benchmarks but is missing the shared perf-link context
  # (project slug / branch / testbed uuid), so EVERY benchmark name degrades to an unlinked
  # plain name. A single benchmark missing its own uuid stays silent (a per-row cosmetic
  # miss); losing the shared context instead is a likely report-contract drift, so the
  # caller surfaces it as a ::warning:: — never a FormatError (the links are cosmetic).
  def perf_links_unavailable? = @perf_urls.any_benchmarks? && !@perf_urls.context_ready?

  private

  def index_boundaries(raw)
    index = {}
    fetch_array(raw, "results").each do |iteration|
      raise FormatError, "results entry is not an array (got #{iteration.class})" unless iteration.is_a?(Array)

      iteration.each do |result|
        name = dig_string(result, "benchmark", "name")
        per_measure = index[name] ||= {}
        fetch_array(result, "measures").each { |measure_entry| index_measure(per_measure, measure_entry, name) }
      end
    end
    index
  end

  # Index one measure's boundary under both its normalized slug and name so callers can
  # match either form (Bencher slugifies the BMF key, e.g. "p50_latency" ->
  # "p50-latency"). Invariant: slug and name normalize to distinct keys across a
  # benchmark's measures. Enforce it (fail loud) rather than let a future collision
  # silently overwrite an earlier boundary and mis-report significance. A single
  # measure whose slug and name normalize together is fine — it's the same boundary.
  def index_measure(per_measure, measure_entry, benchmark_name)
    boundary = parse_boundary(measure_entry)
    slug_key = normalize(dig_string(measure_entry, "measure", "slug"))
    name_key = normalize(dig_string(measure_entry, "measure", "name"))
    [slug_key, name_key].each do |key|
      existing = per_measure[key]
      if existing && !existing.equal?(boundary)
        raise FormatError, "normalized measure key collision on #{key.inspect} for benchmark #{benchmark_name.inspect}"
      end

      per_measure[key] = boundary
    end
  end

  def parse_boundary(measure_entry)
    value = dig_number(measure_entry, "metric", "value")
    raw = measure_entry["boundary"]
    return Boundary.new(value:, baseline: nil, lower_limit: nil, upper_limit: nil) if raw.nil?
    raise FormatError, "boundary is not an object (got #{raw.class})" unless raw.is_a?(Hash)

    Boundary.new(value:, baseline: optional_number(raw, "baseline"),
                 lower_limit: optional_number(raw, "lower_limit"), upper_limit: optional_number(raw, "upper_limit"))
  end

  # Informational alert fields (benchmark/measure/limit) are read leniently so a
  # schema quirk there can't crash regression detection; only the entry shape and
  # `status` (which decides "active") are strict. Strict means a missing or
  # non-String `status` on ANY alert — active, dismissed, or silenced — raises
  # FormatError and fails the job. This is deliberate: status drives regression
  # detection, so we fail loud rather than risk silently skipping an alert we could
  # not classify. A future upgrader who hits this should check dismissed/silenced
  # entries too, not just active ones.
  def parse_alerts(raw)
    fetch_array(raw, "alerts").filter_map do |entry|
      raise FormatError, "alert is not an object (got #{entry.class})" unless entry.is_a?(Hash)
      next unless dig_string(entry, "status") == "active"

      Alert.new(
        benchmark: dig_optional_string(entry, "benchmark", "name"),
        measure: dig_optional_string(entry, "threshold", "measure", "slug"),
        limit: dig_optional_string(entry, "limit")
      )
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def current_regression_alert?(alert)
    return true unless alert.benchmark
    return false if untracked_measure_alert?(alert)

    direction = { "lower" => :lower, "upper" => :upper }[normalize(alert.limit)]
    return true unless direction

    unless alert.measure
      matching_boundaries = @boundaries.fetch(alert.benchmark, {}).values.select do |boundary|
        threshold_side?(boundary, direction)
      end
      return true if matching_boundaries.empty?

      return matching_boundaries.any? { |boundary| boundary.significance(direction) == :regression }
    end

    boundary = boundary(alert.benchmark, alert.measure)
    return true unless boundary && threshold_side?(boundary, direction)

    boundary.significance(direction) == :regression
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def threshold_side?(boundary, direction) = direction == :lower ? boundary.lower_limit : boundary.upper_limit

  # An active alert on a measure the caller does not track (an orphaned server-side
  # threshold). Only applies when tracked_measures was given; a measure-less alert can't be
  # classified here, so it falls through to the existing benchmark-level fail-safe.
  def untracked_measure_alert?(alert)
    return false unless @tracked_measures
    return false unless alert.measure

    !@tracked_measures.include?(normalize(alert.measure))
  end

  def normalize(key)
    key.to_s.downcase.gsub(/[-\s]+/, "_")
  end

  def fetch_array(hash, key)
    value = hash[key]
    raise FormatError, "expected #{key.inspect} to be an array, got #{value.class}" unless value.is_a?(Array)

    value
  end

  def dig_string(hash, *path)
    node = dig!(hash, path)
    raise FormatError, "expected #{path.join('.')} to be a string, got #{node.class}" unless node.is_a?(String)

    node
  end

  def dig_number(hash, *path)
    node = dig!(hash, path)
    raise FormatError, "expected #{path.join('.')} to be a number, got #{node.class}" unless node.is_a?(Numeric)

    node
  end

  def dig!(hash, path)
    path.reduce(hash) do |node, key|
      raise FormatError, "expected object before #{key.inspect}, got #{node.class}" unless node.is_a?(Hash)
      raise FormatError, "missing key #{key.inspect}" unless node.key?(key)

      node[key]
    end
  end

  def dig_optional_string(hash, *path)
    node = path.reduce(hash) { |acc, key| acc.is_a?(Hash) ? acc[key] : nil }
    node.is_a?(String) ? node : nil
  end

  def optional_number(hash, key)
    value = hash[key]
    return nil if value.nil?
    raise FormatError, "expected #{key.inspect} to be a number or null, got #{value.class}" unless value.is_a?(Numeric)

    value
  end
end
