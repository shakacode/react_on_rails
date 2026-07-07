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

  it "leaves agent, editor, and Codex workspace bin links alone" do
    Dir.mktmpdir do |tmpdir|
      ignored_links = {
        ".agents" => "agent-tool",
        ".cursor" => "editor-tool",
        ".Codex" => "codex-upper-tool",
        ".codex" => "codex-lower-tool"
      }.map do |dir, tool|
        File.join(tmpdir, "#{dir}/node_modules/.bin/#{tool}")
      end
      ignored_links.each do |link_path|
        FileUtils.mkdir_p(File.dirname(link_path))
        File.symlink("../tool/bin/tool", link_path)
      end

      stdout, stderr, status = run_cleaner(tmpdir)

      expect(status).to be_success, stderr
      expect(stderr).to be_empty
      ignored_links.each do |link_path|
        expect(File.symlink?(link_path)).to be(true)
      end
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
      expected_pattern = /
        if\s+!\s+"\$STALE_PNPM_BIN_LINK_CLEANER"\s+"\$dir";\s+then
        \s+print_error\s+"Failed\ to\ clean\ stale\ pnpm\ bin\ links\ in\ \$name"
        \s+exit\s+1
        \s+fi
      /x

      expect(setup_script).to match(expected_pattern)
    end
  end

  describe "conductor-setup.sh" do
    let(:conductor_setup_script_path) { File.join(repo_root, "conductor-setup.sh") }

    it "cleans stale pnpm bin links before installing JavaScript dependencies" do
      conductor_setup_script = File.read(conductor_setup_script_path)

      expect(conductor_setup_script).to match(
        %r{run_cmd \./script/clean-stale-pnpm-bin-links \.\s+run_cmd pnpm install}
      )
    end
  end
end
