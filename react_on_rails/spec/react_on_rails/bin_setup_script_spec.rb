# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "pnpm bin cleanup setup support" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "script/clean-stale-pnpm-bin-links") }

  def run_cleaner(root)
    Open3.capture3(script_path, root)
  end

  it "removes broken generated pnpm bin symlinks before install relinks bins" do
    Dir.mktmpdir do |tmpdir|
      stale_link = File.join(tmpdir, "react_on_rails_pro/spec/dummy/node_modules/.bin/node")
      FileUtils.mkdir_p(File.dirname(stale_link))
      File.symlink("../@sentry/node/bin/node", stale_link)

      stdout, stderr, status = run_cleaner(tmpdir)

      expect(status).to be_success, stderr
      expect(stderr).to be_empty
      expect(File.symlink?(stale_link)).to be(false)
      expect(stdout).to include(
        "Removed stale pnpm bin link: react_on_rails_pro/spec/dummy/node_modules/.bin/node"
      )
    end
  end

  it "keeps valid generated pnpm bin symlinks" do
    Dir.mktmpdir do |tmpdir|
      target = File.join(tmpdir, "app/node_modules/tool/bin/tool")
      valid_link = File.join(tmpdir, "app/node_modules/.bin/tool")
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.mkdir_p(File.dirname(valid_link))
      File.write(target, "#!/usr/bin/env node\n")
      File.symlink("../tool/bin/tool", valid_link)

      stdout, stderr, status = run_cleaner(tmpdir)

      expect(status).to be_success, stderr
      expect(stderr).to be_empty
      expect(File.symlink?(valid_link)).to be(true)
      expect(File.exist?(valid_link)).to be(true)
      expect(stdout).to be_empty
    end
  end

  it "leaves agent and editor workspace bin links alone" do
    Dir.mktmpdir do |tmpdir|
      stale_agent_link = File.join(tmpdir, ".agents/node_modules/.bin/tool")
      stale_editor_link = File.join(tmpdir, ".cursor/node_modules/.bin/tool")
      FileUtils.mkdir_p(File.dirname(stale_agent_link))
      FileUtils.mkdir_p(File.dirname(stale_editor_link))
      File.symlink("../tool/bin/tool", stale_agent_link)
      File.symlink("../tool/bin/tool", stale_editor_link)

      stdout, stderr, status = run_cleaner(tmpdir)

      expect(status).to be_success, stderr
      expect(stderr).to be_empty
      expect(File.symlink?(stale_agent_link)).to be(true)
      expect(File.symlink?(stale_editor_link)).to be(true)
      expect(stdout).to be_empty
    end
  end

  it "does not rely on GNU-only find depth flags" do
    expect(File.read(script_path)).not_to match(/\s-(?:min|max)depth\b/)
  end

  describe "bin/setup" do
    let(:setup_script_path) { File.join(repo_root, "bin/setup") }

    it "reports cleaner failures with setup's friendly error path" do
      setup_script = File.read(setup_script_path)
      expected_block = [
        '    if ! "$STALE_PNPM_BIN_LINK_CLEANER" "$dir"; then',
        '      print_error "Failed to clean stale pnpm bin links in $name"',
        "      exit 1",
        "    fi"
      ].join("\n")

      expect(setup_script).to include(expected_block)
    end
  end
end
