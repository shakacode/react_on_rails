# frozen_string_literal: true

# Builds the public Bencher perf-plot URL for a single benchmark from a parsed
# `bencher run --format json` report (issue #3601 item 2). The query mirrors the
# comma-separated lists Bencher's perf view expects — branches/heads/testbeds/benchmarks/
# measures, then a trailing report= — as of the CLI v0.6.8 pin in bencher_report.rb. That
# shape is an external, undocumented contract, so re-verify a real perf link still resolves
# when bumping the pin (the param order is pinned in-repo by bencher_report_spec.rb).
#
# Every field here is informational — it only decides whether a benchmark name links
# out — so extraction is lenient: a missing piece yields nil and an unlinked name, never
# an error. Kept separate from BencherReport's strict regression/boundary parsing.
class BencherPerfUrl
  # Public Bencher host; the path is /perf/<project-slug> (public links).
  BASE = "https://bencher.dev"

  def initialize(raw)
    @raw = raw.is_a?(Hash) ? raw : {}
    @context = extract_context
    @targets = index_targets
  end

  # The perf URL for one benchmark (all its measures), or nil when any required id is
  # missing (then the caller renders the name unlinked).
  def for_benchmark(benchmark_name)
    target = @targets[benchmark_name]
    return nil if target.nil?

    measure_uuids = target[:measure_uuids].uniq
    return nil unless ready?(target, measure_uuids)

    "#{BASE}/perf/#{@context[:project_slug]}?#{query(target, measure_uuids)}"
  end

  # True when the report-wide ids every perf link needs (project slug + branch & testbed
  # uuids) are all present. They are shared by every benchmark, so if any is missing EVERY
  # link degrades to an unlinked name — the all-or-nothing signal BencherReport warns on.
  def context_ready?
    [@context[:project_slug], @context[:branch_uuid], @context[:testbed_uuid]].all?
  end

  # True when the report listed at least one (named) benchmark.
  def any_benchmarks?
    @targets.any?
  end

  private

  def ready?(target, measure_uuids)
    context_ready? && target[:benchmark_uuid] && !measure_uuids.empty?
  end

  # Param order matches the comma-separated lists Bencher's perf view expects (branches,
  # heads, testbeds, benchmarks, measures) plus a trailing report=. Values are UUIDs / a
  # slug / comma-joined UUID lists — all RFC 3986 query-safe characters — so no escaping is
  # needed; the list comma is left literal (a valid query sub-delimiter) for readability
  # rather than percent-encoded to %2C.
  def query(target, measure_uuids)
    params = [["branches", @context[:branch_uuid]]]
    params << ["heads", @context[:head_uuid]] if @context[:head_uuid]
    params << ["testbeds", @context[:testbed_uuid]]
    params << ["benchmarks", target[:benchmark_uuid]]
    params << ["measures", measure_uuids.join(",")]
    params << ["report", @context[:report_uuid]] if @context[:report_uuid]
    params.map { |key, value| "#{key}=#{value}" }.join("&")
  end

  # Top-level ids shared by every benchmark's perf link. Read leniently (nil if absent).
  def extract_context
    {
      project_slug: dig_str(@raw, "project", "slug"),
      report_uuid: dig_str(@raw, "uuid"),
      branch_uuid: dig_str(@raw, "branch", "uuid"),
      head_uuid: dig_str(@raw, "branch", "head", "uuid"),
      testbed_uuid: dig_str(@raw, "testbed", "uuid")
    }
  end

  # Per-benchmark perf inputs (the benchmark UUID + its measure UUIDs), read leniently.
  # Walks the same results array as BencherReport but never raises: a malformed shape just
  # yields fewer/no targets and unlinked names.
  def index_targets
    targets = {}
    results = @raw["results"]
    return targets unless results.is_a?(Array)

    results.each do |iteration|
      next unless iteration.is_a?(Array)

      iteration.each { |result| collect_target(targets, result) }
    end
    targets
  end

  def collect_target(targets, result)
    name = dig_str(result, "benchmark", "name") if result.is_a?(Hash)
    return if name.nil?

    target = targets[name] ||= { benchmark_uuid: dig_str(result, "benchmark", "uuid"), measure_uuids: [] }
    measures = result["measures"]
    return unless measures.is_a?(Array)

    measures.each do |measure_entry|
      uuid = dig_str(measure_entry, "measure", "uuid")
      target[:measure_uuids] << uuid if uuid
    end
  end

  # Lenient nested String fetch: nil for any missing / non-Hash / non-String node.
  def dig_str(hash, *path)
    node = path.reduce(hash) { |acc, key| acc.is_a?(Hash) ? acc[key] : nil }
    node.is_a?(String) ? node : nil
  end
end
