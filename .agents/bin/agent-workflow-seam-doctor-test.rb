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

  def test_nested_bullet_seam_values_pass
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "Tests" => "\n  - **Unit**: `bundle exec rake run_rspec:gem`\n  - **E2E**: `pnpm test:e2e`"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_embedded_placeholder_in_wrapped_seam_value_fails
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "Tests" => "\n  - unit: <unit command>\n  - e2e: `pnpm test:e2e`"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved Agent Workflow Configuration value for key: Tests"
    end
  end

  def test_template_style_placeholder_in_seam_value_fails
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "CI change detector" => "<CI change detector command, or \"n/a\">",
        "Benchmark labels" => "<benchmark labels, or \"n/a\">"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved Agent Workflow Configuration value for key: CI change detector"
      assert_includes out, "unresolved Agent Workflow Configuration value for key: Benchmark labels"
    end
  end

  def test_blank_separator_stops_wrapped_seam_value
    with_repo do |root|
      write_agents(root)
      agents_path = File.join(root, "AGENTS.md")
      body = File.read(agents_path)
      body.sub!(
        "- **Tests**: configured tests.\n",
        "- **Tests**: configured tests.\n\n  orphaned indentation after the key.\n"
      )
      File.write(agents_path, body)
      write_skill(root, "No commands here.\n")

      config = AgentWorkflowSeamDoctor.parse_config(File.read(agents_path))

      assert_equal "configured tests.", config.fetch("Tests")
    end
  end

  def test_json_output_format
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root, "--json")

      assert status.success?, out
      parsed = JSON.parse(out)
      assert_equal "PASS", parsed.fetch("status")
      assert_empty parsed.fetch("issues")
    end
  end

  def test_json_output_format_on_failure
    with_repo do |root|
      File.write(File.join(root, "AGENTS.md"), "# AGENTS.md\n\n## Commands\n")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root, "--json")

      refute status.success?
      parsed = JSON.parse(out)
      assert_equal "FAIL", parsed.fetch("status")
      refute_empty parsed.fetch("issues")
    end
  end

  def test_not_applicable_seam_value_passes
    with_repo do |root|
      seam = REQUIRED_SEAM.merge("Coordination backend" => "n/a")
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
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
end

class AgentWorkflowSeamDoctorFenceTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

  def test_executable_placeholder_in_tilde_code_fence_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ~~~bash
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ~~~
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end

  def test_executable_placeholder_in_long_code_fence_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ````bash
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ````
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end

  def test_mismatched_fence_delimiter_does_not_close_executable_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        ~~~
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end
end

class AgentWorkflowSeamDoctorFenceLengthTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

  def test_shorter_closing_fence_does_not_close_long_executable_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ````bash
        ```
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ````
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end

  def test_shorter_closing_tilde_fence_does_not_close_long_tilde_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ~~~~bash
        ~~~
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ~~~~
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end

  def test_longer_closing_fence_closes_long_executable_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ````bash
        echo ok
        `````
        <follow-up prefix>
      MARKDOWN

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_longer_closing_tilde_fence_closes_long_tilde_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ~~~~bash
        echo ok
        ~~~~~
        <follow-up prefix>
      MARKDOWN

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_closing_fence_with_info_string_stays_inside_executable_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ````bash
        ````bash
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ````
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end

  def test_crlf_closing_fence_closes_executable_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, "```bash\r\necho ok\r\n```\r\n<follow-up prefix>\r\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_spaced_info_string_on_long_non_executable_fence_is_not_executable
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```` markdown
        <follow-up prefix>
        ````
      MARKDOWN

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_spaced_info_string_on_long_executable_fence_is_executable
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```` bash
        gh issue create --title "<follow-up prefix> Review feedback from PR #123"
        ````
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<follow-up prefix>"
    end
  end
end

class AgentWorkflowSeamDoctorFenceContentTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

  def test_four_space_indented_fence_does_not_open_executable_fence
    with_repo do |root|
      write_agents(root)
      write_skill(root, "    ```bash\n    gh issue create --title \"<follow-up prefix> Review feedback\"\n    ```\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_inline_code_in_executable_fence_is_not_reported_twice
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        `gh issue create --title "<follow-up prefix> Review"`
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_equal 1, out.scan("unresolved executable placeholder").length
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

  def test_invalid_utf8_markdown_does_not_crash_scanner
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")
      File.binwrite(File.join(root, ".agents/skills/example/invalid.md"), "Latin-1 byte: \xE9\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end
end

class AgentWorkflowSeamDoctorSharedRootTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

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
        assert_includes out, "[shared]"
        assert_includes out, "skills/shared/SKILL.md"
      end
    end
  end

  def test_missing_shared_root_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")
      missing_root = File.join(root, "missing-shared-root")

      out, status = run_doctor(root, "--shared", missing_root)

      refute status.success?
      assert_includes out, "missing shared root: #{missing_root}"
    end
  end

  def test_shared_root_without_skill_or_workflow_markdown_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")

      Dir.mktmpdir("agent-workflow-shared-root") do |shared_root|
        File.write(File.join(shared_root, "README.md"), "Shared pack docs.\n")

        out, status = run_doctor(root, "--shared", shared_root)

        refute status.success?
        assert_includes out, "shared root has no skill/workflow Markdown: #{shared_root}"
      end
    end
  end

  def test_shared_root_general_markdown_is_not_scanned
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")

      Dir.mktmpdir("agent-workflow-shared-root") do |shared_root|
        File.write(File.join(shared_root, "README.md"), "`gh issue create --title \"<follow-up prefix>\"`\n")
        FileUtils.mkdir_p(File.join(shared_root, "skills/clean"))
        File.write(File.join(shared_root, "skills/clean/SKILL.md"), "Clean shared skill.\n")

        out, status = run_doctor(root, "--shared", shared_root)

        assert status.success?, out
      end
    end
  end

  def test_installed_skill_root_is_scanned
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")

      Dir.mktmpdir("agent-workflow-installed-skills") do |shared_root|
        FileUtils.mkdir_p(File.join(shared_root, "shared"))
        File.write(File.join(shared_root, "shared/SKILL.md"), <<~MARKDOWN)
          ```bash
          gh issue create --title "<follow-up prefix> Review"
          ```
        MARKDOWN

        out, status = run_doctor(root, "--shared", shared_root)

        refute status.success?
        assert_includes out, "shared/SKILL.md"
      end
    end
  end

  def test_multiple_shared_roots_are_scanned
    with_repo do |root|
      write_agents(root)
      write_skill(root, "No commands here.\n")

      Dir.mktmpdir("agent-workflow-shared-root-a") do |shared_root_a|
        Dir.mktmpdir("agent-workflow-shared-root-b") do |shared_root_b|
          FileUtils.mkdir_p(File.join(shared_root_a, "skills/clean"))
          FileUtils.mkdir_p(File.join(shared_root_b, "skills/failing"))
          File.write(File.join(shared_root_a, "skills/clean/SKILL.md"), "Clean shared skill.\n")
          File.write(File.join(shared_root_b, "skills/failing/SKILL.md"), <<~MARKDOWN)
            ```bash
            gh issue create --title "<follow-up prefix> Review"
            ```
          MARKDOWN

          out, status = run_doctor(root, "--shared", shared_root_a, "--shared", shared_root_b)

          refute status.success?
          assert_includes out, "skills/failing/SKILL.md"
        end
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
