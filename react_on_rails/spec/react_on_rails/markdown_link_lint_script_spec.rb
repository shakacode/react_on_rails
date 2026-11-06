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

  describe "pre-push branch check" do
    it "checks local links offline and fetches only remote URLs new since the merge base" do
      Dir.mktmpdir do |tmpdir|
        write_branch_fixture(tmpdir)
        write_executable(File.join(tmpdir, "fake-bin/lychee"), <<~BASH)
          if [ "${1:-}" = "--version" ]; then echo "lychee 0.23.0"; exit 0; fi
          if [ "${3:-}" = "--dump" ]; then grep -oE 'https?://[^)> ]+' "$4" || true; exit 0; fi
          printf '%s\n' "$*" >> "$LYCHEE_LOG"
          if [ "${3:-}" != "--offline" ]; then shift 2; cat "$@" >> "$LYCHEE_LOG"; fi
        BASH
        log = File.join(tmpdir, "lychee.log")

        stdout, stderr, status = run_branch_hook(tmpdir, "LYCHEE_LOG" => log)

        expect(status).to be_success, stderr
        calls = File.read(log)
        expect(calls).to include("--config .lychee.toml --offline README.md")
        expect(calls).to include("http://127.0.0.1:9/new")
        expect(calls).not_to include("http://127.0.0.1:9/old")
        expect(stdout).to include("New remote links in README.md")
      end
    end

    it "fails a new broken remote link but not an untouched one with the real lychee" do
      skip "lychee 0.23.0 is not installed" unless lychee_023_installed?

      Dir.mktmpdir do |tmpdir|
        # The trailing comma is part of the Markdown link destination, so the
        # online pass must check that exact URL.
        write_branch_fixture(tmpdir, new_line: "[new](http://127.0.0.1:9/new,)")

        stdout, stderr, status = run_branch_hook(tmpdir)

        expect(status).not_to be_success
        output = stdout + stderr
        expect(output).to match(%r{\[ERROR\] http://127\.0\.0\.1:9/new, \|})
        expect(output).not_to include("http://127.0.0.1:9/old")
      end
    end

    it "fails new links to missing local and self-repo files with the real lychee" do
      skip "lychee 0.23.0 is not installed" unless lychee_023_installed?

      Dir.mktmpdir do |tmpdir|
        self_repo_link = "https://github.com/shakacode/react_on_rails/blob/main/missing-self.md"
        write_branch_fixture(tmpdir, new_line: "[gone](missing.md)\n[self](#{self_repo_link})")

        stdout, stderr, status = run_branch_hook(tmpdir)

        expect(status).not_to be_success
        output = stdout + stderr
        expect(output).to match(%r{\[ERROR\] file://\S*/missing\.md \|})
        expect(output).to match(%r{\[ERROR\] file://\S*/missing-self\.md \|})
      end
    end
  end

  def lychee_023_installed?
    stdout, _stderr, status = Open3.capture3("lychee", "--version")
    status.success? && stdout.strip == "lychee 0.23.0"
  rescue Errno::ENOENT
    false
  end

  # A Git repository whose origin/main has a broken remote link in README.md and
  # whose HEAD adds one more line to it.
  def write_branch_fixture(directory, new_line: "[new](http://127.0.0.1:9/new)")
    copy_hook_scripts(directory)
    File.write(File.join(directory, ".gitignore"), "tmp/\n")
    File.write(
      File.join(directory, ".lychee.toml"),
      "max_retries = 0\ntimeout = 2\npreprocess = { command = \"bin/lychee-self-repo-links\" }\n"
    )
    File.write(File.join(directory, "README.md"), "# Fixture\n\n[old](http://127.0.0.1:9/old)\n")
    git(directory, "init", "-q", "-b", "main")
    git(directory, "add", ".")
    git(directory, "commit", "-q", "-m", "base")
    git(directory, "update-ref", "refs/remotes/origin/main", "HEAD")
    File.write(File.join(directory, "README.md"), "#{new_line}\n", mode: "a")
    git(directory, "commit", "-q", "-am", "add a link")
  end

  def copy_hook_scripts(directory)
    hook_directory = File.join(directory, "bin/lefthook")
    FileUtils.mkdir_p([hook_directory, File.join(directory, "script/lib"), File.join(directory, "fake-bin")])
    %w[markdown-link-lint get-changed-files].each do |name|
      FileUtils.cp(File.join(repo_root, "bin/lefthook", name), hook_directory)
    end
    FileUtils.cp(File.join(repo_root, "script/lib/git-diff-base"), File.join(directory, "script/lib"))
    FileUtils.cp(File.join(repo_root, "bin/lychee-self-repo-links"), File.join(directory, "bin"))
    File.write(File.join(hook_directory, "ensure-mise"), ":\n")
  end

  def git(directory, *args)
    _stdout, stderr, status = Open3.capture3(
      { "GIT_CONFIG_GLOBAL" => File::NULL, "GIT_CONFIG_NOSYSTEM" => "1" },
      "git", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.com", *args,
      chdir: directory
    )
    raise "git #{args.join(' ')} failed: #{stderr}" unless status.success?
  end

  def run_branch_hook(directory, environment = {})
    path = [File.join(directory, "fake-bin"), ENV.fetch("PATH")].join(":")
    Open3.capture3(
      { "PATH" => path, "BASH_ENV" => nil, "BASE_REF" => "origin/main", "GIT_CONFIG_GLOBAL" => File::NULL,
        "GIT_CONFIG_NOSYSTEM" => "1" }.merge(environment),
      "bin/lefthook/markdown-link-lint",
      "branch",
      chdir: directory
    )
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
