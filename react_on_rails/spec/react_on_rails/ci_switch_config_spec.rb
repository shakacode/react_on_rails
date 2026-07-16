# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "shellwords"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "bin/ci-switch-config" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:source_script_path) { File.join(repo_root, "bin/ci-switch-config") }
  let(:read_tool_version_path) { File.join(repo_root, "bin/read-tool-version") }

  it "reports shakapacker-webpack before core shakapacker in status output" do
    stdout, stderr, status = ci_switch_status({
                                                "shakapacker" => "10.1.0",
                                                "shakapacker-webpack" => "~10.1.0"
                                              })

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker-webpack): 10.1.0")
  end

  it "reports shakapacker-rspack before core shakapacker when webpack is absent" do
    stdout, stderr, status = ci_switch_status({
                                                "shakapacker" => "10.1.0",
                                                "shakapacker-rspack" => "^10.1.0"
                                              })

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker-rspack): 10.1.0")
  end

  it "prefers shakapacker-webpack when both adapter packages are present" do
    stdout, stderr, status = ci_switch_status({
                                                "shakapacker" => "10.1.0",
                                                "shakapacker-webpack" => "~10.1.0",
                                                "shakapacker-rspack" => "^10.1.0"
                                              })

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker-webpack): 10.1.0")
  end

  it "reports core shakapacker when adapter packages are absent" do
    stdout, stderr, status = ci_switch_status({
                                                "shakapacker" => "^10.1.0"
                                              })

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker): 10.1.0")
  end

  it "ignores non-semver adapter specs instead of reporting the raw package line" do
    stdout, stderr, status = ci_switch_status({
                                                "shakapacker" => "10.1.0",
                                                "shakapacker-webpack" => "workspace:~10.1.0"
                                              })

    expect(status).to be_success, stderr
    expect(stdout).to include("Shakapacker (npm, shakapacker): 10.1.0")
    expect(stdout).not_to include("workspace:~10.1.0")
  end

  it "warns in status when a non-git checkout may under-report latest runtimes" do
    stdout, stderr, status = ci_switch_status(
      { "shakapacker" => "10.1.0" },
      tool_versions_source: ".minimum.tool-versions"
    )

    expect(status).to be_success, stderr
    expect(stdout).to include("latest Ruby/Node may be under-reported")
  end

  it "reports configured runtimes without executing runtime shims" do
    Dir.mktmpdir do |tmpdir|
      fake_script_path = install_ci_switch_scripts(tmpdir)
      fake_bin_path = File.join(tmpdir, "fake-bin")
      marker_path = File.join(tmpdir, "runtime-shim-called")
      tool_versions_path = File.join(tmpdir, ".tool-versions")
      expected_tool_versions = File.read(File.join(repo_root, ".tool-versions"))
      expected_ruby = expected_tool_versions[/^ruby\s+(\S+)/, 1]
      expected_node = expected_tool_versions[/^nodejs\s+(\S+)/, 1]

      FileUtils.cp(File.join(repo_root, ".tool-versions"), tool_versions_path)
      FileUtils.cp(File.join(repo_root, ".minimum.tool-versions"), File.join(tmpdir, ".minimum.tool-versions"))
      FileUtils.mkdir_p(fake_bin_path)

      %w[ruby node].each do |runtime|
        shim_path = File.join(fake_bin_path, runtime)
        File.write(
          shim_path,
          <<~BASH
            #!/usr/bin/env bash
            echo #{Shellwords.escape(runtime)} >> #{Shellwords.escape(marker_path)}
            exit 99
          BASH
        )
        FileUtils.chmod("+x", shim_path)
      end

      stdout, stderr, status = Open3.capture3(
        { "PATH" => "#{fake_bin_path}:#{ENV.fetch('PATH')}" },
        fake_script_path,
        "status",
        chdir: tmpdir
      )

      expect(status).to be_success, stderr
      expect(stdout).to include("Ruby: #{expected_ruby} (configured)")
      expect(stdout).to include("Node: #{expected_node} (configured)")
      expect(File).not_to exist(marker_path)
    end
  end

  it "restores the committed latest tool-version profile saved from the current git head" do
    with_ci_switch_tool_versions_repo do |tmpdir, harness_path|
      committed_versions = File.read(File.join(tmpdir, ".tool-versions"))

      run_ci_switch_tool_versions(harness_path, "minimum-tool-versions", chdir: tmpdir)

      expect(File.read(File.join(tmpdir, ".maximum.tool-versions"))).to eq(committed_versions)
      expect(File.read(File.join(tmpdir, ".maximum.tool-versions.head")).strip).to eq(git_head(tmpdir))
      expect(File.read(File.join(tmpdir, ".tool-versions"))).to eq(
        File.read(File.join(tmpdir, ".minimum.tool-versions"))
      )

      run_ci_switch_tool_versions(harness_path, "latest-tool-versions", chdir: tmpdir)

      expect(File.read(File.join(tmpdir, ".tool-versions"))).to eq(committed_versions)
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions"))
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions.head"))
    end
  end

  it "preserves an existing latest profile when minimum mode is rerun after local edits" do
    with_ci_switch_tool_versions_repo do |tmpdir, harness_path|
      latest_versions = File.read(File.join(tmpdir, ".tool-versions"))
      local_minimum_edit = "ruby 3.3.8\nnodejs 20.0.0\n"

      run_ci_switch_tool_versions(harness_path, "minimum-tool-versions", chdir: tmpdir)
      File.write(File.join(tmpdir, ".tool-versions"), local_minimum_edit)

      run_ci_switch_tool_versions(harness_path, "minimum-tool-versions", chdir: tmpdir)

      expect(File.read(File.join(tmpdir, ".maximum.tool-versions"))).to eq(latest_versions)
      expect(File.read(File.join(tmpdir, ".maximum.tool-versions.head")).strip).to eq(git_head(tmpdir))
      expect(File.read(File.join(tmpdir, ".tool-versions"))).to eq(
        File.read(File.join(tmpdir, ".minimum.tool-versions"))
      )
    end
  end

  it "ignores a stale saved latest tool-version profile from another git head" do
    with_ci_switch_tool_versions_repo do |tmpdir, harness_path|
      committed_versions = File.read(File.join(tmpdir, ".tool-versions"))

      File.write(File.join(tmpdir, ".tool-versions"), File.read(File.join(tmpdir, ".minimum.tool-versions")))
      File.write(File.join(tmpdir, ".maximum.tool-versions"), "ruby 4.0.4\nnodejs 22.11.0\n")
      File.write(File.join(tmpdir, ".maximum.tool-versions.head"), "stale-head\n")

      run_ci_switch_tool_versions(harness_path, "latest-tool-versions", chdir: tmpdir)

      expect(File.read(File.join(tmpdir, ".tool-versions"))).to eq(committed_versions)
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions"))
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions.head"))
    end
  end

  it "warns about stale saved latest profile when minimum mode is already active" do
    with_ci_switch_tool_versions_repo do |tmpdir, harness_path|
      minimum_versions = File.read(File.join(tmpdir, ".minimum.tool-versions"))

      File.write(File.join(tmpdir, ".tool-versions"), minimum_versions)
      File.write(File.join(tmpdir, ".maximum.tool-versions"), "ruby 4.0.4\nnodejs 22.11.0\n")
      File.write(File.join(tmpdir, ".maximum.tool-versions.head"), "stale-head\n")

      stdout, stderr, status = Open3.capture3(harness_path, "minimum-tool-versions", chdir: tmpdir)

      expect(status).to be_success, "#{stdout}\n#{stderr}"
      expect(stdout).to include(
        "Stale runtime-version backup exists from a different branch; it will be discarded on restore."
      )
    end
  end

  it "accepts a legacy saved latest profile without a head sidecar when contents match the current git head" do
    with_ci_switch_tool_versions_repo do |tmpdir, harness_path|
      committed_versions = File.read(File.join(tmpdir, ".tool-versions"))

      File.write(File.join(tmpdir, ".tool-versions"), File.read(File.join(tmpdir, ".minimum.tool-versions")))
      File.write(File.join(tmpdir, ".maximum.tool-versions"), committed_versions)
      FileUtils.rm_f(File.join(tmpdir, ".maximum.tool-versions.head"))

      _stdout, stderr, status = Open3.capture3(harness_path, "backup-valid-for-restore", chdir: tmpdir)

      expect(status).to be_success, stderr
    end
  end

  it "does not accept stale head-sidecar backups even when contents match the current git head" do
    with_ci_switch_tool_versions_repo do |tmpdir, harness_path|
      committed_versions = File.read(File.join(tmpdir, ".tool-versions"))

      File.write(File.join(tmpdir, ".tool-versions"), File.read(File.join(tmpdir, ".minimum.tool-versions")))
      File.write(File.join(tmpdir, ".maximum.tool-versions"), committed_versions)
      File.write(File.join(tmpdir, ".maximum.tool-versions.head"), "stale-head\n")

      _stdout, stderr, status = Open3.capture3(harness_path, "backup-valid-for-restore", chdir: tmpdir)

      expect(status).not_to be_success, stderr

      run_ci_switch_tool_versions(harness_path, "latest-tool-versions", chdir: tmpdir)

      expect(File.read(File.join(tmpdir, ".tool-versions"))).to eq(committed_versions)
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions"))
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions.head"))
    end
  end

  it "does not accept same-head backups when contents differ from the committed current git head" do
    with_ci_switch_tool_versions_repo do |tmpdir, harness_path|
      committed_versions = File.read(File.join(tmpdir, ".tool-versions"))

      File.write(File.join(tmpdir, ".tool-versions"), File.read(File.join(tmpdir, ".minimum.tool-versions")))
      File.write(File.join(tmpdir, ".maximum.tool-versions"), "ruby 4.0.4\nnodejs 22.11.0\n")
      File.write(File.join(tmpdir, ".maximum.tool-versions.head"), "#{git_head(tmpdir)}\n")

      _stdout, stderr, status = Open3.capture3(harness_path, "backup-valid-for-restore", chdir: tmpdir)

      expect(status).not_to be_success, stderr

      run_ci_switch_tool_versions(harness_path, "latest-tool-versions", chdir: tmpdir)

      expect(File.read(File.join(tmpdir, ".tool-versions"))).to eq(committed_versions)
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions"))
      expect(File).not_to exist(File.join(tmpdir, ".maximum.tool-versions.head"))
    end
  end

  it "warns when a non-git checkout falls back from latest to the local minimum profile" do
    Dir.mktmpdir do |tmpdir|
      harness_path = File.join(tmpdir, "bin/ci-switch-tool-versions")
      script_copy_path = install_ci_switch_scripts(tmpdir)

      File.write(harness_path, ci_switch_tool_versions_harness(script_copy_path))
      FileUtils.cp(File.join(repo_root, ".minimum.tool-versions"), File.join(tmpdir, ".tool-versions"))
      FileUtils.cp(File.join(repo_root, ".minimum.tool-versions"), File.join(tmpdir, ".minimum.tool-versions"))
      FileUtils.chmod("+x", harness_path)

      stdout, stderr, status = Open3.capture3(harness_path, "read-latest-ruby", chdir: tmpdir)

      expect(status).to be_success, "#{stdout}\n#{stderr}"
      expect(stdout).to include(File.read(File.join(repo_root, ".minimum.tool-versions")).match(/ruby (\S+)/)[1])
      expect(stderr).to include("falling back to current .tool-versions")
      expect(stderr).to include("current .tool-versions matches the minimum profile")
    end
  end

  it "parses plain mise/asdf tool version lines via the shared bin/read-tool-version helper" do
    Dir.mktmpdir do |tmpdir|
      tool_versions_path = File.join(tmpdir, ".tool-versions")
      File.write(tool_versions_path, "ruby 3.3.7\nnodejs 22.12.0\n")

      stdout, stderr, status = Open3.capture3(read_tool_version_path, tool_versions_path, "nodejs")

      expect(status).to be_success, stderr
      expect(stdout.strip).to eq("22.12.0")
    end
  end

  it "fails via the shared bin/read-tool-version helper when the tool-versions file is missing" do
    Dir.mktmpdir do |tmpdir|
      missing_path = File.join(tmpdir, ".tool-versions")

      _stdout, stderr, status = Open3.capture3(read_tool_version_path, missing_path, "ruby")

      expect(status).not_to be_success
      expect(stderr).to include("Missing #{missing_path}")
    end
  end

  it "fails via the shared bin/read-tool-version helper when the tool is not listed" do
    Dir.mktmpdir do |tmpdir|
      tool_versions_path = File.join(tmpdir, ".tool-versions")
      File.write(tool_versions_path, "ruby 3.3.7\n")

      _stdout, stderr, status = Open3.capture3(read_tool_version_path, tool_versions_path, "nodejs")

      expect(status).not_to be_success
      expect(stderr).to include("Missing nodejs version in #{tool_versions_path}")
    end
  end

  it "reports a friendly error when the minimum tool-version file is missing" do
    Dir.mktmpdir do |tmpdir|
      fake_script_path = install_ci_switch_scripts(tmpdir)

      FileUtils.cp(File.join(repo_root, ".tool-versions"), File.join(tmpdir, ".tool-versions"))

      _stdout, stderr, status = Open3.capture3(fake_script_path, "status", chdir: tmpdir)

      expect(status).not_to be_success
      expect(stderr).to include("Error: #{File.join(tmpdir, '.minimum.tool-versions')} not found.")
      expect(stderr).to include("This file is required at script load time and should be committed.")
    end
  end

  it "reports a friendly error when the CI dependency versions file is missing" do
    Dir.mktmpdir do |tmpdir|
      fake_script_path = install_ci_switch_scripts(tmpdir)

      FileUtils.cp(File.join(repo_root, ".tool-versions"), File.join(tmpdir, ".tool-versions"))
      FileUtils.cp(File.join(repo_root, ".minimum.tool-versions"), File.join(tmpdir, ".minimum.tool-versions"))
      FileUtils.rm(File.join(tmpdir, ".ci-dependency-versions"))

      _stdout, stderr, status = Open3.capture3(fake_script_path, "status", chdir: tmpdir)

      expect(status).not_to be_success
      expect(stderr).to include("Error: #{File.join(tmpdir, '.ci-dependency-versions')} not found.")
      expect(stderr).to include("This file is required at script load time and should be committed.")
    end
  end

  def install_ci_switch_scripts(tmpdir)
    script_copy_path = File.join(tmpdir, "bin/ci-switch-config")

    FileUtils.mkdir_p(File.dirname(script_copy_path))
    FileUtils.cp(source_script_path, script_copy_path)
    # bin/ci-switch-config sources this shared parser from its own directory.
    FileUtils.cp(read_tool_version_path, File.join(tmpdir, "bin/read-tool-version"))
    # Dependency profile versions are read from this committed file at load time.
    FileUtils.cp(File.join(repo_root, ".ci-dependency-versions"), File.join(tmpdir, ".ci-dependency-versions"))
    FileUtils.chmod("+x", script_copy_path)

    script_copy_path
  end

  def ci_switch_status(dependencies, tool_versions_source: ".tool-versions")
    Dir.mktmpdir do |tmpdir|
      fake_script_path = install_ci_switch_scripts(tmpdir)
      package_json_path = File.join(tmpdir, "react_on_rails/spec/dummy/package.json")

      FileUtils.mkdir_p(File.dirname(package_json_path))
      FileUtils.cp(File.join(repo_root, tool_versions_source), File.join(tmpdir, ".tool-versions"))
      FileUtils.cp(File.join(repo_root, ".minimum.tool-versions"), File.join(tmpdir, ".minimum.tool-versions"))

      File.write(package_json_path, JSON.pretty_generate("dependencies" => dependencies))

      Open3.capture3(fake_script_path, "status", chdir: tmpdir)
    end
  end

  def with_ci_switch_tool_versions_repo
    Dir.mktmpdir do |tmpdir|
      harness_path = File.join(tmpdir, "bin/ci-switch-tool-versions")
      script_copy_path = install_ci_switch_scripts(tmpdir)

      File.write(harness_path, ci_switch_tool_versions_harness(script_copy_path))
      FileUtils.cp(File.join(repo_root, ".tool-versions"), File.join(tmpdir, ".tool-versions"))
      FileUtils.cp(File.join(repo_root, ".minimum.tool-versions"), File.join(tmpdir, ".minimum.tool-versions"))
      FileUtils.chmod("+x", harness_path)

      run_git(tmpdir, "init")
      run_git(tmpdir, "config", "user.email", "codex@example.com")
      run_git(tmpdir, "config", "user.name", "Codex")
      run_git(tmpdir, "add", "-f", ".tool-versions", ".minimum.tool-versions", "bin/ci-switch-tool-versions")
      run_git(tmpdir, "commit", "--no-gpg-sign", "-m", "Initial tool versions")

      yield tmpdir, harness_path
    end
  end

  def ci_switch_tool_versions_harness(script_path)
    [
      "#!/usr/bin/env bash",
      "set -euo pipefail",
      "source #{Shellwords.escape(script_path)}",
      'case "${1:-}" in',
      "  minimum-tool-versions)",
      "    set_tool_versions_to_minimum",
      "    ;;",
      "  latest-tool-versions)",
      "    restore_tool_versions_to_latest",
      "    ;;",
      "  read-latest-ruby)",
      "    read_latest_tool_version ruby",
      "    ;;",
      "  backup-valid-for-restore)",
      "    saved_tool_versions_valid_for_restore",
      "    ;;",
      "  *)",
      '    echo "Usage: $0 {' \
      'minimum-tool-versions|latest-tool-versions|read-latest-ruby|backup-valid-for-restore}" >&2',
      "    exit 1",
      "    ;;",
      "esac",
      ""
    ].join("\n")
  end

  def run_ci_switch_tool_versions(harness_path, command, chdir:)
    stdout, stderr, status = Open3.capture3(harness_path, command, chdir:)

    expect(status).to be_success, "#{stdout}\n#{stderr}"
  end

  def run_git(chdir, *args)
    stdout, stderr, status = Open3.capture3("git", *args, chdir:)

    expect(status).to be_success, "#{stdout}\n#{stderr}"
  end

  def git_head(chdir)
    stdout, stderr, status = Open3.capture3("git", "rev-parse", "HEAD", chdir:)

    expect(status).to be_success, stderr
    stdout.strip
  end
end
