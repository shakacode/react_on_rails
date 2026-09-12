# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "bin/lefthook/markdown-link-lint" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:hook_path) { File.join(repo_root, "bin/lefthook/markdown-link-lint") }

  it "skips an incompatible lychee version with an actionable warning" do
    _stdout, stderr, status = run_hook("lychee 0.24.2")

    expect(status).to be_success
    expect(stderr).to include("lychee version mismatch; skipping offline Markdown link check.")
    expect(stderr).to include("Found: lychee 0.24.2")
    expect(stderr).to include("Required: lychee 0.23.0 (matches CI)")
  end

  it "keeps the missing lychee skip behavior" do
    _stdout, stderr, status = run_hook(nil)

    expect(status).to be_success
    expect(stderr).to include("lychee is not installed; skipping offline Markdown link check.")
  end

  it "runs the CI-compatible lychee version" do
    Dir.mktmpdir do |tmpdir|
      args_file = File.join(tmpdir, "lychee.args")
      _stdout, stderr, status = run_hook("lychee 0.23.0", args_file:)

      expect(status).to be_success, stderr
      expect(File.read(args_file).lines.map(&:chomp)).to eq(["--config", ".lychee.toml", "--offline", "README.md"])
    end
  end

  def run_hook(version, args_file: nil)
    Dir.mktmpdir do |tmpdir|
      write_hook_fixture(tmpdir, version)
      path = [File.join(tmpdir, "fake-bin"), version ? ENV.fetch("PATH") : "/usr/bin:/bin"].join(":")
      environment = { "PATH" => path }
      environment["LYCHEE_ARGS_FILE"] = args_file if args_file

      return Open3.capture3(
        environment,
        "bin/lefthook/markdown-link-lint",
        "all-changed",
        "--offline",
        chdir: tmpdir
      )
    end
  end

  def write_hook_fixture(directory, version)
    hook_directory = File.join(directory, "bin/lefthook")
    fake_bin = File.join(directory, "fake-bin")
    FileUtils.mkdir_p([hook_directory, fake_bin])
    File.symlink(hook_path, File.join(hook_directory, "markdown-link-lint"))
    File.write(File.join(hook_directory, "ensure-mise"), ":\n")
    write_executable(File.join(hook_directory, "get-changed-files"), "printf 'README.md\\n'\n")
    File.write(File.join(directory, "README.md"), "# fixture\n")
    return unless version

    write_executable(
      File.join(fake_bin, "lychee"),
      <<~BASH
        if [ "${1:-}" = "--version" ]; then
          echo "#{version}"
        elif [ -n "${LYCHEE_ARGS_FILE:-}" ]; then
          printf '%s\\n' "$@" > "$LYCHEE_ARGS_FILE"
        fi
      BASH
    )
  end

  def write_executable(path, body)
    File.write(path, "#!/usr/bin/env bash\n#{body}")
    FileUtils.chmod("+x", path)
  end
end
