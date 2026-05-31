# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "bin/ci-switch-config" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:source_script_path) { File.join(repo_root, "bin/ci-switch-config") }

  it "reports shakapacker-webpack before core shakapacker in status output" do
    stdout, stderr, status = ci_switch_status(
      "shakapacker" => "10.1.0",
      "shakapacker-webpack" => "~10.1.0"
    )

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker-webpack): 10.1.0")
  end

  it "reports shakapacker-rspack before core shakapacker when webpack is absent" do
    stdout, stderr, status = ci_switch_status(
      "shakapacker" => "10.1.0",
      "shakapacker-rspack" => "^10.1.0"
    )

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker-rspack): 10.1.0")
  end

  it "reports core shakapacker when adapter packages are absent" do
    stdout, stderr, status = ci_switch_status(
      "shakapacker" => "^10.1.0"
    )

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker): 10.1.0")
  end

  def ci_switch_status(dependencies)
    Dir.mktmpdir do |tmpdir|
      fake_script_path = File.join(tmpdir, "bin/ci-switch-config")
      package_json_path = File.join(tmpdir, "react_on_rails/spec/dummy/package.json")

      FileUtils.mkdir_p(File.dirname(fake_script_path))
      FileUtils.mkdir_p(File.dirname(package_json_path))
      FileUtils.cp(source_script_path, fake_script_path)
      FileUtils.chmod("+x", fake_script_path)

      File.write(package_json_path, JSON.pretty_generate("dependencies" => dependencies))

      return Open3.capture3(fake_script_path, "status", chdir: tmpdir)
    end
  end
end
