#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for agent-workflow-seam-doctor.
# Run with: ruby .agents/bin/agent-workflow-seam-doctor-test.rb

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

SCRIPT = File.expand_path("agent-workflow-seam-doctor", __dir__)
load SCRIPT

module AgentWorkflowSeamDoctorTestHelpers
  REQUIRED_SEAM = AgentWorkflowSeamDoctor::REQUIRED_KEYS.to_h do |key|
    [key, "configured #{key.downcase}."]
  end.freeze

  def with_repo
    Dir.mktmpdir("agent-workflow-seam-doctor-test") do |dir|
      FileUtils.mkdir_p(File.join(dir, ".agents/skills/example"))
      FileUtils.mkdir_p(File.join(dir, ".agents/workflows"))
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

  def write_workflow(root, content)
    File.write(File.join(root, ".agents/workflows/example.md"), content)
  end

  def run_doctor(root, *)
    Open3.capture2e("ruby", SCRIPT, "--root", root, *)
  end
end

class AgentWorkflowSeamDoctorConfigTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

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

  def test_missing_seam_section_fails
    with_repo do |root|
      File.write(File.join(root, "AGENTS.md"), "# AGENTS.md\n\n## Commands\n")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing AGENTS.md section: Agent Workflow Configuration"
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

  def test_unresolved_seam_value_fails
    with_repo do |root|
      seam = REQUIRED_SEAM.merge("Base branch" => "<main branch>.")
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved Agent Workflow Configuration value for key: Base branch"
    end
  end

  def test_wrapped_seam_values_pass
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "Tests" => "`bundle exec rake run_rspec`,\n  `pnpm run test`, and targeted e2e commands."
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end
end

class AgentWorkflowSeamDoctorPlaceholderTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

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

  def test_executable_placeholder_for_broader_seam_key_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        <docs checks>
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<docs checks>"
    end
  end

  def test_executable_placeholder_in_titled_code_fence_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash title="copyable"
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end

  def test_non_executable_fence_placeholder_is_allowed
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```text
        <follow-up prefix>
        ```
      MARKDOWN

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_task_input_placeholder_in_command_is_allowed
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        bundle exec rspec <test_file>
        ```
      MARKDOWN

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_workflow_placeholder_is_scanned
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")
      write_workflow(root, "`gh issue create --title \"<follow-up prefix> Review\"`\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, ".agents/workflows/example.md"
    end
  end

  def test_shared_root_placeholder_is_scanned
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")

      Dir.mktmpdir("agent-workflow-shared-root") do |shared_root|
        FileUtils.mkdir_p(File.join(shared_root, "skills/shared"))
        File.write(File.join(shared_root, "skills/shared/SKILL.md"), <<~MARKDOWN)
          ```bash
          gh issue create --title "<follow-up prefix> Review"
          ```
        MARKDOWN

        out, status = run_doctor(root, "--shared", shared_root)

        refute status.success?
        assert_includes out, "skills/shared/SKILL.md"
      end
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
