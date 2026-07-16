# frozen_string_literal: true

require "json"

module LocalBenchmarkRunner
  # Aggregates repeated local benchmark JSON files into an A/B route comparison.
  class ComparisonSummary
    Run = Struct.new(:scenario, :repetition, :benchmark_json, keyword_init: true)
    ROUTE_SUITE_SUFFIX_PATTERN = /: (?:Core|Pro)\z/

    RouteSummary = Struct.new(
      :route,
      :baseline,
      :candidate,
      :baseline_values,
      :candidate_values,
      keyword_init: true
    ) do
      def baseline_median_rps = ComparisonSummary.median(baseline_values)
      def candidate_median_rps = ComparisonSummary.median(candidate_values)

      def rps_delta_percent
        return nil if baseline_median_rps.nil? || baseline_median_rps.zero?

        ((candidate_median_rps - baseline_median_rps) / baseline_median_rps) * 100.0
      end

      def baseline_cv_percent = ComparisonSummary.coefficient_of_variation_percent(baseline_values)
      def candidate_cv_percent = ComparisonSummary.coefficient_of_variation_percent(candidate_values)

      def to_h
        {
          route:,
          baseline:,
          candidate:,
          baseline_samples: baseline_values.size,
          candidate_samples: candidate_values.size,
          baseline_median_rps:,
          candidate_median_rps:,
          rps_delta_percent:,
          baseline_cv_percent:,
          candidate_cv_percent:
        }
      end
    end

    def self.median(values)
      sorted = values.compact.sort
      return nil if sorted.empty?

      midpoint = sorted.length / 2
      sorted.length.odd? ? sorted.fetch(midpoint) : (sorted.fetch(midpoint - 1) + sorted.fetch(midpoint)) / 2.0
    end

    def self.coefficient_of_variation_percent(values)
      clean = values.compact
      return nil if clean.empty?

      avg = mean(clean)
      return 0.0 if avg.zero? || clean.length == 1

      (sample_standard_deviation(clean) / avg) * 100.0
    end

    def self.mean(values)
      values.sum / values.length.to_f
    end

    def self.sample_standard_deviation(values)
      avg = mean(values)
      variance = values.sum { |value| (value - avg)**2 } / (values.length - 1).to_f
      Math.sqrt(variance)
    end

    attr_reader :runs, :baseline, :candidate

    def initialize(runs:, baseline:, candidate:)
      @runs = runs
      @baseline = baseline
      @candidate = candidate
    end

    def route_summaries
      @route_summaries ||= common_routes.to_h do |route|
        [
          route,
          RouteSummary.new(
            route:,
            baseline:,
            candidate:,
            baseline_values: rps_values_for(baseline, route),
            candidate_values: rps_values_for(candidate, route)
          )
        ]
      end
    end

    def only_baseline_routes
      scenario_routes.fetch(baseline, []) - scenario_routes.fetch(candidate, [])
    end

    def only_candidate_routes
      scenario_routes.fetch(candidate, []) - scenario_routes.fetch(baseline, [])
    end

    def to_h
      {
        baseline:,
        candidate:,
        common_route_count: common_routes.size,
        baseline_only_route_count: only_baseline_routes.size,
        candidate_only_route_count: only_candidate_routes.size,
        run_counts:,
        routes: route_summaries.transform_values(&:to_h)
      }
    end

    private

    def common_routes
      @common_routes ||= (scenario_routes.fetch(baseline, []) & scenario_routes.fetch(candidate, [])).sort
    end

    def scenario_routes
      @scenario_routes ||= scenario_metrics.transform_values { |routes| routes.keys.sort }
    end

    def rps_values_for(scenario, route)
      per_route_runs.fetch(scenario, {}).fetch(route, []).filter_map { |metrics| metrics.dig("rps", "value")&.to_f }
    end

    def per_route_runs
      @per_route_runs ||= runs.each_with_object({}) do |run, grouped|
        grouped[run.scenario] ||= {}
        read_benchmark_json(run.benchmark_json).each do |route, metrics|
          grouped[run.scenario][route] ||= []
          grouped[run.scenario][route] << metrics
        end
      end
    end

    def scenario_metrics
      @scenario_metrics ||= per_route_runs.transform_values do |routes|
        routes.transform_values(&:last)
      end
    end

    def run_counts
      runs.each_with_object(Hash.new(0)) { |run, counts| counts[run.scenario] += 1 }.to_h
    end

    def read_benchmark_json(path)
      JSON.parse(File.read(path)).transform_keys { |benchmark_name| route_name(benchmark_name) }
    end

    def route_name(benchmark_name)
      benchmark_name.sub(ROUTE_SUITE_SUFFIX_PATTERN, "")
    end
  end
end
