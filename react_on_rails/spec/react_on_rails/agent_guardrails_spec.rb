# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/agent_guardrails"
require "tmpdir"
require "json"

module ReactOnRails
  RSpec.describe AgentGuardrails do
    around do |example|
      Dir.mktmpdir("ror-agent-guardrails") do |dir|
        @app_root = dir
        example.run
      end
    end

    def settings
      JSON.parse(File.read(File.join(@app_root, ".claude/settings.json")))
    end

    def rsc_hook_commands
      settings.dig("hooks", "PostToolUse").flat_map { |entry| entry["hooks"] }
              .map { |hook| hook["command"] }
              .select { |command| command.include?("rsc-app-safety-check.sh") }
    end

    it "creates the skill and hook and registers the hook" do
      actions = described_class.install(@app_root)

      expect(File.file?(File.join(@app_root, ".claude/skills/rsc-app-safety/SKILL.md"))).to be true
      hook_path = File.join(@app_root, ".claude/hooks/rsc-app-safety-check.sh")
      expect(File.file?(hook_path)).to be true
      expect(File.stat(hook_path).mode & 0o111).not_to eq(0) # executable
      expect(rsc_hook_commands.size).to eq(1)
      expect(actions).to include(a_string_matching(/created.*SKILL\.md/))
    end

    it "is idempotent — a second run changes nothing and does not duplicate the hook" do
      described_class.install(@app_root)
      actions = described_class.install(@app_root)

      expect(actions).to all(match(/unchanged/))
      expect(rsc_hook_commands.size).to eq(1)
    end

    it "merges into an existing settings.json without clobbering other hooks" do
      claude_dir = File.join(@app_root, ".claude")
      FileUtils.mkdir_p(claude_dir)
      existing = {
        "hooks" => {
          "PostToolUse" => [
            { "matcher" => "Edit|Write", "hooks" => [{ "type" => "command", "command" => "bin/existing-hook" }] }
          ]
        }
      }
      File.write(File.join(claude_dir, "settings.json"), JSON.pretty_generate(existing))

      described_class.install(@app_root)

      all_commands = settings.dig("hooks", "PostToolUse").flat_map { |entry| entry["hooks"] }.map { |h| h["command"] }
      expect(all_commands).to include("bin/existing-hook")
      expect(rsc_hook_commands.size).to eq(1)
      # Both hooks share the single Edit|Write matcher entry rather than duplicating it.
      expect(settings.dig("hooks", "PostToolUse").size).to eq(1)
    end

    it "raises rather than clobbering an unparseable settings.json" do
      claude_dir = File.join(@app_root, ".claude")
      FileUtils.mkdir_p(claude_dir)
      File.write(File.join(claude_dir, "settings.json"), "{ not valid json ")

      expect { described_class.install(@app_root) }.to raise_error(described_class::Error, /not valid JSON/)
    end
  end
end
