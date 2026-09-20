#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

SCRIPT = File.expand_path("agent-workflow-seam-doctor", __dir__)
load SCRIPT

class ShakaSeamContractTest < Minitest::Test
  SHAKA_POLICY = {
    "version" => 1,
    "base_branch" => "main",
    "review" => {
      "required" => "meaningful_changes",
      "check" => "claude-review"
    },
    "merge" => { "preference" => "ask" }
  }.freeze

  def with_repo
    Dir.mktmpdir("shaka-seam-contract-test") do |dir|
      FileUtils.mkdir_p(File.join(dir, ".agents/bin"))
      FileUtils.mkdir_p(File.join(dir, ".agents/skills/example"))
      FileUtils.mkdir_p(File.join(dir, ".agents/workflows"))
      yield dir
    end
  end

  def write_shaka_contract(root)
    File.write(File.join(root, "AGENTS.md"), <<~MARKDOWN)
      # AGENTS.md

      #{AgentWorkflowSeamDoctor::POINTER_SECTION}

      ## Commands
    MARKDOWN
    File.write(File.join(root, ".agents/agent-workflow.yml"), "#{SHAKA_POLICY.to_yaml}\n")
    File.write(File.join(root, ".agents/bin/README.md"), <<~MARKDOWN)
      # Agent Workflow Scripts

      | Script | Purpose | This repo runs |
      | --- | --- | --- |
      | `validate` | Pre-push gate | `bundle exec rake` |
      | `test` | Run tests | `bundle exec rspec` |
    MARKDOWN
    %w[validate test].each do |name|
      path = File.join(root, ".agents/bin", name)
      File.write(path, <<~BASH)
        #!/usr/bin/env bash
        set -euo pipefail
        cd "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
        exec bundle exec #{name == 'validate' ? 'rake' : 'rspec'} "$@"
      BASH
      File.chmod(0o755, path)
    end
  end

  def run_doctor(root)
    Open3.capture2e("ruby", SCRIPT, "--root", root)
  end

  def test_shaka_typed_seam_passes
    with_repo do |root|
      write_shaka_contract(root)
      File.write(File.join(root, ".agents/skills/example/SKILL.md"), "Run `.agents/bin/validate`.\n")

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end

  def test_shaka_seam_missing_review_fails
    with_repo do |root|
      write_shaka_contract(root)
      File.write(
        File.join(root, ".agents/agent-workflow.yml"),
        YAML.dump(SHAKA_POLICY.except("review"))
      )

      out, status = run_doctor(root)

      refute status.success?, out
      assert_includes out, "missing policy key: review"
    end
  end
end
