# frozen_string_literal: true

require "open3"
require_relative "spec_helper"

RSpec.describe "bin/ci-local Pro RSpec dispatch" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:pro_stage) do
    File.read(File.join(repo_root, "bin/ci-local"))
        .split("# Run React on Rails Pro tests\n", 2).fetch(1)
        .split("# Summary", 2).first
  end

  it "retains harness unit coverage in a separate process from Pro and async specs" do
    stdout, stderr, status = dispatch_pro_stage

    expect(status).to be_success, stderr
    expect(stdout.lines.map(&:chomp)).to eq([
                                              "cd react_on_rails_pro && bundle_command \"/pro/Gemfile\" " \
                                              "bundle exec rspec spec/react_on_rails_pro spec/async",
                                              "cd react_on_rails_pro && bundle_command \"/pro/Gemfile\" " \
                                              "bundle exec rspec spec/load"
                                            ])
  end

  def dispatch_pro_stage
    # Execute the real stage, replacing only dependency setup and job execution.
    # The emitted commands are the boundary passed to independent RSpec processes.
    prelude = <<~BASH
      set -euo pipefail
      RUN_PRO_TESTS=true
      FAST_MODE=false
      RUN_JS=true
      PRO_GEMFILE=/pro/Gemfile
      ensure_pro_dependencies() { return 0; }
      run_job() { printf '%s\\n' "$2"; }
    BASH
    Open3.capture3({ "BASH_ENV" => nil, "ENV" => nil }, "bash", "-c", prelude + pro_stage)
  end
end
