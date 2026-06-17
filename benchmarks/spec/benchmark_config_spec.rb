# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/benchmark_config"

# env_or_default underpins every benchmark parameter (RATE, CONNECTIONS, ...).
# The benchmark workflow passes "" for any omitted workflow_dispatch input, so an
# empty string must be treated as unset and fall back to the default rather than
# overriding it with a blank value (#3459). These pin that "0 = unset" branch was
# replaced by "empty = unset" semantics.
RSpec.describe "benchmark_config env_or_default" do
  around do |example|
    saved = ENV.key?("BENCHMARK_SPEC_KEY") ? ENV["BENCHMARK_SPEC_KEY"] : :unset
    example.run
  ensure
    if saved == :unset
      ENV.delete("BENCHMARK_SPEC_KEY")
    else
      ENV["BENCHMARK_SPEC_KEY"] = saved
    end
  end

  it "returns the default when the key is unset" do
    ENV.delete("BENCHMARK_SPEC_KEY")

    expect(env_or_default("BENCHMARK_SPEC_KEY", "fallback")).to eq("fallback")
  end

  it "treats an empty string (omitted workflow_dispatch input) as unset" do
    ENV["BENCHMARK_SPEC_KEY"] = ""

    expect(env_or_default("BENCHMARK_SPEC_KEY", "fallback")).to eq("fallback")
  end

  it "returns the env value when one is present" do
    ENV["BENCHMARK_SPEC_KEY"] = "from-env"

    expect(env_or_default("BENCHMARK_SPEC_KEY", "fallback")).to eq("from-env")
  end

  it "preserves a literal '0' value rather than treating it as unset" do
    # The old implementation special-cased "0" as unset; after that branch was
    # removed a caller asking for 0 (e.g. RATE/CONNECTIONS edge inputs) must get
    # the real value back so validation, not env_or_default, decides if it's legal.
    ENV["BENCHMARK_SPEC_KEY"] = "0"

    expect(env_or_default("BENCHMARK_SPEC_KEY", "fallback")).to eq("0")
  end

  it "returns the default unchanged (non-string defaults pass through)" do
    ENV.delete("BENCHMARK_SPEC_KEY")

    # CONNECTIONS et al. pass Integer defaults and call .to_i on the result, so
    # env_or_default must hand the default back untouched rather than stringifying it.
    expect(env_or_default("BENCHMARK_SPEC_KEY", 10)).to eq(10)
  end
end
