# frozen_string_literal: true

require "open3"
require "rbconfig"

require_relative "spec_helper"

RSpec.describe "run-local-benchmark-comparison" do
  let(:script) { File.expand_path("../run-local-benchmark-comparison.rb", __dir__) }

  def run_script(*args)
    Open3.capture3(RbConfig.ruby, script, "core", *args, "--dry-run")
  end

  it "copies direct benchmark helper dependencies into old-ref shims" do
    runner_shim_files = File.read(script).match(/RUNNER_SHIM_FILES = %w\[(.*?)\]/m).captures.fetch(0).split

    expect(runner_shim_files).to include("benchmarks/lib/benchmark_target_monitor.rb")
  end

  it "rejects A/B refs that sanitize to the same scenario name" do
    _stdout, stderr, status = run_script("--a-ref", "feature/foo", "--b-ref", "feature-foo")

    expect(status).not_to be_success
    expect(stderr).to include("A/B scenario names must be distinct")
  end

  it "rejects baselines and candidates that do not match a scenario name" do
    _stdout, stderr, status = run_script(
      "--a-ref", "main",
      "--b-ref", "v17.0.0.rc.5",
      "--baseline", "rc5",
      "--candidate", "main"
    )

    expect(status).not_to be_success
    expect(stderr).to include("--baseline and --candidate must match scenario names")
  end
end
