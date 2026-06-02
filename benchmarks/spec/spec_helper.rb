# frozen_string_literal: true

# Lightweight spec_helper for the stdlib-only scripts under benchmarks/.
#
# Unlike react_on_rails/spec/react_on_rails/spec_helper.rb, this deliberately
# does NOT load Rails or the react_on_rails gem: the benchmark scripts are plain
# Ruby (require "json" and friends), so the runner only needs rspec. Keep it that
# way — pulling in Rails here would defeat the point of testing these in
# isolation and slow the suite down.

require "json"

# Mixin for specs that drive scripts which read all of their input from ENV
# (e.g. generate_matrix.rb). `with_env` swaps in the given vars, clears every
# other benchmark gating key so the host/CI environment can't leak in, and
# always restores the original ENV afterwards.
module BenchmarkEnvHelper
  GATING_ENV_KEYS = %w[
    BENCHMARK_EVENT_NAME
    BENCHMARK_APP_VERSION
    BENCHMARK_NON_RUNTIME_ONLY
    BENCHMARK_PULL_REQUEST_LABELS
    BENCHMARK_PULL_REQUEST_HEAD_REPO
    BENCHMARK_ROUTES
    GITHUB_REPOSITORY
    RUN_CORE_BENCHMARKS
    RUN_PRO_BENCHMARKS
    RUN_PRO_NODE_RENDERER_BENCHMARKS
  ].freeze

  def with_env(vars)
    snapshot = ENV.to_h
    GATING_ENV_KEYS.each { |key| ENV.delete(key) }
    vars.each { |key, value| ENV[key.to_s] = value.to_s }
    yield
  ensure
    ENV.replace(snapshot)
  end
end
