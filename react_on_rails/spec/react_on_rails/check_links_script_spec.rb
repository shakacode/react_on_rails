# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"

RSpec.describe "bin/check-links" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "bin/check-links") }

  it "invokes lychee with the same inputs as the markdown link CI workflow" do
    Dir.mktmpdir do |tmpdir|
      args_file = File.join(tmpdir, "lychee.args")
      lychee_stub = File.join(tmpdir, "lychee")
      File.write(
        lychee_stub,
        <<~BASH
          #!/usr/bin/env bash
          printf '%s\\n' "$@" > "$LYCHEE_ARGS_FILE"
        BASH
      )
      FileUtils.chmod("+x", lychee_stub)

      _stdout, stderr, status = Open3.capture3(
        {
          "LYCHEE_ARGS_FILE" => args_file,
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH')}"
        },
        script_path,
        chdir: repo_root
      )

      expect(status).to be_success, stderr
      expect(File.read(args_file).lines.map(&:chomp)).to eq(expected_lychee_args)
    end
  end

  it "keeps the lychee invocation documented once" do
    script_content = File.read(script_path)
    executable_lines = script_content.lines.grep_v(/\A\s*(#|$)/).join

    expect(script_content.scan(/^# Word-split the globs/).size).to eq(1)
    expect(script_content.scan(/^exec lychee /).size).to eq(1)
    expect(executable_lines).not_to include("--files-from")
  end

  def expected_lychee_args
    Dir.chdir(repo_root) do
      ["--config", ".lychee.toml", "docs/"] + Dir["*.md"] + Dir["react_on_rails_pro/*.md"]
    end
  end
end
