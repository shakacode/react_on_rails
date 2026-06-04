# frozen_string_literal: true

require "json"

# Parses the report emitted by `bencher run --format json` (Bencher CLI v0.6.2;
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
class BencherReport
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

  def self.parse(json_string)
    new(JSON.parse(json_string))
  rescue JSON::ParserError => e
    raise FormatError, "Bencher report is not valid JSON: #{e.message}"
  end

  def initialize(raw)
    raise FormatError, "report is not a JSON object (got #{raw.class})" unless raw.is_a?(Hash)

    @boundaries = index_boundaries(raw)
    @alerts = parse_alerts(raw)
  end

  attr_reader :alerts

  def regression?
    !@alerts.empty?
  end

  # Boundary for a benchmark+measure, or nil if absent from the report.
  def boundary(benchmark_name, measure_key)
    @boundaries.dig(benchmark_name, normalize(measure_key))
  end

  # :regression | :improvement | nil for benchmark+measure given its direction.
  def significance(benchmark_name, measure_key, direction)
    boundary(benchmark_name, measure_key)&.significance(direction)
  end

  private

  def index_boundaries(raw)
    index = {}
    fetch_array(raw, "results").each do |iteration|
      raise FormatError, "results entry is not an array (got #{iteration.class})" unless iteration.is_a?(Array)

      iteration.each do |result|
        name = dig_string(result, "benchmark", "name")
        per_measure = index[name] ||= {}
        fetch_array(result, "measures").each do |measure_entry|
          boundary = parse_boundary(measure_entry)
          # Index by both slug and name so callers can match either form (Bencher
          # slugifies the BMF measure key, e.g. "p50_latency" -> "p50-latency").
          # Invariant: slug and name are expected to normalize to distinct strings
          # across all measures of a given benchmark. If two measures collided on a
          # normalized key the later write would silently overwrite the earlier
          # boundary; that can't happen with the current Bencher measure set.
          per_measure[normalize(dig_string(measure_entry, "measure", "slug"))] = boundary
          per_measure[normalize(dig_string(measure_entry, "measure", "name"))] = boundary
        end
      end
    end
    index
  end

  def parse_boundary(measure_entry)
    value = dig_number(measure_entry, "metric", "value")
    raw = measure_entry["boundary"]
    return Boundary.new(value: value, baseline: nil, lower_limit: nil, upper_limit: nil) if raw.nil?
    raise FormatError, "boundary is not an object (got #{raw.class})" unless raw.is_a?(Hash)

    Boundary.new(value: value, baseline: optional_number(raw, "baseline"),
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
