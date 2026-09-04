# frozen_string_literal: true

require "open3"
require "rbconfig"

require_relative "spec_helper"

RSpec.describe "run-local-benchmark" do
  let(:script) { File.expand_path("../run-local-benchmark.rb", __dir__) }

  license_values = {
    "an absent" => nil,
    "an empty" => "",
    "a whitespace-only" => " \t"
  }

  def run_script(suite, *options, license: nil)
    env = {
      "BENCHER_API_KEY" => nil,
      "BENCHER_API_TOKEN" => nil,
      "REACT_ON_RAILS_PRO_LICENSE" => license
    }

    Open3.capture3(env, RbConfig.ruby, script, suite, *options)
  end

  {
    "pro" => "Pro",
    "pro-node-renderer" => "Pro Node Renderer"
  }.each do |suite, suite_name|
    license_values.each do |license_description, license|
      it "preflights #{suite} with #{license_description} Pro license" do
        stdout, _stderr, status = run_script(suite, "--no-upload", "--preflight-only", license:)

        expect(status).to be_success
        expect(stdout).to include("Suite: #{suite_name} |")
      end
    end
  end

  it "still requires Bencher credentials when upload is enabled" do
    _stdout, stderr, status = run_script("core", "--upload", "--preflight-only")

    expect(status).not_to be_success
    expect(stderr).to include("BENCHER_API_KEY or BENCHER_API_TOKEN is required for Bencher uploads.")
  end
end
