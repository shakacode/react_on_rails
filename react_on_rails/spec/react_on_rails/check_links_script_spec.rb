# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "bin/check-links" do
  utf8_collation_locale = "en_US.UTF-8"

  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "bin/check-links") }

  it "invokes lychee with deterministically ordered CI inputs under UTF-8 collation" do
    Dir.mktmpdir do |tmpdir|
      write_controlled_markdown_files(tmpdir)
      args_file = File.join(tmpdir, "lychee.args")
      write_executable(
        File.join(tmpdir, "lychee"),
        <<~BASH
          printf '%s\\n' "$@" > "$LYCHEE_ARGS_FILE"
        BASH
      )

      c_order, c_stderr, c_status = markdown_glob_order(tmpdir, "C")
      utf8_order, utf8_stderr, utf8_status = markdown_glob_order(tmpdir, utf8_collation_locale)

      expect(c_status).to be_success, c_stderr
      expect(c_order).to eq(["AGENTS.md", "AGENTS_USER_GUIDE.md"])
      expect(utf8_status).to be_success, utf8_stderr
      expect(utf8_stderr).to be_empty
      expect(utf8_order).to eq(["AGENTS_USER_GUIDE.md", "AGENTS.md"])

      _stdout, stderr, status = Open3.capture3(
        {
          "LANG" => utf8_collation_locale,
          "LC_ALL" => utf8_collation_locale,
          "LYCHEE_ARGS_FILE" => args_file,
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH')}"
        },
        script_path,
        chdir: tmpdir
      )

      expect(status).to be_success, stderr
      expect(File.read(args_file).lines.map(&:chomp)).to eq(
        [
          "--config",
          ".lychee.toml",
          "docs/",
          "AGENTS.md",
          "AGENTS_USER_GUIDE.md",
          "react_on_rails_pro/README.md"
        ]
      )
    end
  end

  it "does not invoke lychee when sorting the expanded inputs fails" do
    Dir.mktmpdir do |tmpdir|
      write_controlled_markdown_files(tmpdir)
      lychee_invocation = File.join(tmpdir, "lychee.invoked")
      write_executable(File.join(tmpdir, "sort"), "exit 42\n")
      write_executable(File.join(tmpdir, "lychee"), "touch \"$LYCHEE_INVOCATION\"\n")

      _stdout, stderr, status = Open3.capture3(
        {
          "LC_ALL" => "C",
          "LYCHEE_INVOCATION" => lychee_invocation,
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH')}"
        },
        script_path,
        chdir: tmpdir
      )

      expect(status.exitstatus).to eq(42), stderr
      expect(File).not_to exist(lychee_invocation)
    end
  end

  it "keeps the lychee invocation documented once" do
    script_content = File.read(script_path)
    executable_lines = script_content.lines.grep_v(/\A\s*(#|$)/).join

    expect(script_content.scan(/^# Expand the same globs/).size).to eq(1)
    expect(script_content.scan(/^exec lychee /).size).to eq(1)
    expect(executable_lines).not_to include("--files-from")
  end

  def write_controlled_markdown_files(directory)
    File.write(File.join(directory, "AGENTS.md"), "")
    File.write(File.join(directory, "AGENTS_USER_GUIDE.md"), "")
    FileUtils.mkdir_p(File.join(directory, "react_on_rails_pro"))
    File.write(File.join(directory, "react_on_rails_pro", "README.md"), "")
  end

  def write_executable(path, body)
    File.write(path, "#!/usr/bin/env bash\n#{body}")
    FileUtils.chmod("+x", path)
  end

  def markdown_glob_order(directory, locale)
    stdout, stderr, status = Open3.capture3(
      { "LANG" => locale, "LC_ALL" => locale },
      "bash",
      "-c",
      "printf '%s\\n' *.md",
      chdir: directory
    )
    [stdout.lines.map(&:chomp), stderr, status]
  end
end
