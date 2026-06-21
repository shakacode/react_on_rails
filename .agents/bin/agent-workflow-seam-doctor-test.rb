#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for agent-workflow-seam-doctor.
# Run with: ruby .agents/bin/agent-workflow-seam-doctor-test.rb

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

SCRIPT = File.expand_path("agent-workflow-seam-doctor", __dir__)

class AgentWorkflowSeamDoctorTest < Minitest::Test
  REQUIRED_SEAM = {
    "Base branch" => "`main` (fetch and compare via `origin/main`).",
    "Pre-push local validation" => "`bin/ci-local`.",
    "CI change detector" => "`script/ci-changes-detector origin/main`.",
    "Hosted-CI trigger" => "`+ci-run-hosted` PR-comment command.",
    "Benchmark labels" => "`benchmark`.",
    "Follow-up issue prefix" => "`Follow-up:`.",
    "Changelog" => "`/CHANGELOG.md`, user-visible changes only.",
    "Lint / format" => "`bundle exec rake lint`, `bundle exec rake autofix`.",
    "Merge ledger" => "`script/pr-merge-ledger <PR> --strict`.",
    "Docs checks" => "`script/check-docs-sidebar`, `bin/check-links`.",
    "Tests" => "`bundle exec rake run_rspec`, `pnpm run test`.",
    "Build / type checks" => "`pnpm run build`, `pnpm run type-check`.",
    "Review gate" => "`claude-review`.",
    "Approval-exempt change categories" => "workflow, build-config, package-script.",
    "Coordination backend" => "public claim-comment fallback."
  }.freeze

  def with_repo
    Dir.mktmpdir("agent-workflow-seam-doctor-test") do |dir|
      FileUtils.mkdir_p(File.join(dir, ".agents/skills/example"))
      FileUtils.mkdir_p(File.join(dir, ".agents/workflows"))
      File.write(File.join(dir, "CHANGELOG.md"), "# Changelog\n")
      FileUtils.mkdir_p(File.join(dir, "script"))
      FileUtils.touch(File.join(dir, "script/check-docs-sidebar"))
      FileUtils.mkdir_p(File.join(dir, "bin"))
      FileUtils.touch(File.join(dir, "bin/check-links"))
      yield dir
    end
  end

  def write_agents(root, seam = REQUIRED_SEAM)
    body = +"# AGENTS.md\n\n"
    body << "## Agent Workflow Configuration\n\n"
    seam.each do |key, value|
      body << "- **#{key}**: #{value}\n"
    end
    body << "\n## Commands\n"
    File.write(File.join(root, "AGENTS.md"), body)
  end

  def write_skill(root, content)
    File.write(File.join(root, ".agents/skills/example/SKILL.md"), content)
  end

  def run_doctor(root, *)
    Open3.capture2e("ruby", SCRIPT, "--root", root, *)
  end

  def test_complete_seam_without_executable_placeholders_passes
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ---
        name: example
        ---

        Use the repo's follow-up issue prefix from `AGENTS.md`.
      MARKDOWN

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end

  def test_missing_required_seam_keys_fail
    with_repo do |root|
      seam = REQUIRED_SEAM.dup
      seam.delete("Tests")
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing Agent Workflow Configuration key: Tests"
    end
  end

  def test_executable_angle_placeholder_in_code_fence_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved executable placeholder"
      assert_includes out, "<follow-up prefix>"
    end
  end

  def test_prose_angle_placeholder_is_allowed
    with_repo do |root|
      write_agents(root)
      write_skill(root, "Use title `<follow-up prefix> Review feedback from PR #N` after resolving the seam.\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end
end
