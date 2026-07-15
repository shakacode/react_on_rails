# frozen_string_literal: true

require "json"
require "yaml"
require_relative "spec_helper"

RSpec.describe "Pro hosted CI workflow" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:workflow) do
    YAML.safe_load_file(
      File.join(repo_root, ".github/workflows/pro-test-package-and-gem.yml"),
      aliases: true
    )
  end
  let(:pro_package) do
    JSON.parse(File.read(File.join(repo_root, "packages/react-on-rails-pro/package.json")))
  end

  it "runs the packaged React compatibility smoke on the selected Pro hosted path" do
    package_test_job = workflow.fetch("jobs").fetch("package-js-tests")
    commands = package_test_job.fetch("steps").filter_map { |step| step["run"] }

    expect(package_test_job.fetch("if")).to include("run_pro_tests == 'true'")
    expect(commands).to include("pnpm --filter react-on-rails-pro test")
    expect(pro_package.dig("scripts", "test")).to include("pnpm run test:packed-react-compatibility")
    expect(commands).to include("pnpm --filter react-on-rails-pro-node-renderer run ci")
  end
end
