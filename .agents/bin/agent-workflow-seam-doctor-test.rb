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
      FileUtils.mkdir_p(File.join(dir, ".agents/bin"))
      yield dir
    end
  end

  def write_portable_contract(root)
    body = +"# AGENTS.md\n\n"
    body << "## Agent Workflow Configuration\n\n"
    body << "Portable shared skills resolve this repo's commands and policy through:\n\n"
    body << "- **Commands** — run `.agents/bin/<name>` (`setup`, `validate`, `test`, `lint`, "
    body << "`build`, `docs`, `ci-detect`); see [`.agents/bin/README.md`](.agents/bin/README.md).\n"
    body << "- **Policy / config** — [`.agents/agent-workflow.yml`](.agents/agent-workflow.yml).\n"
    body << "\n## Commands\n"
    File.write(File.join(root, "AGENTS.md"), body)
    write_agent_workflow_config(root)
    write_agent_workflow_scripts(root)
  end

  def write_agent_workflow_config(root, overrides = {})
    config = {
      "base_branch" => "main",
      "hosted_ci_trigger" => "+ci-* PR-comment commands",
      "ci_parity_environment" => "No dedicated act/local runner image; use bin/ci-local.",
      "secret_redaction_patterns" => "Redact SECRET, TOKEN, KEY, PASSWORD, and LICENSE.",
      "trusted_github_actor_boundary" => ".agents/trusted-github-actors.yml does not trust bots by default.",
      "benchmark_labels" => "benchmark, benchmark-core",
      "follow_up_prefix" => AgentWorkflowSeamDoctor::FOLLOW_UP_PREFIX,
      "changelog" => "/CHANGELOG.md, user-visible changes only.",
      "merge_ledger" => "script/pr-merge-ledger <PR> --strict",
      "review_gate" => "claude-review",
      "approval_exempt" => "focused trusted workflow/build/dependency edits",
      "coordination_backend" => "private shakacode/agent-coordination"
    }.merge(overrides)

    File.write(File.join(root, ".agents/agent-workflow.yml"), YAML.dump(config))
  end

  def write_agent_workflow_scripts(root, omit: [])
    AgentWorkflowSeamDoctor::REQUIRED_COMMAND_SCRIPTS.each do |script_name|
      next if omit.include?(script_name)

      path = File.join(root, ".agents/bin", script_name)
      File.write(path, "#!/usr/bin/env bash\nexit 0\n")
      FileUtils.chmod("+x", path)
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

  def test_portable_contract_without_inline_keys_passes
    with_repo do |root|
      write_portable_contract(root)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end

  def test_portable_contract_missing_script_fails
    with_repo do |root|
      write_portable_contract(root)
      FileUtils.rm_f(File.join(root, ".agents/bin/lint"))
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing agent workflow command script: .agents/bin/lint"
    end
  end

  def test_portable_contract_non_executable_script_fails
    with_repo do |root|
      write_portable_contract(root)
      FileUtils.chmod("-x", File.join(root, ".agents/bin/lint"))
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "agent workflow command script is not executable: .agents/bin/lint"
    end
  end

  def test_portable_contract_invalid_yaml_fails
    with_repo do |root|
      write_portable_contract(root)
      File.write(File.join(root, ".agents/agent-workflow.yml"), "base_branch: [\n")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "invalid .agents/agent-workflow.yml"
    end
  end

  def test_portable_contract_yaml_list_not_mapping_fails
    with_repo do |root|
      write_portable_contract(root)
      File.write(File.join(root, ".agents/agent-workflow.yml"), "- item1\n- item2\n")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, ".agents/agent-workflow.yml must be a mapping"
    end
  end

  def test_portable_contract_missing_yaml_key_fails
    with_repo do |root|
      write_portable_contract(root)
      write_agent_workflow_config(root, "follow_up_prefix" => nil)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing agent workflow config key: follow_up_prefix"
      refute_includes out, "invalid agent workflow config value for key: follow_up_prefix"
    end
  end

  def test_portable_contract_allows_empty_collection_values
    with_repo do |root|
      write_portable_contract(root)
      write_agent_workflow_config(root, "benchmark_labels" => [])
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end

  def test_portable_contract_unresolved_yaml_value_fails
    with_repo do |root|
      write_portable_contract(root)
      write_agent_workflow_config(root, "benchmark_labels" => "<benchmark labels>")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved agent workflow config value for key: benchmark_labels"
    end
  end

  def test_portable_contract_missing_agents_md_pointer_fails
    with_repo do |root|
      body = +"# AGENTS.md\n\n"
      body << "## Agent Workflow Configuration\n\n"
      body << "See `.agents/agent-workflow.yml`.\n"
      body << "\n## Commands\n"
      File.write(File.join(root, "AGENTS.md"), body)
      write_agent_workflow_config(root)
      write_agent_workflow_scripts(root)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "AGENTS.md section must point to .agents/bin/README.md and .agents/bin/<name>"
    end
  end

  def test_portable_contract_follow_up_prefix_must_be_literal_prefix
    with_repo do |root|
      write_portable_contract(root)
      write_agent_workflow_config(
        root,
        "follow_up_prefix" => "Follow-up: (default to no new issue; see policy)"
      )
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "invalid agent workflow config value for key: follow_up_prefix"
    end
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

  def test_missing_secret_redaction_patterns_key_fails
    with_repo do |root|
      seam = REQUIRED_SEAM.dup
      seam.delete("Secret redaction patterns")
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing Agent Workflow Configuration key: Secret redaction patterns"
    end
  end

  def test_unresolved_required_seam_key_value_fails
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "Secret redaction patterns" => "<repo-specific CI parity redaction patterns>"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved Agent Workflow Configuration value for key: Secret redaction patterns"
    end
  end

  def test_unresolved_extra_redaction_command_placeholder_fails
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "Optional redaction helper" => "<secret redaction command>"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved Agent Workflow Configuration value for key: Optional redaction helper"
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
        "CI parity environment" => "<CI parity command, runner image, reproduction guide, or \"n/a\">",
        "Benchmark labels" => "<benchmark labels, or \"n/a\">"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved Agent Workflow Configuration value for key: CI change detector"
      assert_includes out, "unresolved Agent Workflow Configuration value for key: CI parity environment"
      assert_includes out, "unresolved Agent Workflow Configuration value for key: Benchmark labels"
    end
  end

  def test_standalone_ci_parity_placeholder_in_seam_value_fails
    with_repo do |root|
      seam = REQUIRED_SEAM.merge("CI parity environment" => "<runner image>")
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved Agent Workflow Configuration value for key: CI parity environment"
    end
  end

  def test_ci_parity_placeholder_variants_in_seam_value_fail
    with_repo do |root|
      [
        "<runner image, or \"n/a\">",
        "<runner image for act>",
        "<reproduction guide URL>",
        "<GitHub runner image>",
        "<local reproduction guide URL>",
        "<runner image:>",
        "<reproduction guide: >",
        "<runner image, optional: value>",
        "<runner image optional: value>"
      ].each do |placeholder|
        seam = REQUIRED_SEAM.merge("CI parity environment" => placeholder)
        write_agents(root, seam)
        write_skill(root, "No commands here.\n")

        out, status = run_doctor(root)

        refute status.success?, placeholder
        assert_includes out, "unresolved Agent Workflow Configuration value for key: CI parity environment"
      end
    end
  end

  def test_filled_ci_parity_command_value_passes
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "CI parity environment" => "<CI parity command: bin/ci-parity>"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_filled_ci_parity_runner_image_with_prefix_value_passes
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "CI parity environment" => "act with <GitHub runner image: ghcr.io/catthehacker/ubuntu:act-22.04>"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_filled_ci_parity_runner_image_value_passes
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "CI parity environment" => "act with <runner image: ghcr.io/catthehacker/ubuntu:act-22.04>"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_filled_ci_parity_reproduction_guide_qualified_value_passes
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "CI parity environment" => "see <reproduction guide URL: https://wiki.example.com/ci>"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_plural_runner_images_phrase_is_not_a_ci_parity_placeholder
    with_repo do |root|
      seam = REQUIRED_SEAM.merge(
        "CI parity environment" => "docs mention <runner images> generally"
      )
      write_agents(root, seam)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
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

  def test_executable_ci_parity_placeholder_in_code_fence_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        act -P ubuntu-latest=<runner image>
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<runner image>"
    end
  end

  def test_filled_ci_parity_runner_image_in_code_fence_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        act -P ubuntu-latest=<runner image: ghcr.io/catthehacker/ubuntu:act-22.04>
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<runner image: ghcr.io/catthehacker/ubuntu:act-22.04>"
    end
  end

  def test_executable_filled_ci_parity_command_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        <CI parity command: bin/ci-parity>
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<CI parity command: bin/ci-parity>"
    end
  end

  def test_inline_ci_parity_placeholder_command_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, "Run `act -P ubuntu-latest=<reproduction guide URL>`.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<reproduction guide URL>"
    end
  end

  def test_executable_compound_placeholder_is_reported_once
    with_repo do |root|
      write_agents(root)
      write_skill(root, <<~MARKDOWN)
        ```bash
        echo <hosted CI runner image>
        ```
      MARKDOWN

      out, status = run_doctor(root)

      refute status.success?
      assert_equal 1, out.scan("<hosted CI runner image>").length
    end
  end

  def test_inline_act_event_command_placeholder_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, "Run `act pull_request -P ubuntu-latest=<runner image>`.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<runner image>"
    end
  end

  def test_inline_bare_act_placeholder_fails
    with_repo do |root|
      write_agents(root)
      write_skill(root, "Run `act <runner image>`.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<runner image>"
    end
  end

  def test_inline_act_prose_does_not_make_placeholder_executable
    with_repo do |root|
      write_agents(root)
      write_skill(root, "Use `act on this finding <runner image>` when documenting parity.\n")

      out, status = run_doctor(root)

      assert status.success?, out
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

class AgentWorkflowSeamDoctorEncodingTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

  def test_non_ascii_agents_md_parses_under_ascii_locale
    with_repo do |root|
      write_agents(root)
      agents_path = File.join(root, "AGENTS.md")
      body = File.read(agents_path)
      # A real AGENTS.md carries non-ASCII bytes (em dashes, arrows). Reading it
      # under a non-UTF-8 locale must not crash the config parser.
      body.sub!("# AGENTS.md\n", "# AGENTS.md\n\nReact on Rails → SSR overview.\n")
      File.write(agents_path, body)
      write_skill(root, "No commands here.\n")

      out, status = Open3.capture2e(
        { "LC_ALL" => "C", "LANG" => "C" }, "ruby", SCRIPT, "--root", root
      )

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end
end
