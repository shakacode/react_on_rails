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
  POLICY = {
    "base_branch" => "main",
    "follow_up_prefix" => "Follow-up:",
    "review_gate" => "AI reviewers are advisory; merge gate is green checks plus resolved threads.",
    "approval_exempt" => "docs and workflow text when portable.",
    "coordination_backend" => "public claim-comment fallback.",
    "changelog" => "CHANGELOG.md; user-visible changes only.",
    "benchmark_labels" => "n/a",
    "merge_ledger" => "n/a",
    "ci_parity_environment" => "n/a",
    "hosted_ci_trigger" => "n/a",
    "ci_change_detector" => "n/a"
  }.freeze

  def with_repo
    Dir.mktmpdir("agent-workflow-seam-doctor-test") do |dir|
      FileUtils.mkdir_p(File.join(dir, ".agents/bin"))
      FileUtils.mkdir_p(File.join(dir, ".agents/skills/example"))
      FileUtils.mkdir_p(File.join(dir, ".agents/workflows"))
      yield dir
    end
  end

  def write_agents(root, section = AgentWorkflowSeamDoctor::POINTER_SECTION)
    File.write(File.join(root, "AGENTS.md"), "# AGENTS.md\n\n#{section}\n\n## Commands\n")
  end

  def write_policy(root, values = POLICY)
    File.write(File.join(root, ".agents/agent-workflow.yml"), "#{values.to_yaml}\n")
  end

  def write_bin_readme(root)
    File.write(File.join(root, ".agents/bin/README.md"), <<~MARKDOWN)
      # Agent Workflow Scripts

      | Script | Purpose | This repo runs |
      | --- | --- | --- |
      | `validate` | Pre-push gate | `bundle exec rake` |
      | `test` | Run tests | `bundle exec rspec` |
    MARKDOWN
  end

  def write_script(root, name, body = "exec bundle exec #{name}\n")
    path = File.join(root, ".agents/bin", name)
    File.write(path, <<~BASH)
      #!/usr/bin/env bash
      set -euo pipefail
      cd "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
      #{body}
    BASH
    File.chmod(0o755, path)
    path
  end

  def write_valid_binstub_contract(root)
    write_agents(root)
    write_policy(root)
    write_bin_readme(root)
    write_script(root, "validate", "exec bundle exec rake\n")
    write_script(root, "test", "exec bundle exec rspec \"$@\"\n")
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

  def executable_available?(executable)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
      path = File.join(directory, executable)
      File.file?(path) && File.executable?(path)
    end
  end
end

class AgentWorkflowSeamDoctorBinstubContractTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

  def test_complete_binstub_contract_passes
    with_repo do |root|
      write_valid_binstub_contract(root)
      write_skill(root, <<~MARKDOWN)
        ---
        name: example
        ---

        Run `.agents/bin/validate` before pushing.
      MARKDOWN

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end

  def test_missing_pointer_section_fails
    with_repo do |root|
      write_policy(root)
      write_bin_readme(root)
      write_script(root, "validate")
      write_script(root, "test")
      File.write(File.join(root, "AGENTS.md"), "# AGENTS.md\n\n## Commands\n")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing AGENTS.md section: Agent Workflow Configuration"
    end
  end

  def test_missing_core_script_fails
    with_repo do |root|
      write_agents(root)
      write_policy(root)
      write_bin_readme(root)
      write_script(root, "validate")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing core script: .agents/bin/test"
    end
  end

  def test_non_executable_core_script_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      File.chmod(0o644, File.join(root, ".agents/bin/test"))
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "core script is not executable: .agents/bin/test"
    end
  end

  def test_non_executable_optional_script_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      write_script(root, "lint", "exec bundle exec rubocop\n")
      File.chmod(0o644, File.join(root, ".agents/bin/lint"))
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "script is not executable: .agents/bin/lint"
    end
  end

  def test_script_without_repo_root_cd_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      path = File.join(root, ".agents/bin/test")
      File.write(path, <<~BASH)
        #!/usr/bin/env bash
        set -euo pipefail
        exec bundle exec rspec
      BASH
      File.chmod(0o755, path)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "script does not cd to repo root: .agents/bin/test"
    end
  end

  def test_composed_script_root_preamble_passes
    with_repo do |root|
      write_valid_binstub_contract(root)
      path = File.join(root, ".agents/bin/validate")
      File.write(path, <<~BASH)
        #!/usr/bin/env bash
        set -euo pipefail
        root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
        cd "$root"
        "$root/.agents/bin/test"
      BASH
      File.chmod(0o755, path)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end

  def test_bash_syntax_error_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      path = File.join(root, ".agents/bin/test")
      File.write(path, <<~BASH)
        #!/usr/bin/env bash
        set -euo pipefail
        cd "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
        if true
      BASH
      File.chmod(0o755, path)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "script has bash syntax error: .agents/bin/test"
    end
  end

  def test_composed_script_missing_sibling_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      path = File.join(root, ".agents/bin/validate")
      File.write(path, <<~BASH)
        #!/usr/bin/env bash
        set -euo pipefail
        root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
        cd "$root"
        "$root/.agents/bin/lint"
        "$root/.agents/bin/test"
      BASH
      File.chmod(0o755, path)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "script references missing sibling script: .agents/bin/validate -> .agents/bin/lint"
    end
  end

  def test_missing_policy_file_fails
    with_repo do |root|
      write_agents(root)
      write_bin_readme(root)
      write_script(root, "validate")
      write_script(root, "test")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing policy config: .agents/agent-workflow.yml"
    end
  end

  def test_missing_required_policy_key_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      values = POLICY.dup
      values.delete("review_gate")
      write_policy(root, values)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing policy key: review_gate"
    end
  end

  def test_incomplete_untrusted_contributor_intake_policy_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      policy = POLICY.merge(
        "untrusted_contributor_intake" => { "trusted_github_host" => "github.com" }
      )
      write_policy(root, policy)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "missing policy key: untrusted_contributor_intake.trusted_github_scheme"
      assert_includes out, "missing policy key: untrusted_contributor_intake.trusted_github_repo"
    end
  end

  def test_complete_untrusted_contributor_intake_policy_passes
    with_repo do |root|
      write_valid_binstub_contract(root)
      policy = POLICY.merge(
        "untrusted_contributor_intake" => {
          "trusted_github_host" => "github.com",
          "trusted_github_scheme" => "https",
          "trusted_github_repo" => "octo-org/hello-world"
        }
      )
      write_policy(root, policy)
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      assert status.success?, out
      assert_includes out, "PASS"
    end
  end

  def test_unresolved_policy_value_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
      write_policy(root, POLICY.merge("ci_parity_environment" => "<runner image>"))
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "unresolved policy value for key: ci_parity_environment"
    end
  end

  def test_invalid_policy_yaml_fails
    with_repo do |root|
      write_agents(root)
      write_bin_readme(root)
      write_script(root, "validate")
      write_script(root, "test")
      File.write(File.join(root, ".agents/agent-workflow.yml"), "base_branch: [\n")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "invalid policy config: .agents/agent-workflow.yml"
    end
  end

  def test_regular_check_accepts_scalar_trust_values_for_preflight_compatibility
    with_repo do |root|
      write_valid_binstub_contract(root)
      write_skill(root, "No commands here.\n")
      File.write(File.join(root, ".agents/trusted-github-actors.yml"), "trusted_bots: deploy\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_regular_check_rejects_overlapping_trust_bot_roles
    with_repo do |root|
      write_valid_binstub_contract(root)
      write_skill(root, "No commands here.\n")
      trust = {
        "trusted_bots" => ["@Deploy[bot]"],
        "trusted_metadata_bots" => ["deploy"]
      }
      File.write(File.join(root, ".agents/trusted-github-actors.yml"), trust.to_yaml)

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "bot(s) listed in both trusted_bots and trusted_metadata_bots: deploy"
    end
  end

  def test_json_output_format
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_policy(root)
      write_bin_readme(root)
      write_script(root, "validate")
      write_script(root, "test")
      write_skill(root, "No commands here.\n")

      out, status = run_doctor(root, "--json")

      refute status.success?
      parsed = JSON.parse(out)
      assert_equal "FAIL", parsed.fetch("status")
      refute_empty parsed.fetch("issues")
    end
  end
end

class AgentWorkflowSeamDoctorPlaceholderTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

  def test_executable_angle_placeholder_in_code_fence_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
      write_skill(root, "```bash\r\necho ok\r\n```\r\n<follow-up prefix>\r\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_spaced_info_string_on_long_non_executable_fence_is_not_executable
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
      write_skill(root, "    ```bash\n    gh issue create --title \"<follow-up prefix> Review feedback\"\n    ```\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_inline_code_in_executable_fence_is_not_reported_twice
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
      write_skill(root, "Run `act -P ubuntu-latest=<reproduction guide URL>`.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<reproduction guide URL>"
    end
  end

  def test_executable_compound_placeholder_is_reported_once
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
      write_skill(root, "Run `act pull_request -P ubuntu-latest=<runner image>`.\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, "<runner image>"
    end
  end

  def test_inline_act_prose_does_not_make_placeholder_executable
    with_repo do |root|
      write_valid_binstub_contract(root)
      write_skill(root, "Use `act on this finding <runner image>` when documenting parity.\n")

      out, status = run_doctor(root)

      assert status.success?, out
    end
  end

  def test_non_executable_fence_placeholder_is_allowed
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
      write_skill(root, "No commands here.\n")
      write_workflow(root, "`gh issue create --title \"<follow-up prefix> Review\"`\n")

      out, status = run_doctor(root)

      refute status.success?
      assert_includes out, ".agents/workflows/example.md"
    end
  end

  def test_invalid_utf8_markdown_does_not_crash_scanner
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
      write_skill(root, "No commands here.\n")
      missing_root = File.join(root, "missing-shared-root")

      out, status = run_doctor(root, "--shared", missing_root)

      refute status.success?
      assert_includes out, "missing shared root: #{missing_root}"
    end
  end

  def test_shared_root_without_skill_or_workflow_markdown_fails
    with_repo do |root|
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
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
      write_valid_binstub_contract(root)
      agents_path = File.join(root, "AGENTS.md")
      body = File.read(agents_path, encoding: "UTF-8")
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

class AgentWorkflowSeamDoctorInitCliTest < Minitest::Test
  include AgentWorkflowSeamDoctorTestHelpers

  def test_help_advertises_init
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")

    assert status.success?, out
    assert_includes out, "--init"
  end

  def test_init_only_options_require_init
    {
      "--base-branch" => "develop",
      "--validate-command" => "true",
      "--test-command" => "true"
    }.each do |option, value|
      Dir.mktmpdir("agent-workflow-seam-init") do |root|
        out, status = run_doctor(root, option, value)

        refute status.success?
        assert_includes out, "#{option} requires --init"
      end
    end
  end

  def test_init_with_explicit_commands_creates_a_complete_seam
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      assert status.success?, out
      assert_includes out, "PASS agent workflow seam is complete"
      assert_includes File.read(File.join(root, "AGENTS.md"), encoding: "UTF-8"), AgentWorkflowSeamDoctor::POINTER_SECTION
      assert File.executable?(File.join(root, ".agents/bin/validate"))
      assert File.executable?(File.join(root, ".agents/bin/test"))
      assert_equal "main", YAML.safe_load(File.read(File.join(root, ".agents/agent-workflow.yml"))).fetch("base_branch")
      trust = YAML.safe_load(File.read(File.join(root, ".agents/trusted-github-actors.yml")))
      assert_equal [], trust.fetch("trusted_users")
      assert_equal [], trust.fetch("trusted_bots")
      assert_equal ["github-actions"], trust.fetch("trusted_metadata_bots")
      assert_equal [], trust.fetch("trusted_teams")
    end
  end

  def test_init_explicit_simple_commands_forward_wrapper_arguments
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      %w[validate test].each do |name|
        path = File.join(root, "bin", name)
        File.write(path, "#!/usr/bin/env bash\nprintf '#{name}:%s\\n' \"${1:-missing}\"\n")
        File.chmod(0o755, path)
      end

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "bin/validate",
        "--test-command", "bin/test"
      )
      assert status.success?, out

      validate_out, validate_status = Open3.capture2e(File.join(root, ".agents/bin/validate"), "--changed=src/a b.rb")
      test_out, test_status = Open3.capture2e(File.join(root, ".agents/bin/test"), "--watch=false")
      assert validate_status.success?, validate_out
      assert test_status.success?, test_out
      assert_equal "validate:--changed=src/a b.rb\n", validate_out
      assert_equal "test:--watch=false\n", test_out
    end
  end

  def test_init_preserves_shell_comment_commands_verbatim
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = "echo validate # caller owns forwarding"
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      assert_includes validate, "#{command}\n"
      refute_includes validate, "#{command} \"$@\""
    end
  end

  def test_init_preserves_compound_commands_verbatim
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = 'bin/validate "$@" && bin/test "$@"'
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      assert_includes validate, "#{command}\n"
      refute_includes validate, "exec #{command}"
    end
  end

  def test_init_preserves_subshell_commands_verbatim
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = '(bin/validate "$@")'
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      assert_includes validate, "#{command}\n"
      refute_includes validate, "exec #{command}"
    end
  end

  def test_init_forwards_arguments_when_shell_metacharacters_are_quoted_or_escaped
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", 'LABEL="issue #1" bin/validate',
        "--test-command", 'URL=https://example.test/a\&b bin/test'
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'LABEL="issue #1" bin/validate "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'URL=https://example.test/a\&b bin/test "$@"'
    end
  end

  def test_init_forwards_outer_arguments_when_inner_forwarding_is_single_quoted
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = 'bash -c \'exec bin/validate "$@"\' _'
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), %(exec #{command} "$@")
    end
  end

  def test_init_rejects_inner_shell_forwarding_without_a_dollar_zero_placeholder
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", 'bash -c \'exec bin/validate "$@"\'',
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c forwarding requires an explicit \$0 placeholder after the command string"
      assert_includes out, "add _ before forwarded wrapper arguments"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_rejects_inner_shell_forwarding_without_a_placeholder_after_clustered_env_flags
    runtime_out, _runtime_err, runtime_status = Open3.capture3(
      "env", "-iv", "bash", "-c", 'printf "%s\\n" "$@"', "FIRST", "SECOND"
    )
    assert runtime_status.success?, runtime_out
    assert_equal "SECOND\n", runtime_out

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(%q(env -iv bash -c 'exec bin/validate "$@"'))
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_preserves_runtime_arguments_after_clustered_env_flags_with_a_placeholder
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/usr/bin/env sh\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      command = %q(env -iv bash -c 'exec bin/validate "$@"' _)

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )
      assert status.success?, out

      runtime_out, _runtime_err, runtime_status = Open3.capture3(
        File.join(root, ".agents/bin/validate"), "FIRST", "SECOND"
      )
      assert runtime_status.success?, runtime_out
      assert_equal "<FIRST>\n<SECOND>\n", runtime_out
    end
  end

  def test_init_consumes_attached_operands_in_clustered_env_short_options
    {
      %q(env -iuCI bash -c 'exec bin/validate "$@"' _) =>
        %q(exec env -iuCI bash -c 'exec bin/validate "$@"' _ "$@"),
      %q(env -iC/tmp bash -c 'exec bin/validate "$@"' _) =>
        %q(exec env -iC/tmp bash -c 'exec bin/validate "$@"' _ "$@")
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_consumes_gnu_long_env_option_operands_attached_with_equals
    command = %q(env --unset=CI --chdir=/tmp bash -c 'exec bin/validate "$@"' _)

    assert_equal %q(exec env --unset=CI --chdir=/tmp bash -c 'exec bin/validate "$@"' _ "$@"),
                 AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_fails_closed_when_an_env_option_operand_consumes_the_last_token
    [
      "env -iu CI",
      "env -iC /tmp",
      "env --unset CI",
      "env --chdir /tmp"
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "cannot safely parse env command prefix"
    end
  end

  def test_init_fails_closed_when_env_has_only_assignments_or_an_empty_split_string
    [
      "env -i FOO=bar",
      "env FOO=bar",
      "env -iu CI FOO=bar",
      "env -- FOO=bar",
      "env -S ''",
      "env -ivS ''",
      "env --split-string ''",
      "env --split-string="
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "cannot safely parse env command prefix"
    end
  end

  def test_init_accepts_env_assignments_followed_by_a_utility
    {
      "env -i FOO=bar npm run validate" => 'exec env -i FOO=bar npm run validate -- "$@"',
      "env FOO=bar npm run validate" => 'exec env FOO=bar npm run validate -- "$@"',
      "env -iu CI FOO=bar npm run validate" => 'exec env -iu CI FOO=bar npm run validate -- "$@"',
      "env -- FOO=bar npm run validate" => 'exec env -- FOO=bar npm run validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_preserves_exec_as_a_literal_env_utility
    {
      "env exec" => 'exec env exec "$@"',
      "env FOO=bar exec" => 'exec env FOO=bar exec "$@"',
      "env exec npm run validate" => 'exec env exec npm run validate "$@"',
      "env FOO=bar exec npm run validate" => 'exec env FOO=bar exec npm run validate "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_accepts_attached_empty_long_env_operands_followed_by_a_utility
    {
      "env --unset= npm run validate" => 'exec env --unset= npm run validate -- "$@"',
      "env --chdir= npm run validate" => 'exec env --chdir= npm run validate -- "$@"',
      "env --split-string= npm run validate" => 'exec env --split-string= npm run validate -- "$@"',
      "env --argv0= npm run validate" => 'exec env --argv0= npm run validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_accepts_empty_separate_split_string_operands_followed_by_a_utility
    {
      "env -S '' npm run validate" => 'exec env -S \'\' npm run validate -- "$@"',
      "env -ivS '' npm run validate" => 'exec env -ivS \'\' npm run validate -- "$@"',
      "env --split-string '' npm run validate" => 'exec env --split-string \'\' npm run validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_accepts_next_token_env_option_operands_followed_by_a_utility
    {
      "env -iu CI npm run validate" => 'exec env -iu CI npm run validate -- "$@"',
      "env -iC /tmp npm run validate" => 'exec env -iC /tmp npm run validate -- "$@"',
      "env --unset CI npm run validate" => 'exec env --unset CI npm run validate -- "$@"',
      "env --chdir /tmp npm run validate" => 'exec env --chdir /tmp npm run validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_fails_closed_for_unknown_or_malformed_env_options
    [
      %q(env -x bash -c 'exec bin/validate "$@"'),
      %q(env -ivx bash -c 'exec bin/validate "$@"'),
      %q(env --unknown bash -c 'exec bin/validate "$@"'),
      "env -u",
      "env -ivC",
      "env -ivS"
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "cannot safely parse env command prefix"
    end
  end

  def test_init_preserves_clustered_env_split_string_commands_verbatim
    [
      "env -ivS 'npm run validate' \"$@\"",
      "env -ivS'npm run validate' \"$@\"",
      "env --split-string 'npm run validate' \"$@\""
    ].each do |command|
      assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_preserves_absolute_env_split_string_commands_verbatim
    [
      "/usr/bin/env -S 'npm run validate' \"$@\"",
      "/usr/bin/env -ivS'npm run validate' \"$@\"",
      "/usr/bin/env --split-string='npm run validate' \"$@\"",
      %q(/usr/bin/env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _' "$@")
    ].each do |command|
      assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_rejects_an_empty_absolute_env_split_string
    ["/usr/bin/env -S ''", "/usr/bin/env --split-string="].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "cannot safely parse env command prefix"
    end
  end

  def test_init_preserves_runtime_arguments_through_an_absolute_env_split_string
    Dir.mktmpdir("agent-workflow-seam-init-env-split") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/usr/bin/env sh\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      command = %q(/usr/bin/env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@")

      assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )
      assert status.success?, out

      runtime_out, runtime_status = Open3.capture2e(
        File.join(root, ".agents/bin/validate"), "FIRST", "SECOND"
      )
      assert runtime_status.success?, runtime_out
      assert_equal "<FIRST>\n<SECOND>\n", runtime_out
    end
  end

  def test_init_recursively_recognizes_a_safe_nested_env_split_string
    Dir.mktmpdir("agent-workflow-seam-init-env-nested") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/usr/bin/env sh\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      command = %q(env env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@")

      assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )
      assert status.success?, out

      runtime_out, runtime_status = Open3.capture2e(
        File.join(root, ".agents/bin/validate"), "FIRST", "SECOND"
      )
      assert runtime_status.success?, runtime_out
      assert_equal "<FIRST>\n<SECOND>\n", runtime_out
    end
  end

  def test_init_recursively_normalizes_npm_after_nested_env_utilities
    assert_equal 'exec env env npm run validate -- "$@"',
                 AgentWorkflowSeamDoctor.init_command_line("env env npm run validate")

    Dir.mktmpdir("agent-workflow-seam-init-env-npm") do |root|
      marker = File.join(root, "args.json")
      node_program = 'require("fs").writeFileSync(process.env.MARKER, JSON.stringify(process.argv.slice(1)))'
      File.write(
        File.join(root, "package.json"),
        JSON.generate(
          "name" => "nested-env-runtime",
          "version" => "1.0.0",
          "scripts" => { "capture" => "node -e #{Shellwords.escape(node_program)} --" }
        )
      )
      command = AgentWorkflowSeamDoctor.init_command_line("env env npm run capture")
      out, status = Open3.capture2e(
        { "MARKER" => marker }, "bash", "-c", command, "_", "--caller", chdir: root
      )

      assert status.success?, out
      assert_equal ["--caller"], JSON.parse(File.read(marker))
    end
  end

  def test_init_rejects_opaque_env_split_strings_without_explicit_outer_forwarding
    [
      "env -S 'npm run validate'",
      "/usr/bin/env --split-string='npm run validate'",
      %q(env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(env env -S 'bash -c "printf \"<%s>\\n\" \"\$@\""')
    ].each do |command|
      Dir.mktmpdir("agent-workflow-seam-init-env-policy") do |root|
        out, status = run_doctor(
          root,
          "--init",
          "--validate-command", command,
          "--test-command", "true"
        )

        refute status.success?, command
        assert_includes out, "opaque env split-string commands require explicit outer argument forwarding"
        refute File.exist?(File.join(root, ".agents/bin/validate"))
        refute Dir.exist?(File.join(root, ".agents"))
      end
    end
  end

  def test_init_preserves_safe_bare_absolute_and_nested_env_split_strings
    Dir.mktmpdir("agent-workflow-seam-init-env-policy") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/usr/bin/env sh\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      [
        %q(env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(/usr/bin/env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(env env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@")
      ].each do |command|
        assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)
        runtime_out, runtime_status = Open3.capture2e(
          "bash", "-c", command, "_", "FIRST", "SECOND", chdir: root
        )
        assert runtime_status.success?, runtime_out
        assert_equal "<FIRST>\n<SECOND>\n", runtime_out
      end
    end
  end

  def test_init_rejects_opaque_env_split_strings_after_option_bearing_exec_prefixes
    [
      %q(exec -a wrapped env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(exec -c env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(exec -cl env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(exec -- env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(CI=1 exec -a wrapped env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(exec -cl env /usr/bin/env -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _')
    ].each do |command|
      Dir.mktmpdir("agent-workflow-seam-init-env-exec-policy") do |root|
        out, status = run_doctor(
          root,
          "--init",
          "--validate-command", command,
          "--test-command", "true"
        )

        refute status.success?, command
        assert_includes out, "opaque env split-string commands require explicit outer argument forwarding"
        refute Dir.exist?(File.join(root, ".agents"))
      end
    end
  end

  def test_init_preserves_runtime_arguments_after_option_bearing_exec_prefixes
    Dir.mktmpdir("agent-workflow-seam-init-env-exec-policy") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/bin/sh\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      [
        %q(exec -a wrapped env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(exec -c env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(exec -cl env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(exec -- env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(CI=1 exec -a wrapped env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(exec -cl env /usr/bin/env -S 'bash -c "exec bin/validate \"\$@\"" _' "$@")
      ].each do |command|
        assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)
        runtime_out, runtime_status = Open3.capture2e(
          "bash", "-c", command, "_", "FIRST", "SECOND", chdir: root
        )
        assert runtime_status.success?, "#{command}: #{runtime_out}"
        assert_equal "<FIRST>\n<SECOND>\n", runtime_out, command
      end
    end
  end

  def test_init_rejects_env_split_strings_when_forwarding_is_only_an_earlier_option_value
    [
      %q(env -u "$@" -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(env --argv0 "$@" -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(env env -u "$@" -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(env /usr/bin/env --argv0 "$@" -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _'),
      %q(env -u '$@' -S 'bash -c "printf \"<%s>\\n\" \"\$@\"" _')
    ].each do |command|
      Dir.mktmpdir("agent-workflow-seam-init-env-boundary") do |root|
        out, status = run_doctor(
          root,
          "--init",
          "--validate-command", command,
          "--test-command", "true"
        )

        refute status.success?, command
        assert_includes out, "opaque env split-string commands require explicit outer argument forwarding"
        refute Dir.exist?(File.join(root, ".agents"))
      end
    end
  end

  def test_init_requires_env_split_string_forwarding_after_the_split_operand
    Dir.mktmpdir("agent-workflow-seam-init-env-boundary") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/bin/sh\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      [
        %q(env -u CI -S 'bash -c "exec bin/validate \"\$@\"" _' "$@"),
        %q(env /usr/bin/env -u CI -S 'bash -c "exec bin/validate \"\$@\"" _' "$@")
      ].each do |command|
        assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)
        runtime_out, runtime_status = Open3.capture2e(
          "bash", "-c", command, "_", "FIRST", "SECOND", chdir: root
        )
        assert runtime_status.success?, "#{command}: #{runtime_out}"
        assert_equal "<FIRST>\n<SECOND>\n", runtime_out, command
      end

      long_option_command = %q(env --argv0 validator -S 'bash -c "exec bin/validate \"\$@\"" _' "$@")
      assert_equal long_option_command, AgentWorkflowSeamDoctor.init_command_line(long_option_command)
    end
  end

  def test_init_rejects_a_shell_comment_in_place_of_the_dollar_zero_placeholder
    command = 'bash -c \'exec bin/validate "$@"\' # not a placeholder'

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_rejects_shell_boundaries_in_place_of_the_dollar_zero_placeholder
    [
      "# comment",
      "< input",
      "<input",
      "> output",
      ">output",
      "2> output",
      "2>output",
      "{fd}>output",
      "&& true",
      "|| true",
      "; true",
      "& true",
      "| true",
      "( true",
      ")"
    ].each do |boundary|
      command = %(bash -c 'exec bin/validate "$@"' #{boundary})

      error = assert_raises(AgentWorkflowSeamDoctor::InitError, boundary) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
    end
  end

  def test_init_rejects_shell_boundaries_attached_to_the_command_string
    ["; true", "&& true", "|| true", "& true", "| true", "< input", "> output", "2> output"].each do |suffix|
      command = %(bash -c 'exec bin/validate "$@"'#{suffix})

      [command, "#{command} _"].each do |candidate|
        error = assert_raises(AgentWorkflowSeamDoctor::InitError, candidate) do
          AgentWorkflowSeamDoctor.init_command_line(candidate)
        end
        assert_includes error.message, "bash -c command string has an attached unquoted shell metacharacter"
        assert_includes error.message, "quote or separate the metacharacter"
      end
    end
  end

  def test_init_rejects_backtick_substitution_attached_to_a_shell_command_string
    Dir.mktmpdir("agent-workflow-seam-init-substitution") do |root|
      marker = File.join(root, "should-not-exist")
      substitution = File.join(root, "attempt-substitution")
      File.write(substitution, "#!/bin/sh\ntouch #{Shellwords.escape(marker)}\n")
      File.chmod(0o755, substitution)
      command = %(bash -c 'printf safe'`#{substitution}` _)

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "active outer command substitution"
      refute_includes out, substitution
      refute File.exist?(marker)
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_rejects_top_level_outer_command_substitution
    ["`touch secret-marker`", "$(touch secret-marker)"].each do |substitution|
      command = "printf safe#{substitution}"

      error = assert_raises(AgentWorkflowSeamDoctor::InitError, substitution) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "active outer command substitution"
      refute_includes error.message, "secret-marker"
    end
  end

  def test_init_rejects_substitution_after_an_apostrophe_inside_double_quotes
    accepted = []

    %w[dollar backtick].each do |form|
      Dir.mktmpdir("agent-workflow-seam-init-substitution") do |root|
        marker = File.join(root, "executed")
        trigger = File.join(root, "trigger")
        File.write(trigger, "#!/bin/sh\ntouch #{Shellwords.escape(marker)}\n")
        File.chmod(0o755, trigger)
        substitution = form == "dollar" ? "$(#{trigger})" : "`#{trigger}`"
        command = %(printf "%s\\n" "it's #{substitution}")

        out, status = run_doctor(
          root,
          "--init",
          "--validate-command", command,
          "--test-command", "true"
        )
        if status.success?
          runtime_out, runtime_status = Open3.capture2e(File.join(root, ".agents/bin/validate"))
          accepted << "#{form}:runtime=#{runtime_status.success?}:marker=#{File.exist?(marker)}:#{runtime_out}"
        else
          assert_includes out, "active outer command substitution"
          refute_includes out, trigger
          refute File.exist?(marker)
        end
      end
    end

    assert_empty accepted, accepted.join("; ")
  end

  def test_init_validates_all_commands_before_writing_any_wrapper
    Dir.mktmpdir("agent-workflow-seam-init-transaction") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", 'printf "$(true)"'
      )

      refute status.success?
      assert_includes out, "active outer command substitution"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
      refute File.exist?(File.join(root, ".agents/bin/test"))
      refute Dir.exist?(File.join(root, ".agents"))
    end
  end

  def test_init_ignores_substitution_text_in_an_inert_shell_comment
    command = "printf safe # $(docs example)"

    assert_equal command, AgentWorkflowSeamDoctor.init_command_line(command)

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line("printf safe#$(true)")
    end
    assert_includes error.message, "active outer command substitution"
  end

  def test_init_allows_command_substitution_inside_a_single_quoted_shell_payload
    [
      %q(bash -c 'printf "%s\n" "$(printf safe)"' _),
      %q(bash -c 'printf "%s\n" "`printf safe`"' _)
    ].each do |command|
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_fails_closed_for_malformed_shell_and_non_shell_quoting
    [
      %q(bash -c 'exec bin/validate "$@"),
      "ruby -e 'puts :ok"
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_equal "cannot safely parse command: unmatched quotes or shell tokenization mismatch; " \
                   "fix the command quoting", error.message
    end
  end

  def test_init_fails_closed_without_leaking_an_internal_tokenization_mismatch
    original = AgentWorkflowSeamDoctor.method(:shell_word_spans)
    AgentWorkflowSeamDoctor.define_singleton_method(:shell_word_spans) do |*|
      raise ArgumentError, "shell tokenization mismatch: secret command text"
    end

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line("true")
    end
    assert_equal "cannot safely parse command: unmatched quotes or shell tokenization mismatch; " \
                 "fix the command quoting", error.message
    refute_includes error.message, "secret command text"
  ensure
    AgentWorkflowSeamDoctor.define_singleton_method(:shell_word_spans, original) if original
  end

  def test_init_allows_shell_words_as_dollar_zero_placeholders
    ["_", "'#'", "\\#", "'<input'", "\\>output", "'&&'"].each do |placeholder|
      command = %(bash -c 'exec bin/validate "$@"' #{placeholder} "$@")

      assert_equal %(exec #{command}), AgentWorkflowSeamDoctor.init_command_line(command), placeholder
    end
  end

  def test_init_rejects_an_unquoted_expansion_that_can_remove_the_dollar_zero_placeholder
    runtime_out, runtime_status = Open3.capture2e(
      { "EMPTY" => nil },
      "bash", "-c", %q(bash -c 'printf "%s\n" "$@"' ${EMPTY-} FIRST SECOND)
    )
    assert runtime_status.success?, runtime_out
    assert_equal "SECOND\n", runtime_out

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(%q(bash -c 'exec bin/validate "$@"' ${EMPTY-}))
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_rejects_an_unquoted_parameter_expansion_placeholder
    placeholder = "$EMPTY"
    command = %(bash -c 'exec bin/validate "$@"' #{placeholder})
    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_rejects_unquoted_command_substitution_placeholders
    ["$(true)", "`true`"].each do |placeholder|
      command = %(bash -c 'exec bin/validate "$@"' #{placeholder})
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, placeholder) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "active outer command substitution"
    end
  end

  def test_init_rejects_placeholder_syntax_that_can_expand_to_multiple_words
    ["*", "file?.rb", "[ab]*", "{left,right}"].each do |placeholder|
      command = %(bash -c 'exec bin/validate "$@"' #{placeholder})
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, placeholder) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
    end
  end

  def test_init_allows_literal_quoted_and_escaped_placeholder_metacharacters
    [
      "_",
      "'$EMPTY'",
      "'$(true)'",
      "'*'",
      "'{left,right}'",
      %q(\$EMPTY),
      %q(\*),
      %q(\?),
      %q(\{left,right\}),
      %q("\$EMPTY"),
      '"*"'
    ].each do |placeholder|
      command = %(bash -c 'exec bin/validate "$@"' #{placeholder})

      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), placeholder
    end
  end

  def test_init_preserves_runtime_arguments_with_an_explicit_placeholder_before_a_comment
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/usr/bin/env bash\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      command = 'bash -c \'exec bin/validate "$@"\' _ "$@" # caller owns forwarding'

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )
      assert status.success?, out

      validate_out, validate_status = Open3.capture2e(
        File.join(root, ".agents/bin/validate"), "first argument", "; touch should-not-run"
      )
      assert validate_status.success?, validate_out
      assert_equal "<first argument>\n<; touch should-not-run>\n", validate_out
    end
  end

  def test_init_allows_literal_forwarding_text_in_an_inner_shell_payload
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = 'bash -c \'echo \\$@\' _'
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), %(exec #{command} "$@")
    end
  end

  def test_init_rejects_double_quoted_shell_forwarding_without_a_dollar_zero_placeholder
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c "exec bin/validate \"$@\"")
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c has active outer argument expansion inside its command string"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_rejects_active_outer_forwarding_in_a_double_quoted_shell_payload_even_with_placeholder
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c "exec bin/validate \"$@\"" _)
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c has active outer argument expansion inside its command string"
      assert_includes out, "use a single-quoted command string plus an explicit $0 placeholder"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_rejects_active_outer_forwarding_despite_inner_single_quote_characters
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c "echo '$@'" _)
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c has active outer argument expansion inside its command string"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_requires_placeholder_for_outer_escaped_forwarding_in_a_double_quoted_payload
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c "exec bin/validate \"\$@\"")
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c forwarding requires an explicit $0 placeholder"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_allows_outer_escaped_forwarding_in_a_double_quoted_payload_with_placeholder
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c "exec bin/validate \"\$@\"" _)
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), %(exec #{command} "$@")
    end
  end

  def test_init_requires_placeholder_for_forwarding_in_an_unquoted_escaped_shell_payload
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c exec\ bin/validate\ \"\$@\")
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c forwarding requires an explicit $0 placeholder"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_preserves_all_arguments_for_dequoted_shell_payloads_with_placeholder
    [
      %q(bash -c exec\ bin/validate\ \"\$@\" _),
      %q(bash -c $'exec bin/validate "$@"' _),
      %q(bash -c $'exec bin/validate "\044\100"' _)
    ].each do |command|
      Dir.mktmpdir("agent-workflow-seam-init") do |root|
        FileUtils.mkdir_p(File.join(root, "bin"))
        validate_path = File.join(root, "bin/validate")
        File.write(validate_path, <<~BASH)
          #!/usr/bin/env bash
          printf '%s\n' "$@"
        BASH
        File.chmod(0o755, validate_path)
        out, status = run_doctor(
          root,
          "--init",
          "--validate-command", command,
          "--test-command", "true"
        )
        assert status.success?, out

        marker = File.join(root, "injected")
        hostile_argument = "; touch #{marker}"
        validate_out, validate_status = Open3.capture2e(
          File.join(root, ".agents/bin/validate"), "first", hostile_argument
        )

        assert validate_status.success?, validate_out
        assert_equal "first\n#{hostile_argument}\n", validate_out
        refute File.exist?(marker), "forwarded argument executed as shell source"
      end
    end
  end

  def test_init_requires_placeholder_for_forwarding_in_an_ansi_c_quoted_shell_payload
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c $'exec bin/validate "$@"')
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c forwarding requires an explicit $0 placeholder"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_rejects_forwarding_exposed_by_ansi_c_nul_truncation
    command = <<~'COMMAND'.chomp
      bash -c $'exec bin/validate \0\\''$@'
    COMMAND

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_rejects_forwarding_in_fragments_concatenated_after_encoded_ansi_c_nuls
    [
      %q(bash -c $'exec bin/validate \000\047''"$@"'),
      %q(bash -c $'exec bin/validate \x00\047''"$@"'),
      %q(bash -c $'exec bin/validate \u0000\047''"$@"'),
      %q(bash -c $'exec bin/validate \U00000000\047''"$@"')
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
    end
  end

  def test_init_rejects_forwarding_exposed_by_wrapped_octal_nul_truncation
    command = <<~'COMMAND'.chomp
      bash -c $'exec bin/validate \400\047''"$@"'
    COMMAND

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_requires_placeholder_for_octal_forwarding_in_an_ansi_c_quoted_shell_payload
    [
      %q(bash -c $'exec bin/validate "\044\100"'),
      %q(bash -c $'exec bin/validate "\444\500"'),
      %q(bash -c $'exec bin/validate "\044'$'\100'$'"')
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
    end
  end

  def test_init_requires_placeholder_for_hex_forwarding_in_an_ansi_c_quoted_shell_payload
    command = %q(bash -c $'exec bin/validate "\x24\x40"')

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_requires_placeholder_for_unicode_forwarding_in_an_ansi_c_quoted_shell_payload
    [
      %q(bash -c $'exec bin/validate "\u0024\u0040"'),
      %q(bash -c $'exec bin/validate "\U00000024\U00000040"'),
      %q(bash -c $'exec bin/validate "\u0024\u0040\u0000"')
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
    end
  end

  def test_init_ignores_forwarding_bytes_after_a_nul_in_the_same_ansi_c_segment
    command = %q(bash -c $'printf safe\u0000\u0024\u0040' _)

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_preserves_runtime_arguments_after_ansi_c_nul_truncation_with_a_placeholder
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      validate_path = File.join(root, "bin/validate")
      File.write(validate_path, "#!/usr/bin/env bash\nprintf '<%s>\\n' \"$@\"\n")
      File.chmod(0o755, validate_path)
      command = <<~'COMMAND'.chomp
        bash -c $'exec bin/validate \x00\047''"$@"' _ "$@"
      COMMAND

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )
      assert status.success?, out

      validate_out, validate_status = Open3.capture2e(
        File.join(root, ".agents/bin/validate"), "first argument", "; touch should-not-run"
      )
      assert validate_status.success?, validate_out
      assert_equal "<first argument>\n<; touch should-not-run>\n", validate_out
    end
  end

  def test_init_rejects_malformed_or_unsupported_ansi_c_escapes_in_a_shell_payload
    [
      %q(bash -c $'printf "\x"'),
      %q(bash -c $'printf "\u"'),
      %q(bash -c $'printf "\U00110000"'),
      %q(bash -c $'printf "\c"'),
      %q(bash -c $'printf "\q"')
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "cannot safely decode ANSI-C command string"
    end
  end

  def test_init_allows_benign_supported_ansi_c_escapes_in_a_shell_payload
    command = %q(bash -c $'printf "safe\nvalue\t\?"' _)

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_fails_closed_for_an_ansi_c_escaped_quote_even_with_a_safe_placeholder
    command = <<~'COMMAND'.chomp
      bash -c $'printf "<%s>\\n" "it\'s safe"' _
    COMMAND

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "cannot safely parse command"

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command.delete_suffix(" _"))
    end
    assert_includes error.message, "cannot safely parse command"
  end

  def test_init_allows_high_byte_octal_and_hex_ansi_c_escapes
    [
      %q(bash -c $'printf "\303\251"'),
      %q(bash -c $'printf "\xc3\xa9"')
    ].each do |command|
      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder)
    end
  end

  def test_init_does_not_treat_escaped_ansi_c_escape_text_as_forwarding
    [
      %q(bash -c $'printf "\\\\044\\\\100"'),
      %q(bash -c $'printf "\\\\x24\\\\x40"'),
      %q(bash -c $'printf "\\\\u0024\\\\u0040"'),
      %q(bash -c $'printf \047\044\100\047')
    ].each do |command|
      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder)
    end
  end

  def test_init_rejects_active_outer_forwarding_in_a_mixed_quoted_shell_payload
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(bash -c 'printf SAFE; '"$@" _)
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bash -c has active outer argument expansion inside its command string"
      assert_includes out, "use a single-quoted command string plus an explicit $0 placeholder"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_handles_clustered_shell_command_options_with_placeholder_safety
    {
      "bash -lc" => "bash -lc",
      "zsh -cl" => "zsh -cl"
    }.each do |prefix, label|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "#{prefix.split.first} -c forwarding requires an explicit \$0 placeholder"

      command = %(#{prefix} 'exec bin/validate "$@"' _)
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), label
    end
  end

  def test_init_handles_attached_shell_option_values_before_dash_c
    {
      "zsh" => %w[
        -oSHWORDSPLIT -OSHWORDSPLIT +oSHWORDSPLIT +OSHWORDSPLIT
        -foSHWORDSPLIT -fOSHWORDSPLIT +foSHWORDSPLIT +fOSHWORDSPLIT
      ],
      "ksh" => %w[-oemacs +oemacs -foemacs +foemacs],
      "mksh" => %w[-oemacs +oemacs -foemacs +foemacs]
    }.each do |shell, options|
      options.each do |option|
        if system(shell, "-c", "exit 0", out: File::NULL, err: File::NULL)
          runtime_out, runtime_status = Open3.capture2e(
            shell, option, "-c", 'printf "%s\\n" "$@"', "FIRST", "SECOND"
          )
          assert runtime_status.success?, runtime_out
          assert_equal "SECOND\n", runtime_out
        end

        command = %(#{shell} #{option} -c 'printf "%s\\n" "$@"')
        error = assert_raises(AgentWorkflowSeamDoctor::InitError, "#{shell} #{option}") do
          AgentWorkflowSeamDoctor.init_command_line(command)
        end
        assert_includes error.message, "#{shell} -c forwarding requires an explicit $0 placeholder"

        command_with_placeholder = "#{command} _"
        assert_equal %(exec #{command_with_placeholder} "$@"),
                     AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder)
      end
    end
  end

  def test_init_detects_c_before_an_attached_underscored_zsh_o_operand
    command = %q(zsh -fcoSH_WORD_SPLIT 'printf "%s\\n" "$@"')
    if executable_available?("zsh")
      runtime_out, runtime_status = Open3.capture2e(
        "zsh", "-fcoSH_WORD_SPLIT", 'printf "%s\\n" "$@"', "FIRST", "SECOND"
      )
      assert runtime_status.success?, runtime_out
      assert_equal "SECOND\n", runtime_out
    end

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "zsh -c forwarding requires an explicit $0 placeholder"

    command_with_placeholder = "#{command} _"
    assert_equal %(exec #{command_with_placeholder} "$@"),
                 AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder)
  end

  def test_init_ignores_c_inside_attached_zsh_o_operands
    [
      'zsh -oNO_CLOBBER "$@"',
      'zsh -onoclobber "$@"',
      'zsh +fcoSH_WORD_SPLIT "$@"'
    ].each do |command|
      assert_equal %(exec #{command}), AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_finds_the_command_string_after_options_following_dash_c
    runtime_out, runtime_status = Open3.capture2e(
      "bash", "-c", "-e", 'printf "%s\\n" "$@"', "_", "FIRST", "SECOND"
    )
    assert runtime_status.success?, runtime_out
    assert_equal "FIRST\nSECOND\n", runtime_out

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(%q(bash -c -e 'exec bin/validate "$@"'))
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_finds_the_command_string_after_an_option_terminator_following_dash_c
    runtime_out, runtime_status = Open3.capture2e(
      "bash", "-c", "--", 'printf "%s\\n" "$@"', "_", "FIRST", "SECOND"
    )
    assert runtime_status.success?, runtime_out
    assert_equal "FIRST\nSECOND\n", runtime_out

    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(%q(bash -c -- 'exec bin/validate "$@"'))
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"
  end

  def test_init_rejects_dash_c_when_its_command_string_is_missing
    ["bash -c", "bash -c -e", "bash -c --", "bash -c -o posix"].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "bash -c requires a command string before forwarded wrapper arguments"
    end
  end

  def test_init_scans_option_prefixes_after_dash_c_across_supported_shell_families
    [
      "bash +e -c +e",
      "bash -c -o posix",
      "bash -c +o posix",
      "bash -c -O extglob",
      "bash -c +O extglob",
      "sh -c -e",
      "sh -c --",
      "zsh -c -e",
      "zsh -c --"
    ].each do |prefix|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, prefix) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "-c forwarding requires an explicit $0 placeholder"

      command = %(#{prefix} 'exec bin/validate "$@"' _)
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), prefix
    end
  end

  def test_init_preserves_first_and_second_runtime_arguments_after_dash_c_options
    cases = {
      "bash" => ["-c -e", "-c --", "-c -o posix", "+e -c +e"],
      "sh" => ["-c -e", "-c --"],
      "zsh" => ["-c -e", "-c --"]
    }
    cases.each do |shell, prefixes|
      next unless executable_available?(shell)

      prefixes.each do |prefix|
        Dir.mktmpdir("agent-workflow-seam-init") do |root|
          FileUtils.mkdir_p(File.join(root, "bin"))
          validate_path = File.join(root, "bin/validate")
          File.write(validate_path, "#!/usr/bin/env sh\nprintf '<%s>\\n' \"$@\"\n")
          File.chmod(0o755, validate_path)
          command = %(#{shell} #{prefix} 'exec bin/validate "$@"' _)

          out, status = run_doctor(
            root,
            "--init",
            "--validate-command", command,
            "--test-command", "true"
          )
          assert status.success?, "#{command}: #{out}"

          runtime_out, runtime_status = Open3.capture2e(
            File.join(root, ".agents/bin/validate"), "FIRST", "SECOND"
          )
          assert runtime_status.success?, "#{command}: #{runtime_out}"
          assert_equal "<FIRST>\n<SECOND>\n", runtime_out, command
        end
      end
    end
  end

  def test_init_applies_placeholder_safety_to_sh_family_shell_basenames
    %w[ash dash ksh mksh posh].each do |shell|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, shell) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{shell} -c 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "#{shell} -c forwarding requires an explicit $0 placeholder"

      command = %(#{shell} -c 'exec bin/validate "$@"' _)
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_applies_placeholder_safety_to_bounded_shell_aliases_and_versioned_bash_names
    %w[rbash oksh loksh ksh93 yash bash5 bash5.2 bash-5.3 rbash5 rbash-5.3].each do |shell|
      command = %(#{shell} -c 'printf "%s\\n" "$@"')
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, shell) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "#{shell} -c forwarding requires an explicit $0 placeholder"

      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder)
    end

    command = %q(genericsh -c 'printf "%s\n" "$@"')
    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_preserves_runtime_arguments_for_bounded_shell_aliases
    bash = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).filter_map do |directory|
      candidate = File.join(directory, "bash")
      candidate if File.file?(candidate) && File.executable?(candidate)
    end.first
    skip "bash unavailable" unless bash

    Dir.mktmpdir("agent-workflow-seam-init-shell-alias") do |root|
      %w[rbash oksh loksh ksh93 yash bash5 bash5.2 bash-5.3 rbash5].each do |shell|
        path = File.join(root, shell)
        File.symlink(bash, path)
        command = %(#{path} -c 'printf "<%s>\\n" "$@"' _)
        generated = AgentWorkflowSeamDoctor.init_command_line(command)
        runtime_out, runtime_status = Open3.capture2e(
          "bash", "-c", generated, "_", "FIRST", "SECOND"
        )

        assert runtime_status.success?, "#{shell}: #{runtime_out}"
        assert_equal "<FIRST>\n<SECOND>\n", runtime_out, shell
      end
    end
  end

  def test_init_rejects_csh_family_dash_c_commands_outside_the_supported_forwarding_model
    %w[csh tcsh].each do |shell|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, shell) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{shell} -c 'echo safe'))
      end
      assert_includes error.message, "#{shell} -c cannot safely accept generated wrapper arguments"
    end
  end

  def test_init_applies_placeholder_safety_to_direct_busybox_shell_applets
    %w[sh ash].each do |applet|
      prefix = "busybox #{applet}"
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, prefix) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} -c 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "#{prefix} -c forwarding requires an explicit $0 placeholder"

      command = %(#{prefix} -c 'exec bin/validate "$@"' _)
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_consumes_shell_option_values_before_finding_the_command_string_option
    ["bash -o posix -c", "bash -O extglob -c"].each do |prefix|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "bash -c forwarding requires an explicit \$0 placeholder"

      command = %(#{prefix} 'exec bin/validate "$@"' _)
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), prefix
    end
  end

  def test_init_consumes_ksh_family_option_values_before_finding_dash_c
    {
      "ksh" => [["-T", "0"], ["-R", "/tmp/ksh-rc"]],
      "mksh" => [["-T", "0"], ["-R", "/tmp/ksh-rc"]]
    }.each do |shell, options|
      options.each do |option, value|
        if shell == "ksh" && option == "-T" && system(shell, "-c", "exit 0", out: File::NULL, err: File::NULL)
          runtime_out, runtime_status = Open3.capture2e(
            shell, option, value, "-c", 'printf "%s\\n" "$@"', "FIRST", "SECOND"
          )
          assert runtime_status.success?, runtime_out
          assert_equal "SECOND\n", runtime_out
        end

        prefix = "#{shell} #{option} #{value} -c"
        error = assert_raises(AgentWorkflowSeamDoctor::InitError, prefix) do
          AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} 'exec bin/validate "$@"'))
        end
        assert_includes error.message, "#{shell} -c forwarding requires an explicit $0 placeholder"

        command = %(#{prefix} 'exec bin/validate "$@"' _)
        assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), prefix
      end
    end
  end

  def test_init_does_not_treat_c_inside_attached_o_values_as_a_command_flag
    Dir.mktmpdir("shell-attached-o-value") do |root|
      script = File.join(root, "print-args")
      File.write(script, 'printf "<%s>\\n" "$@"')

      {
        "zsh" => %w[-ocorrect -onoclobber],
        "ksh" => %w[-oemacs],
        "mksh" => %w[-oemacs]
      }.each do |shell, options|
        options.each do |option|
          if system(shell, "-c", "exit 0", out: File::NULL, err: File::NULL)
            runtime_out, runtime_status = Open3.capture2e(shell, option, script, "FIRST", "SECOND")
            assert runtime_status.success?, runtime_out
            assert_equal "<FIRST>\n<SECOND>\n", runtime_out
          end

          command = %(#{shell} #{option} "$@")
          assert_equal %(exec #{command}), AgentWorkflowSeamDoctor.init_command_line(command), command
        end
      end
    end
  end

  def test_init_preserves_c_before_attached_or_separate_o_values_as_a_command_flag
    [
      "zsh -coSHWORDSPLIT", "zsh -co SHWORDSPLIT",
      "ksh -coemacs", "ksh -co emacs",
      "mksh -coemacs", "mksh -co emacs"
    ].each do |prefix|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, prefix) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "-c forwarding requires an explicit $0 placeholder"
    end
  end

  def test_init_parses_attached_ksh_family_r_and_t_option_operands
    %w[ksh mksh].each do |shell|
      ["-Rcache", "-T0x"].each do |option|
        command = %(#{shell} #{option} script.ksh "$@")
        assert_equal %(exec #{command}), AgentWorkflowSeamDoctor.init_command_line(command), command
      end

      command = %(#{shell} -T0c 'printf "%s\\n" "$@"')
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, shell) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "#{shell} -c forwarding requires an explicit $0 placeholder"

      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder)
    end

    return unless system("ksh", "-c", "exit 0", out: File::NULL, err: File::NULL)

    runtime_out, runtime_status = Open3.capture2e(
      "ksh", "-T0c", 'printf "%s\\n" "$@"', "FIRST", "SECOND"
    )
    assert runtime_status.success?, runtime_out
    assert_equal "SECOND\n", runtime_out
  end

  def test_init_uses_integrated_ksh_cluster_arity_and_command_metadata
    %w[ksh mksh].each do |shell|
      [
        "#{shell} -T0o emacs -c",
        "#{shell} -T0co emacs",
        "#{shell} -T0R db -c"
      ].each do |prefix|
        command = %(#{prefix} 'printf "%s\\n" "$@"')
        error = assert_raises(AgentWorkflowSeamDoctor::InitError, prefix) do
          AgentWorkflowSeamDoctor.init_command_line(command)
        end
        assert_includes error.message, "#{shell} -c forwarding requires an explicit $0 placeholder"

        command_with_placeholder = "#{command} _"
        assert_equal %(exec #{command_with_placeholder} "$@"),
                     AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder), prefix
      end
    end

    return unless system("ksh", "-c", "exit 0", out: File::NULL, err: File::NULL)

    Dir.mktmpdir("ksh-option-metadata") do |root|
      {
        "-T0o emacs -c" => [["-T0o", "emacs", "-c"], "SECOND\n"],
        "-T0co emacs" => [["-T0co", "emacs"], "SECOND\n"],
        "-T0R db -c" => [["-T0R", File.join(root, "db"), "-c"], ""]
      }.each do |label, (options, expected)|
        runtime_out, runtime_status = Open3.capture2e(
          "ksh", *options, 'printf "%s\\n" "$@"', "FIRST", "SECOND"
        )
        assert runtime_status.success?, "#{label}: #{runtime_out}"
        assert_equal expected, runtime_out, label
      end
    end
  end

  def test_init_consumes_values_for_options_clustered_with_the_command_string_option
    ["bash -clo posix", "bash -oc posix"].each do |prefix|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "bash -c forwarding requires an explicit \$0 placeholder"

      command = %(#{prefix} 'exec bin/validate "$@"' _)
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), prefix
    end
  end

  def test_init_does_not_treat_shell_script_operands_as_command_string_options
    command = %q(bash script.sh -c 'echo "$@"')

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_stops_shell_command_string_detection_at_the_option_terminator
    command = %q(bash -- -c 'echo "$@"')

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_handles_wrapped_and_absolute_shell_commands_with_placeholder_safety
    [
      "env FOO=bar bash -c",
      "/usr/bin/env bash -c",
      "/bin/bash -c"
    ].each do |prefix|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
        AgentWorkflowSeamDoctor.init_command_line(%(#{prefix} 'exec bin/validate "$@"'))
      end
      assert_includes error.message, "bash -c forwarding requires an explicit \$0 placeholder"

      command = %(#{prefix} 'exec bin/validate "$@"' _)
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), prefix
    end
  end

  def test_init_applies_placeholder_safety_to_supported_shell_suffixes_under_wrappers
    [
      "command bash -c",
      "nice -n 5 bash -c",
      "timeout 5 /bin/bash -c",
      "command nice -n 5 timeout 5 busybox sh -c"
    ].each do |prefix|
      command = %(#{prefix} 'exec bin/validate "$@"')
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, prefix) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "-c forwarding requires an explicit $0 placeholder"

      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder), prefix
    end
  end

  def test_init_conservatively_rejects_an_exact_supported_shell_token_used_as_wrapper_data
    command = %q(printf '%s\n' bash -c 'literal "$@"')
    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"

    non_shell_command = %q(printf '%s\n' bashful -c 'literal "$@"')
    assert_equal %(exec #{non_shell_command} "$@"),
                 AgentWorkflowSeamDoctor.init_command_line(non_shell_command)
  end

  def test_init_does_not_treat_a_relative_env_executable_as_the_env_utility
    command = "./bin/env -x true"

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_distinguishes_escaped_and_braced_outer_argument_forwarding
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", 'printf \\$@',
        "--test-command", 'bin/test "${@}"'
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec printf \\$@ "$@"'
      test = File.read(File.join(root, ".agents/bin/test"))
      assert_includes test, 'exec bin/test "${@}"'
      refute_includes test, 'bin/test "${@}" "$@"'
    end
  end

  def test_init_requires_placeholder_for_active_positional_parameter_expansions
    [
      '"$*"',
      '"$#"',
      '"$1"',
      '"$0"',
      '"${@:-fallback}"',
      '"${@#prefix}"',
      '"${*:-fallback}"',
      '"${#}"',
      '"${#@}"',
      '"${#:-fallback}"',
      '"${##prefix}"',
      '"${1:-fallback}"',
      '"${0#prefix}"',
      '"${!1}"',
      '"${!0}"',
      '"${!#}"',
      '"${!@}"'
    ].each do |expression|
      command = %(bash -c 'printf "%s\\n" #{expression}')
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, expression) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "bash -c forwarding requires an explicit $0 placeholder"

      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder), expression
    end
  end

  def test_init_requires_placeholder_for_every_supported_shell_c_payload
    [
      ["bash -c", "echo safe"],
      ["bash -c", 'eval "$DYNAMIC_CODE"'],
      ["bash -c", "source scripts/check.sh"],
      ["bash -c", "run_check"],
      ["zsh -c", 'print -r -- "${(e)code}"'],
      ["zsh -c", 'print -r -- "${(j:P:)list}"'],
      ["zsh -c", 'print -r -- "${(P)${:-argv}}"'],
      ["ksh -c", "print safe"],
      ["command nice -n 5 timeout 5 /bin/bash -c", "echo nested-safe"]
    ].each do |prefix, payload|
      command = "#{prefix} #{Shellwords.escape(payload)}"
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "-c forwarding requires an explicit $0 placeholder"

      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder), command
    end
  end

  def test_init_preserves_the_original_complete_argv_forwarding_contract
    ['"$@"', '"${@}"'].each do |expression|
      command = "bin/test #{expression}"
      assert_equal "exec #{command}", AgentWorkflowSeamDoctor.init_command_line(command), expression
    end
  end

  def test_init_appends_forwarding_when_at_expansion_is_concatenated_or_nested
    [
      'bin/test "$@suffix"',
      'bin/test "prefix${@}"',
      "bin/test ${@}suffix"
    ].each do |command|
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), command
    end

    assert_equal 'FORWARDED="$@" bin/test "$@"',
                 AgentWorkflowSeamDoctor.init_command_line('FORWARDED="$@" bin/test')

    assert_equal 'exec npm run test -- "$@suffix" "$@"',
                 AgentWorkflowSeamDoctor.init_command_line('npm run test "$@suffix"')
    assert_equal 'exec env CI=1 npm run test -- "prefix${@}" "$@"',
                 AgentWorkflowSeamDoctor.init_command_line('env CI=1 npm run test "prefix${@}"')
  end

  def test_init_appends_complete_forwarding_after_positional_state_references
    [
      '"$*"', '"$#"', '"$1"', '"$0"',
      '"${@:-fallback}"', '"${@#prefix}"', '"${*:-fallback}"',
      '"${#}"', '"${#@}"', '"${1:-fallback}"', '"${0#prefix}"',
      '"${!1}"', '"${!0}"', '"${!#}"', '"${!@}"'
    ].each do |expression|
      command = "bin/test #{expression}"
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), expression
    end
  end

  def test_init_rejects_broad_positional_state_in_outer_double_quoted_shell_payloads
    [
      %q(bash -c "printf '%s\\n' \"${@:-fallback}\""),
      %q(bash -c "printf '%s\\n' \"${@#pre}\""),
      %q(bash -c "printf '%s\\n' \"$*\""),
      %q(bash -c "printf '%s\\n' \"$1\"")
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "active outer argument expansion"
    end
  end

  def test_init_rejects_active_outer_bash_indirection_and_special_argument_state
    [
      %q(bash -c "printf '%s\\n' \"${!name}\"" _),
      %q(bash -c "printf '%s\\n' \"$BASH_ARGV\"" _),
      %q(bash -c "printf '%s\\n' \"${BASH_ARGV[*]}\"" _),
      %q(bash -c "printf '%s\\n' \"${#BASH_ARGC}\"" _),
      %q(zsh -c "printf '%s\\n' \"${BASH_ARGV0:-fallback}\"" _)
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "active outer argument expansion"
    end

    [
      %q(bash -c "printf '%s\\n' \"\${!name}\"" _),
      %q(bash -c 'printf "%s\\n" "${BASH_ARGV[*]}"' _),
      %q(bash -c "printf '%s\\n' \"$BASH_ARGV_FOO\"" _)
    ].each do |command|
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_runtime_confirms_outer_bash_indirection_can_inject_the_first_wrapper_argument
    wrapper_line = 'exec bash -c "eval \\"${!name}\\"" _ "$@"'
    runtime_out, runtime_status = Open3.capture2e(
      { "name" => "1" }, "bash", "-c", wrapper_line, "wrapper", "printf INJECTED"
    )
    assert runtime_status.success?, runtime_out
    assert_equal "INJECTED", runtime_out

    command = %q(bash -c "eval \"${!name}\"" _)
    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line(command)
    end
    assert_includes error.message, "active outer argument expansion"
  end

  def test_init_ignores_escaped_or_single_quoted_positional_parameter_literals
    [
      'bin/test \\${@:-fallback}',
      "bin/test '${@#prefix}'",
      'bin/test \\${*:-fallback}',
      "bin/test '${#@}'",
      'bin/test \\${1:-fallback}',
      "bin/test '${0#prefix}'",
      'bin/test \\${!1}',
      "bin/test '${!#}'"
    ].each do |command|
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_keeps_shell_specific_state_expansions_scoped_out_of_generic_commands
    [
      'bin/test "${!name}"',
      'bin/test "$argv"',
      'bin/test "${ARGC}"',
      'bin/test "$ZSH_ARGZERO"',
      'bin/test "${BASH_ARGV[*]}"',
      'bin/test "$BASH_ARGC"',
      'bin/test "${BASH_ARGV0}"',
      'bin/test "${(q)argv}"',
      'bin/test "${^ARGC}"',
      'bin/test "${(P)name}"',
      'bin/test "${(P)${:-argv}}"'
    ].each do |command|
      assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_requires_placeholder_for_zsh_positional_state_expansions
    [
      '"$argv"',
      '"${argv[*]}"',
      '"${argv[1]:-fallback}"',
      '"$ARGC"',
      '"${ARGC:-0}"',
      '"$ZSH_ARGZERO"',
      '"${ZSH_ARGZERO#prefix}"',
      '"${#argv}"',
      '"${#ARGC}"',
      '"${#ZSH_ARGZERO}"',
      '"${(q)argv}"',
      '"${(@)argv}"',
      '"${^argv}"',
      '"${=argv}"',
      '"${~argv}"',
      '"${(q)^argv}"',
      '"${(q)#argv}"',
      '"${(q)ARGC}"',
      '"${^ZSH_ARGZERO}"',
      '"${(j:):)argv}"',
      '"${(P)name}"',
      '"${(P)${:-argv}}"',
      '"${(P)${:-ARGC}}"',
      '"${(P)${:-ZSH_ARGZERO}}"',
      '"${(P)1}"'
    ].each do |expression|
      command = %(zsh -c 'printf "%s\\n" #{expression}')
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, expression) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "zsh -c forwarding requires an explicit $0 placeholder"

      command_with_placeholder = "#{command} _"
      assert_equal %(exec #{command_with_placeholder} "$@"),
                   AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder), expression
    end
  end

  def test_init_requires_placeholder_for_bash_positional_state_expansions
    %w[bash sh].each do |shell|
      [
        '"${!name}"',
        '"${!prefix*}"',
        '"$BASH_ARGV"',
        '"${BASH_ARGV[*]}"',
        '"${#BASH_ARGV}"',
        '"$BASH_ARGC"',
        '"${BASH_ARGC[*]}"',
        '"$BASH_ARGV0"',
        '"${BASH_ARGV0:-fallback}"'
      ].each do |expression|
        command = %(#{shell} -c 'printf "%s\\n" #{expression}')
        error = assert_raises(AgentWorkflowSeamDoctor::InitError, "#{shell} #{expression}") do
          AgentWorkflowSeamDoctor.init_command_line(command)
        end
        assert_includes error.message, "#{shell} -c forwarding requires an explicit $0 placeholder"

        command_with_placeholder = "#{command} _"
        assert_equal %(exec #{command_with_placeholder} "$@"),
                     AgentWorkflowSeamDoctor.init_command_line(command_with_placeholder), expression
      end
    end
  end

  def test_init_ignores_literal_shell_specific_state_expansions_in_shell_payloads
    {
      "zsh" => [
        'printf "%s\\n" \\${argv[*]}',
        %(printf "%s\\n" '$ARGC'),
        'printf "%s\\n" \\${(q)argv}',
        %(printf "%s\\n" '${^argv}'),
        'printf "%s\\n" \\${(j:):)argv}',
        %(printf "%s\\n" '${(P)name}'),
        'printf "%s\\n" \\${(P)${:-argv}}'
      ],
      "bash" => ['printf "%s\\n" \\${!name}', %(printf "%s\\n" '$BASH_ARGV')]
    }.each do |shell, payloads|
      payloads.each do |payload|
        command = "#{shell} -c #{Shellwords.escape(payload)} _"
        assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command), command
      end
    end
  end

  def test_init_does_not_match_bash_special_state_variable_prefixes
    command = 'bash -c \'printf "%s\\n" "$BASH_ARGV_FOO" "${BASH_ARGCOUNT}"\' _'

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_does_not_match_zsh_state_variable_prefixes_after_parameter_flags
    command = 'zsh -c \'printf "%s\\n" "${(q)argv_extra}" "${^ARGCOUNT}"\' _'

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_runtime_confirms_indirect_positional_expansion_shifts_without_a_placeholder
    environment = { "FIRST" => "first-value", "SECOND" => "second-value" }
    payload = 'printf "%s\\n" "${!1}"'

    runtime_out, runtime_status = Open3.capture2e(environment, "bash", "-c", payload, "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "second-value\n", runtime_out

    runtime_out, runtime_status = Open3.capture2e(environment, "bash", "-c", payload, "_", "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "first-value\n", runtime_out
  end

  def test_runtime_confirms_zsh_named_positional_state_shifts_without_a_placeholder
    skip "zsh unavailable" unless executable_available?("zsh")

    payload = 'printf "argv=<%s> argc=<%s> argzero=<%s>\\n" "${argv[*]}" "$ARGC" "$ZSH_ARGZERO"'

    runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "argv=<SECOND> argc=<1> argzero=<FIRST>\n", runtime_out

    runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "_", "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "argv=<FIRST SECOND> argc=<2> argzero=<_>\n", runtime_out
  end

  def test_runtime_confirms_zsh_parameter_flag_forms_shift_without_a_placeholder
    skip "zsh unavailable" unless executable_available?("zsh")

    %w[${(q)argv} ${(@)argv} ${^argv} ${=argv} ${~argv} ${(q)^argv} ${(q)#argv}].each do |expression|
      payload = %(printf "<%s>\\n" "#{expression}")
      runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "FIRST", "SECOND")
      assert runtime_status.success?, runtime_out
      refute_includes runtime_out, "FIRST", expression
      without_placeholder = runtime_out

      runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "_", "FIRST", "SECOND")
      assert runtime_status.success?, runtime_out
      refute_equal without_placeholder, runtime_out, expression
    end
  end

  def test_runtime_confirms_zsh_delimited_flags_and_indirection_shift_without_a_placeholder
    skip "zsh unavailable" unless executable_available?("zsh")

    {
      "${(j:):)argv}" => ["<SECOND>\n", "<FIRST)SECOND>\n"],
      "${(P)name}" => ["<SECOND>\n", "<FIRST SECOND>\n"]
    }.each do |expression, expected|
      assignment = expression.include?("(P)") ? "name=argv; " : ""
      payload = %(#{assignment}printf "<%s>\\n" "#{expression}")

      runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "FIRST", "SECOND")
      assert runtime_status.success?, runtime_out
      assert_equal expected.fetch(0), runtime_out

      runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "_", "FIRST", "SECOND")
      assert runtime_status.success?, runtime_out
      assert_equal expected.fetch(1), runtime_out
    end
  end

  def test_runtime_confirms_zsh_nested_and_numeric_indirection_targets
    skip "zsh unavailable" unless executable_available?("zsh")

    {
      "${(P)${:-argv}}" => ["<SECOND>\n", "<FIRST SECOND>\n"],
      "${(P)${:-ARGC}}" => ["<1>\n", "<2>\n"],
      "${(P)${:-ZSH_ARGZERO}}" => ["<FIRST>\n", "<_>\n"]
    }.each do |expression, expected|
      payload = %(printf "<%s>\\n" "#{expression}")
      runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "FIRST", "SECOND")
      assert runtime_status.success?, runtime_out
      assert_equal expected.fetch(0), runtime_out

      runtime_out, runtime_status = Open3.capture2e("zsh", "-c", payload, "_", "FIRST", "SECOND")
      assert runtime_status.success?, runtime_out
      assert_equal expected.fetch(1), runtime_out
    end

    environment = { "FIRST" => "first-value", "SECOND" => "second-value" }
    payload = 'printf "<%s>\\n" "${(P)1}"'
    runtime_out, runtime_status = Open3.capture2e(environment, "zsh", "-c", payload, "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "<second-value>\n", runtime_out
    runtime_out, runtime_status = Open3.capture2e(environment, "zsh", "-c", payload, "_", "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "<first-value>\n", runtime_out
  end

  def test_runtime_confirms_bash_special_arrays_shift_without_a_placeholder
    payload = 'printf "argv=<%s> argc=<%s>\\n" "${BASH_ARGV[*]}" "${BASH_ARGC[*]}"'

    runtime_out, runtime_status = Open3.capture2e("bash", "-c", payload, "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "argv=<SECOND> argc=<1>\n", runtime_out

    runtime_out, runtime_status = Open3.capture2e("bash", "-c", payload, "_", "FIRST", "SECOND")
    assert runtime_status.success?, runtime_out
    assert_equal "argv=<SECOND FIRST> argc=<2>\n", runtime_out
  end

  def test_runtime_confirms_braced_at_operators_shift_without_a_placeholder
    {
      "${@:-fallback}" => { without_placeholder: "prefixSECOND\n", with_placeholder: "prefixFIRST\nprefixSECOND\n" },
      "${@#prefix}" => { without_placeholder: "SECOND\n", with_placeholder: "FIRST\nSECOND\n" }
    }.each do |expression, expected|
      payload = %(printf "%s\\n" "#{expression}")
      runtime_out, runtime_status = Open3.capture2e("bash", "-c", payload, "prefixFIRST", "prefixSECOND")
      assert runtime_status.success?, runtime_out
      assert_equal expected.fetch(:without_placeholder), runtime_out

      runtime_out, runtime_status = Open3.capture2e(
        "bash", "-c", payload, "_", "prefixFIRST", "prefixSECOND"
      )
      assert runtime_status.success?, runtime_out
      assert_equal expected.fetch(:with_placeholder), runtime_out
    end
  end

  def test_init_rejects_an_assignment_only_command_with_quoted_forwarding_text
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "LABEL='\$@'",
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "assignment-only commands cannot safely forward wrapper arguments"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_rejects_argument_forwarding_text_inside_a_shell_comment
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", 'bin/validate # "$@" is documentation',
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "argument-forwarding text inside a shell comment is ambiguous"
      refute File.exist?(File.join(root, ".agents/bin/validate"))
    end
  end

  def test_init_allows_commented_forwarding_text_after_real_outer_forwarding
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = 'echo "$@" # caller forwards "$@"'
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), "#{command}\n"
    end
  end

  def test_init_escapes_pipes_in_the_generated_readme_table
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = 'bin/validate "$@" | tee validate.log'
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      readme = File.read(File.join(root, ".agents/bin/README.md"))
      assert_includes readme, '| `validate` | Pre-push gate | `bin/validate "$@" \| tee validate.log` |'
      refute_includes readme, '| `bin/validate "$@" | tee validate.log` |'
    end
  end

  def test_init_uses_a_safe_markdown_code_span_for_commands_with_backticks
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = %q(echo \`date\`)
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      readme = File.read(File.join(root, ".agents/bin/README.md"))
      assert_includes readme, '| `validate` | Pre-push gate | `` echo \`date\` `` |'
      refute_includes readme, '| `validate` | Pre-push gate | `echo \`date\`` |'
    end
  end

  def test_init_ignores_fenced_pointer_headings_and_preserves_the_example
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      example = <<~MARKDOWN
        # AGENTS.md

        ## Example

        ```markdown
        ## Agent Workflow Configuration

        Example content that must remain fenced.
        ```

        ## Existing Guidance

        Keep this guidance.
      MARKDOWN
      File.write(File.join(root, "AGENTS.md"), example)

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      assert status.success?, out
      agents = File.read(File.join(root, "AGENTS.md"), encoding: "UTF-8")
      assert agents.start_with?(example)
      assert_includes agents, "Example content that must remain fenced.\n```"
      assert_equal 2, agents.scan("## Agent Workflow Configuration").length
      assert_includes agents, "Keep this guidance."
    end
  end

  def test_init_rejects_one_explicit_command_before_writing
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(root, "--init", "--validate-command", "true")

      refute status.success?
      assert_includes out, "--validate-command and --test-command must be provided together"
      refute File.exist?(File.join(root, ".agents"))
      refute File.exist?(File.join(root, "AGENTS.md"))
    end
  end

  def test_init_reports_missing_root_before_an_incomplete_explicit_command_pair
    Dir.mktmpdir("agent-workflow-seam-init") do |parent|
      missing = File.join(parent, "missing")
      out, status = run_doctor(missing, "--init", "--validate-command", "true")

      refute status.success?
      assert_includes out, "missing directory: #{missing}"
      refute_includes out, "must be provided together"
    end
  end

  def test_init_rejects_explicit_commands_that_would_replace_repo_owned_wrappers
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents/bin"))
      validate_path = write_script(root, "validate", "exec echo repo-validate \"$@\"\n")
      test_path = write_script(root, "test", "exec echo repo-test \"$@\"\n")
      before = { validate_path => File.binread(validate_path), test_path => File.binread(test_path) }

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "echo replacement-validate",
        "--test-command", "echo replacement-test"
      )

      refute status.success?
      assert_includes out, "explicit commands cannot replace repo-owned wrappers"
      assert_includes out, ".agents/bin/validate"
      assert_includes out, ".agents/bin/test"
      after = before.keys.to_h { |path| [path, File.binread(path)] }
      assert_equal before, after
      refute File.exist?(File.join(root, ".agents/bin/README.md"))
      refute File.exist?(File.join(root, ".agents/agent-workflow.yml"))
      refute File.exist?(File.join(root, "AGENTS.md"))
    end
  end

  def test_init_api_rejects_one_explicit_command_before_writing
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
        AgentWorkflowSeamDoctor.init(
          root,
          base_branch: "main",
          validate_command: "true",
          test_command: nil
        )
      end

      assert_includes error.message, "--validate-command and --test-command must be provided together"
      refute File.exist?(File.join(root, ".agents"))
      refute File.exist?(File.join(root, "AGENTS.md"))
    end
  end

  def test_init_unknown_repo_writes_fail_closed_wrappers_and_precise_next_step
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(root, "--init")

      refute status.success?
      assert_includes out, "unconfigured init wrapper: .agents/bin/validate"
      assert_includes out, "rerun --init with both --validate-command CMD and --test-command CMD"
      validate = File.read(File.join(root, ".agents/bin/validate"))
      assert_includes validate, "# Agent workflow seam init: command not configured."

      checked_out, checked_status = run_doctor(root)
      refute checked_status.success?
      assert_includes checked_out, "unconfigured init wrapper: .agents/bin/validate"
    end
  end

  def test_init_detects_executable_root_validate_and_test_commands
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      %w[validate test].each do |name|
        path = File.join(root, "bin", name)
        File.write(path, "#!/usr/bin/env bash\nexit 0\n")
        File.chmod(0o755, path)
      end

      out, status = run_doctor(root, "--init")

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec bin/validate "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'exec bin/test "$@"'
    end
  end

  def test_init_detects_exact_javascript_scripts_with_runner_specific_argument_forwarding
    {
      "package-lock.json" => 'exec npm run validate -- "$@"',
      "pnpm-lock.yaml" => 'exec pnpm run validate "$@"',
      "yarn.lock" => 'exec yarn run validate "$@"'
    }.each do |lockfile, expected_validate|
      Dir.mktmpdir("agent-workflow-seam-init") do |root|
        File.write(File.join(root, "package.json"), JSON.generate("scripts" => { "validate" => "check", "test" => "spec" }))
        File.write(File.join(root, lockfile), "lock\n")

        out, status = run_doctor(root, "--init")

        assert status.success?, "#{lockfile}: #{out}"
        assert_includes File.read(File.join(root, ".agents/bin/validate")), expected_validate
      end
    end
  end

  def test_init_explicit_javascript_runner_commands_use_runner_specific_argument_forwarding
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm run validate",
        "--test-command", "pnpm run test"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      test = File.read(File.join(root, ".agents/bin/test"))
      assert_includes validate, 'exec npm run validate -- "$@"'
      assert_includes test, 'exec pnpm run test "$@"'
      refute_includes test, 'pnpm run test -- "$@"'
    end
  end

  def test_init_does_not_duplicate_a_leading_exec
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "exec bundle exec rake validate",
        "--test-command", "exec npm run test"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      test = File.read(File.join(root, ".agents/bin/test"))
      assert_includes validate, 'exec bundle exec rake validate "$@"'
      refute_includes validate, "exec exec"
      assert_includes test, 'exec npm run test -- "$@"'
      refute_includes test, "exec exec"
    end
  end

  def test_init_normalizes_npm_after_option_bearing_exec_prefixes
    {
      "exec -a npm npm run validate" => 'exec -a npm npm run validate -- "$@"',
      "exec -a npm -- npm run validate" => 'exec -a npm -- npm run validate -- "$@"',
      "CI=1 exec -cl -a npm -- npm run validate" =>
        'CI=1 exec -cl -a npm -- npm run validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_fails_closed_for_malformed_option_bearing_exec_prefixes
    ["exec -a", "exec -a npm", "exec -x npm run validate", "exec -a npm --"].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "cannot safely parse exec command prefix"
      refute_includes error.message, command
    end
  end

  def test_init_preserves_runtime_caller_options_through_an_option_bearing_exec_prefix
    Dir.mktmpdir("agent-workflow-seam-init-exec-npm") do |root|
      marker = File.join(root, "args.json")
      node_program = 'require("fs").writeFileSync(process.env.MARKER, JSON.stringify(process.argv.slice(1)))'
      File.write(
        File.join(root, "package.json"),
        JSON.generate(
          "name" => "exec-prefix-runtime",
          "version" => "1.0.0",
          "scripts" => { "capture" => "node -e #{Shellwords.escape(node_program)} --" }
        )
      )
      command = AgentWorkflowSeamDoctor.init_command_line("exec -a npm -- npm run capture")

      out, status = Open3.capture2e(
        { "MARKER" => marker }, "bash", "-c", command, "_", "--caller-option", chdir: root
      )

      assert status.success?, out
      assert_equal ["--caller-option"], JSON.parse(File.read(marker))
    end
  end

  def test_init_normalizes_outer_command_whitespace_before_classification
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "  exec true  ",
        "--test-command", "  CI=1 npm run test  "
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      test = File.read(File.join(root, ".agents/bin/test"))
      assert_includes validate, 'exec true "$@"'
      refute_includes validate, "exec  exec"
      assert_includes test, 'CI=1 npm run test -- "$@"'
      refute_includes test, "exec  CI=1"
    end
  end

  def test_init_adds_npm_separator_after_leading_environment_assignments
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "CI=1 npm run validate",
        "--test-command", "CI=1 LABEL='test suite' exec npm run test"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      test = File.read(File.join(root, ".agents/bin/test"))
      assert_includes validate, 'CI=1 npm run validate -- "$@"'
      assert_includes test, %(CI=1 LABEL='test suite' exec npm run test -- "$@")
    end
  end

  def test_init_adds_npm_separator_after_npm_options
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm --prefix app run validate",
        "--test-command", "CI=1 npm --workspace packages/core --silent run test"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      test = File.read(File.join(root, ".agents/bin/test"))
      assert_includes validate, 'exec npm --prefix app run validate -- "$@"'
      assert_includes test, 'CI=1 npm --workspace packages/core --silent run test -- "$@"'
    end
  end

  def test_init_consumes_separated_npm_option_values_before_finding_the_lifecycle_command
    assert_equal 'exec npm --prefix test run validate -- "$@"',
                 AgentWorkflowSeamDoctor.init_command_line("npm --prefix test run validate")
    assert_equal 'exec npm --workspace run test -- "$@"',
                 AgentWorkflowSeamDoctor.init_command_line("npm --workspace run test")
  end

  def test_init_consumes_attached_npm_option_values_before_finding_the_lifecycle_command
    assert_equal 'exec npm --prefix=test run validate -- "$@"',
                 AgentWorkflowSeamDoctor.init_command_line("npm --prefix=test run validate")
    assert_equal 'exec npm --workspace=run test -- "$@"',
                 AgentWorkflowSeamDoctor.init_command_line("npm --workspace=run test")
  end

  def test_init_consumes_supported_npm_options_between_run_and_the_script_operand
    {
      "npm run --workspace packages/core validate" =>
        'exec npm run --workspace packages/core validate -- "$@"',
      "npm run --workspace=packages/core validate" =>
        'exec npm run --workspace=packages/core validate -- "$@"',
      "npm run --silent validate" =>
        'exec npm run --silent validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_adds_npm_separator_for_run_script_alias
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm run-script validate",
        "--test-command", "npm --prefix app run-script test"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec npm run-script validate -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'exec npm --prefix app run-script test -- "$@"'
    end
  end

  def test_init_adds_npm_separator_for_run_aliases
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm rum validate",
        "--test-command", "npm urn test"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec npm rum validate -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'exec npm urn test -- "$@"'
    end
  end

  def test_init_adds_npm_separator_for_test_lifecycle_command
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm --prefix app test",
        "--test-command", "npm test"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec npm --prefix app test -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'exec npm test -- "$@"'
    end
  end

  def test_init_adds_npm_separator_for_test_aliases
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm --prefix app tst",
        "--test-command", "npm t"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec npm --prefix app tst -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'exec npm t -- "$@"'
    end
  end

  def test_init_adds_npm_separator_after_env_utility_assignments
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "env CI=1 npm run validate",
        "--test-command", "/usr/bin/env LABEL='test suite' npm run-script test"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec env CI=1 npm run validate -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")),
                      %(exec /usr/bin/env LABEL='test suite' npm run-script test -- "$@")
    end
  end

  def test_init_adds_npm_separator_after_env_utility_options
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "env -u CI npm run validate",
        "--test-command", "env --chdir app --ignore-environment npm run-script test"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec env -u CI npm run validate -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'exec env --chdir app --ignore-environment npm run-script test -- "$@"'
    end
  end

  def test_init_adds_npm_separator_after_clustered_env_utility_options
    {
      "env -iv npm run validate" => 'exec env -iv npm run validate -- "$@"',
      "env -iuCI npm run validate" => 'exec env -iuCI npm run validate -- "$@"',
      "env -iC/tmp npm run validate" => 'exec env -iC/tmp npm run validate -- "$@"',
      "env --unset=CI --chdir=/tmp npm run validate" =>
        'exec env --unset=CI --chdir=/tmp npm run validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command)
    end
  end

  def test_init_preserves_env_split_string_commands_verbatim
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      validate_command = "env -S 'npm run validate' \"$@\""
      test_command = "env --split-string='npm run test' \"$@\""
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", validate_command,
        "--test-command", test_command
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      test = File.read(File.join(root, ".agents/bin/test"))
      assert_includes validate, "#{validate_command}\n"
      refute_includes validate, "#{validate_command} \"$@\""
      assert_includes test, "#{test_command}\n"
      refute_includes test, "#{test_command} \"$@\""
    end
  end

  def test_init_adds_npm_separator_after_env_option_terminator
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "env -- npm run validate",
        "--test-command", "env -- npm run-script test"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec env -- npm run validate -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), 'exec env -- npm run-script test -- "$@"'
    end
  end

  def test_init_adds_npm_separator_before_caller_supplied_argument_forwarding
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", 'npm run validate "$@"',
        "--test-command", "CI=1 npm run-script test \$@"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")), 'exec npm run validate -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")), "CI=1 npm run-script test -- \$@"
    end
  end

  def test_init_adds_npm_separator_immediately_after_script_operand_with_existing_arguments
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", 'npm run validate --grep smoke "$@"',
        "--test-command", "npm test --watch=false"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")),
                      'exec npm run validate -- --grep smoke "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")),
                      'exec npm test -- --watch=false "$@"'
    end
  end

  def test_init_preserves_an_npm_run_option_terminator_without_adding_a_script_separator
    {
      "npm run -- validate" => 'exec npm run -- validate "$@"',
      "npm run -- validate --watch" => 'exec npm run -- validate --watch "$@"',
      'npm run -- validate -- "$@"' => 'exec npm run -- validate -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command), command
    end

    assert_equal 'exec npm -- run validate "$@"',
                 AgentWorkflowSeamDoctor.init_command_line("npm -- run validate")
  end

  def test_init_preserves_runtime_caller_options_after_an_npm_run_option_terminator
    Dir.mktmpdir("agent-workflow-seam-init-npm-terminator") do |root|
      marker = File.join(root, "args.json")
      node_program = 'require("fs").writeFileSync(process.env.MARKER, JSON.stringify(process.argv.slice(1)))'
      File.write(
        File.join(root, "package.json"),
        JSON.generate(
          "name" => "npm-terminator-runtime",
          "version" => "1.0.0",
          "scripts" => { "capture" => "node -e #{Shellwords.escape(node_program)} --" }
        )
      )
      command = AgentWorkflowSeamDoctor.init_command_line("npm run -- capture")

      out, status = Open3.capture2e(
        { "MARKER" => marker }, "bash", "-c", command, "_", "--silent", "CALLER", chdir: root
      )

      assert status.success?, out
      assert_equal ["--silent", "CALLER"], JSON.parse(File.read(marker))
    end
  end

  def test_init_repositions_a_late_npm_separator_without_duplicating_it
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", 'npm run validate --grep smoke -- "$@"',
        "--test-command", "true"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      assert_includes validate, 'exec npm run validate -- --grep smoke "$@"'
      refute_includes validate, '-- --grep smoke -- "$@"'
    end
  end

  def test_init_moves_known_npm_options_before_positional_script_arguments
    assert_equal 'exec npm run validate --workspace packages/core -- smoke "$@"',
                 AgentWorkflowSeamDoctor.init_command_line(
                   "npm run validate smoke --workspace packages/core"
                 )
    assert_equal 'exec npm run validate --workspace packages/core -- smoke "$@"',
                 AgentWorkflowSeamDoctor.init_command_line(
                   'npm run validate smoke --workspace packages/core -- "$@"'
                 )
  end

  def test_init_keeps_unknown_script_options_ordered_after_known_npm_options
    assert_equal 'exec npm run validate --workspace packages/core -- --grep smoke --watch=false "$@"',
                 AgentWorkflowSeamDoctor.init_command_line(
                   "npm run validate --grep smoke --workspace packages/core --watch=false"
                 )
  end

  def test_init_recognizes_unique_npm_long_option_abbreviations
    assert_equal 'exec npm test --sil -- smoke "$@"',
                 AgentWorkflowSeamDoctor.init_command_line("npm test smoke --sil")
    assert_equal 'exec npm test -- smoke --worksp packages/core "$@"',
                 AgentWorkflowSeamDoctor.init_command_line(
                   "npm test smoke --worksp packages/core"
                 )
  end

  def test_init_preserves_workspace_execution_when_a_known_option_follows_a_script_argument
    Dir.mktmpdir("agent-workflow-seam-init-npm") do |root|
      marker = File.join(root, "which-script")
      node_program = "require('fs').writeFileSync(process.argv[1], process.argv[2] + ':' + " \
                     "JSON.stringify(process.argv.slice(3)))"
      script = lambda do |label|
        "node -e #{Shellwords.escape(node_program)} #{Shellwords.escape(marker)} #{label}"
      end
      File.write(
        File.join(root, "package.json"),
        JSON.generate(
          "name" => "root",
          "version" => "1.0.0",
          "workspaces" => ["packages/*"],
          "scripts" => { "echoargs" => script.call("ROOT") }
        )
      )
      workspace = File.join(root, "packages/core")
      FileUtils.mkdir_p(workspace)
      File.write(
        File.join(workspace, "package.json"),
        JSON.generate(
          "name" => "core",
          "version" => "1.0.0",
          "scripts" => { "echoargs" => script.call("WORKSPACE") }
        )
      )

      command = AgentWorkflowSeamDoctor.init_command_line(
        "npm run echoargs smoke --workspace packages/core --"
      )
      out, status = Open3.capture2e("bash", "-c", command, chdir: root)

      assert status.success?, out
      assert_equal 'WORKSPACE:["smoke"]', File.read(marker)
    end
  end

  def test_init_preserves_an_immediate_npm_separator_as_authoritative
    command = "npm run validate -- --workspace packages/core --grep smoke"

    assert_equal %(exec #{command} "$@"), AgentWorkflowSeamDoctor.init_command_line(command)
  end

  def test_init_preserves_an_existing_npm_separator_after_the_option_prefix
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      command = 'npm run validate --omit=dev -- --grep smoke "$@"'
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", command,
        "--test-command", "true"
      )

      assert status.success?, out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      assert_includes validate, "exec #{command}"
      refute_includes validate, "npm run validate -- -- --grep"
    end
  end

  def test_init_preserves_npm_cli_options_after_the_script_operand
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm run validate --workspace packages/core",
        "--test-command", "npm test --ignore-scripts"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")),
                      'exec npm run validate --workspace packages/core -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")),
                      'exec npm test --ignore-scripts -- "$@"'
    end
  end

  def test_init_preserves_generic_npm_cli_options_after_the_script_operand
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm run validate --loglevel silent",
        "--test-command", "npm test --silent"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")),
                      'exec npm run validate --loglevel silent -- "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")),
                      'exec npm test --silent -- "$@"'
    end
  end

  def test_init_uses_exact_npm_config_key_and_arity_metadata_before_script_arguments
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm run validate --omit=dev --color=false -w2 --grep smoke",
        "--test-command", "npm test --omit dev --silent intent"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")),
                      'exec npm run validate --omit=dev --color=false -w2 -- --grep smoke "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")),
                      'exec npm test --omit dev --silent -- intent "$@"'
    end
  end

  def test_init_consumes_separated_optional_npm_config_values
    {
      "npm run validate --audit false" => 'exec npm run validate --audit false -- "$@"',
      "npm run validate --color always" => 'exec npm run validate --color always -- "$@"',
      "npm run validate --col always" => 'exec npm run validate --col always -- "$@"',
      "npm run validate --no-audit false" => 'exec npm run validate --no-audit false -- "$@"',
      "npm run validate --ignore-scripts false" =>
        'exec npm run validate --ignore-scripts false -- "$@"',
      "npm run validate -g false" => 'exec npm run validate -g false -- "$@"',
      "npm run validate -n false" => 'exec npm run validate -n false -- "$@"',
      "npm run validate --ws false" => 'exec npm run validate --ws false -- "$@"',
      "npm run validate --browser firefox" => 'exec npm run validate --browser firefox -- "$@"',
      'npm --browser "" run validate' => 'exec npm --browser "" run validate "$@"',
      "npm --browser - run validate" => 'exec npm --browser - run validate -- "$@"',
      "npm run validate --audit" => 'exec npm run validate --audit -- "$@"',
      "npm run validate --audit --color always" =>
        'exec npm run validate --audit --color always -- "$@"',
      "npm run validate --audit false -- --grep smoke" =>
        'exec npm run validate --audit false -- --grep smoke "$@"',
      "npm --audit false run validate" => 'exec npm --audit false run validate -- "$@"',
      "npm --audit run validate" => 'exec npm --audit run validate -- "$@"',
      "npm run --audit validate" => 'exec npm run --audit validate -- "$@"',
      "npm --optional null run validate" => 'exec npm --optional null run validate -- "$@"',
      "npm --optional run validate" => 'exec npm --optional run validate -- "$@"',
      "npm --color always run validate" => 'exec npm --color always run validate -- "$@"',
      "npm --color run validate" => 'exec npm --color run validate -- "$@"',
      "npm run --color always validate" => 'exec npm run --color always validate -- "$@"',
      "npm -g false test" => 'exec npm -g false test -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_preserves_optional_npm_values_in_a_generated_wrapper_at_runtime
    Dir.mktmpdir("agent-workflow-seam-init-npm") do |root|
      {
        ["audit", "--audit", "false"] => "false",
        ["color", "--color", "always"] => "always",
        ["global", "-g", "false"] => "false",
        ["audit", "--no-audit", "false"] => "true",
        ["yes", "-n", "false"] => "true",
        ["workspaces", "--ws", "false"] => "false",
        ["optional", "--optional", "null"] => "null"
      }.each do |arguments, expected|
        config_out, config_status = Open3.capture2e("npm", "config", "get", *arguments)
        assert config_status.success?, config_out
        assert_equal expected, config_out.lines.last.to_s.strip, arguments.join(" ")
      end

      marker = File.join(root, "npm-options.json")
      node_program = <<~'JAVASCRIPT'.tr("\n", " ").strip
        require("fs").writeFileSync(process.env.MARKER, JSON.stringify({
          args: process.argv.slice(1)
        }))
      JAVASCRIPT
      File.write(
        File.join(root, "package.json"),
        JSON.generate(
          "name" => "npm-options-runtime",
          "version" => "1.0.0",
          "scripts" => { "capture" => "node -e #{Shellwords.escape(node_program)}" }
        )
      )
      command = AgentWorkflowSeamDoctor.init_command_line(
        "npm run capture --audit false --color always -g false"
      )

      out, status = Open3.capture2e(
        { "MARKER" => marker }, "bash", "-c", command, "_", "CALLER", chdir: root
      )

      assert status.success?, out
      assert_equal({ "args" => ["CALLER"] }, JSON.parse(File.read(marker)))

      ["npm --audit run capture", "npm run --audit capture", "npm --browser - run capture"].each do |source|
        command = AgentWorkflowSeamDoctor.init_command_line(source)
        out, status = Open3.capture2e(
          { "MARKER" => marker }, "bash", "-c", command, "_", "CALLER", chdir: root
        )

        assert status.success?, out
        assert_equal({ "args" => ["CALLER"] }, JSON.parse(File.read(marker)), source)
      end

      FileUtils.rm_f(marker)
      command = AgentWorkflowSeamDoctor.init_command_line('npm --browser "" run capture')
      out, status = Open3.capture2e(
        { "MARKER" => marker }, "bash", "-c", command, "_", "CALLER", chdir: root
      )
      refute status.success?, out
      refute File.exist?(marker), out
    end
  end

  def test_init_rejects_a_post_script_required_npm_option_without_a_value
    error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
      AgentWorkflowSeamDoctor.init_command_line("npm run validate -w")
    end

    assert_includes error.message, 'npm option "-w" requires a value'
    assert_includes error.message, "place npm options before the script name"
  end

  def test_init_rejects_complete_forwarding_as_a_required_npm_option_value_in_every_phase
    ['"$@"', '"${@}"', "$@", "${@}"].each do |forwarding|
      [
        "npm --workspace #{forwarding} run validate",
        "npm run --workspace #{forwarding} validate",
        "npm run validate --workspace #{forwarding}"
      ].each do |command|
        error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
          AgentWorkflowSeamDoctor.init_command_line(command)
        end
        assert_includes error.message, "requires a literal value, not complete argument forwarding"
        assert_includes error.message, "put -- immediately after the script operand"
      end
    end
  end

  def test_init_rejects_active_positional_state_in_attached_required_npm_option_values
    [
      'npm --prefix="$@" run validate',
      "npm --prefix=$@ run validate",
      'npm run --workspace="${@}" validate',
      "npm run --workspace=${@} validate",
      'npm run validate --workspace="$@"',
      "npm run validate --workspace=$@",
      'npm run -w"$@" validate',
      "npm run validate -w$@"
    ].each do |command|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError, command) do
        AgentWorkflowSeamDoctor.init_command_line(command)
      end
      assert_includes error.message, "requires a literal value"
      assert_includes error.message, "put -- immediately after the script operand"
      refute_includes error.message, "$@"
      refute_includes error.message, "${@}"
    end
  end

  def test_init_preserves_literal_positional_text_in_attached_required_npm_option_values
    {
      'npm --prefix=\$@ run validate' => 'exec npm --prefix=\$@ run validate -- "$@"',
      "npm --prefix='$@' run validate" => "exec npm --prefix='$@' run validate -- \"$@\"",
      'npm run validate -w\$@' => 'exec npm run validate -w\$@ -- "$@"',
      "npm run validate -w'$@'" => "exec npm run validate -w'$@' -- \"$@\""
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_preserves_literal_required_npm_values_and_forwarding_after_a_real_separator
    {
      "npm --workspace packages/core run validate" =>
        'exec npm --workspace packages/core run validate -- "$@"',
      "npm run --workspace packages/core validate" =>
        'exec npm run --workspace packages/core validate -- "$@"',
      "npm run validate --workspace packages/core" =>
        'exec npm run validate --workspace packages/core -- "$@"',
      'npm run validate -- --workspace "$@"' =>
        'exec npm run validate -- --workspace "$@"',
      "npm run validate --enjoy-by tomorrow" =>
        'exec npm run validate --enjoy-by tomorrow -- "$@"'
    }.each do |command, expected|
      assert_equal expected, AgentWorkflowSeamDoctor.init_command_line(command), command
    end
  end

  def test_init_preserves_dash_prefixed_values_for_required_npm_options
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "npm run validate --workspace --grep smoke",
        "--test-command", "npm test --node-options --max-old-space-size=4096 --watch=false"
      )

      assert status.success?, out
      assert_includes File.read(File.join(root, ".agents/bin/validate")),
                      'exec npm run validate --workspace --grep -- smoke "$@"'
      assert_includes File.read(File.join(root, ".agents/bin/test")),
                      'exec npm test --node-options --max-old-space-size=4096 -- --watch=false "$@"'
      assert_equal 'exec npm test --node-options=--max-old-space-size=4096 -- --watch=false "$@"',
                   AgentWorkflowSeamDoctor.init_command_line(
                     "npm test --node-options=--max-old-space-size=4096 --watch=false"
                   )
    end
  end

  def test_init_uses_vendored_npm_metadata_without_an_npm_executable
    original_path = ENV.fetch("PATH", nil)
    ENV["PATH"] = "/nonexistent"

    command = AgentWorkflowSeamDoctor.init_command_line(
      "npm test -ddd --quiet --yes --production --no-production --no-audit --npm-version 11.6.0 --watch=false"
    )

    assert_equal "exec npm test -ddd --quiet --yes --production --no-production --no-audit " \
                 '--npm-version 11.6.0 -- --watch=false "$@"',
                 command
  ensure
    ENV["PATH"] = original_path
  end

  def test_init_appends_missing_yaml_keys_without_losing_comments_or_formatting
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents"))
      policy_path = File.join(root, ".agents/agent-workflow.yml")
      trust_path = File.join(root, ".agents/trusted-github-actors.yml")
      policy_prefix = <<~YAML
        # Keep this policy guidance.
        base_branch: develop # deployment branch
        custom_policy: "keep quoted"
      YAML
      trust_prefix = <<~YAML
        # Keep this trust guidance.
        trusted_users:
          - maintainer # release owner
      YAML
      File.write(policy_path, policy_prefix)
      File.write(trust_path, trust_prefix)

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      assert status.success?, out
      assert File.read(policy_path).start_with?(policy_prefix)
      assert File.read(trust_path).start_with?(trust_prefix)
      policy = YAML.safe_load(File.read(policy_path))
      trust = YAML.safe_load(File.read(trust_path))
      assert_equal "develop", policy.fetch("base_branch")
      assert_equal "keep quoted", policy.fetch("custom_policy")
      assert_equal [], trust.fetch("trusted_bots")
      assert_equal ["github-actions"], trust.fetch("trusted_metadata_bots")
      assert_equal [], trust.fetch("trusted_teams")
    end
  end

  def test_init_fails_before_writing_when_existing_yaml_cannot_be_safely_appended
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents"))
      policy_path = File.join(root, ".agents/agent-workflow.yml")
      original = "{base_branch: develop} # keep flow style\n"
      File.write(policy_path, original)

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "cannot safely add missing policy config keys without rewriting"
      assert_equal original, File.read(policy_path)
      refute File.exist?(File.join(root, ".agents/bin"))
      refute File.exist?(File.join(root, "AGENTS.md"))
    end
  end

  def test_init_reports_filesystem_errors_without_a_backtrace
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents/bin/validate"))

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "FAIL agent workflow seam has 1 issue(s)"
      refute_includes out, "agent-workflow-seam-doctor:"
      refute_includes out, "Errno::EISDIR"
    end
  end

  def test_init_treats_non_object_package_json_as_unknown
    [[], "package", 1, nil].each do |package|
      Dir.mktmpdir("agent-workflow-seam-init") do |root|
        File.write(File.join(root, "package.json"), JSON.generate(package))
        File.write(File.join(root, "package-lock.json"), "lock\n")

        out, status = run_doctor(root, "--init")

        refute status.success?
        assert_includes out, "unconfigured init wrapper"
        refute_includes out, "TypeError"
        refute_includes out, "NoMethodError"
      end
    end
  end

  def test_init_treats_invalid_utf8_package_json_as_unknown
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      File.binwrite(File.join(root, "package.json"), "{\xFF}".b)
      File.write(File.join(root, "package-lock.json"), "lock\n")

      out, status = run_doctor(root, "--init")

      refute status.success?
      assert_includes out, "unconfigured init wrapper"
      refute_includes out, "invalid byte sequence"
      refute_includes out, "Encoding::"
    end
  end

  def test_init_does_not_detect_blank_javascript_scripts
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      File.write(File.join(root, "package.json"), JSON.generate("scripts" => { "validate" => " ", "test" => "spec" }))
      File.write(File.join(root, "package-lock.json"), "lock\n")

      out, status = run_doctor(root, "--init")

      refute status.success?
      assert_includes out, "unconfigured init wrapper"
    end
  end

  def test_init_json_reports_shared_root_validation_failures
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      missing_shared = File.join(root, "missing-shared")
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true",
        "--shared", missing_shared,
        "--json"
      )

      refute status.success?
      payload = JSON.parse(out)
      assert_equal "FAIL", payload.fetch("status")
      assert_includes payload.fetch("issues"), "missing shared root: #{missing_shared}"
    end
  end

  def test_init_preserves_an_existing_valid_seam_and_is_idempotent
    with_repo do |root|
      write_valid_binstub_contract(root)
      trust_path = File.join(root, ".agents/trusted-github-actors.yml")
      File.write(trust_path, {
        "trusted_users" => ["maintainer"],
        "trusted_bots" => [],
        "trusted_metadata_bots" => ["github-actions"],
        "trusted_teams" => []
      }.to_yaml)
      paths = [
        "AGENTS.md",
        ".agents/bin/README.md",
        ".agents/bin/validate",
        ".agents/bin/test",
        ".agents/agent-workflow.yml",
        ".agents/trusted-github-actors.yml"
      ]
      before = paths.to_h { |path| [path, File.binread(File.join(root, path))] }

      out, status = run_doctor(root, "--init")
      assert status.success?, out
      second_out, second_status = run_doctor(root, "--init")
      assert second_status.success?, second_out

      after = paths.to_h { |path| [path, File.binread(File.join(root, path))] }
      assert_equal before, after
    end
  end

  def test_init_readme_records_existing_optional_wrappers
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents/bin"))
      write_script(root, "lint", "exec echo lint \"$@\"\n")

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      assert status.success?, out
      readme = File.read(File.join(root, ".agents/bin/README.md"))
      assert_includes readme, "| `lint` | Lint / format | configured wrapper |"
      refute_includes readme, "| `lint` | Lint / format | n/a |"
    end
  end

  def test_bare_init_refreshes_managed_readme_for_new_optional_wrapper
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      first_out, first_status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )
      assert first_status.success?, first_out
      refute_includes File.read(File.join(root, ".agents/bin/README.md")), "| `lint` | Lint / format | configured wrapper |"
      write_script(root, "lint", "exec echo lint \"$@\"\n")

      second_out, second_status = run_doctor(root, "--init")

      assert second_status.success?, second_out
      assert_includes File.read(File.join(root, ".agents/bin/README.md")), "| `lint` | Lint / format | configured wrapper |"
    end
  end

  def test_init_preserves_scalar_trust_entries_accepted_by_preflight
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents"))
      trust_path = File.join(root, ".agents/trusted-github-actors.yml")
      File.write(trust_path, "trusted_bots: deploy\n")

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      assert status.success?, out
      trust = YAML.safe_load(File.read(trust_path))
      assert_equal "deploy", trust.fetch("trusted_bots")
      assert_equal ["github-actions"], trust.fetch("trusted_metadata_bots")
    end
  end

  def test_init_validates_existing_yaml_before_writing
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents"))
      policy_path = File.join(root, ".agents/agent-workflow.yml")
      File.write(policy_path, "base_branch: [\n")

      out, status = run_doctor(root, "--init", "--validate-command", "true", "--test-command", "true")

      refute status.success?
      assert_includes out, "invalid policy config"
      assert_equal "base_branch: [\n", File.read(policy_path)
      refute File.exist?(File.join(root, "AGENTS.md"))
      refute File.exist?(File.join(root, ".agents/bin"))
    end
  end

  def test_init_rejects_overlapping_trusted_bot_roles_before_writing
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, ".agents"))
      trust_path = File.join(root, ".agents/trusted-github-actors.yml")
      trust = {
        "trusted_users" => [],
        "trusted_bots" => ["@Deploy[bot]"],
        "trusted_metadata_bots" => ["deploy"],
        "trusted_teams" => []
      }
      File.write(trust_path, trust.to_yaml)
      before = File.binread(trust_path)

      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "bot(s) listed in both trusted_bots and trusted_metadata_bots: deploy"
      assert_equal before, File.binread(trust_path)
      refute File.exist?(File.join(root, ".agents/bin"))
      refute File.exist?(File.join(root, "AGENTS.md"))
    end
  end

  def test_init_does_not_guess_when_javascript_detection_is_ambiguous
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      File.write(File.join(root, "package.json"), JSON.generate("scripts" => { "validate" => "check", "test" => "spec" }))
      File.write(File.join(root, "package-lock.json"), "lock\n")
      File.write(File.join(root, "yarn.lock"), "lock\n")

      out, status = run_doctor(root, "--init")

      refute status.success?
      assert_includes out, "unconfigured init wrapper"
    end
  end

  def test_init_uses_explicit_base_branch_for_new_policy
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--base-branch", "develop",
        "--validate-command", "true",
        "--test-command", "true"
      )

      assert status.success?, out
      policy = YAML.safe_load(File.read(File.join(root, ".agents/agent-workflow.yml")))
      assert_equal "develop", policy.fetch("base_branch")
    end
  end

  def test_init_rejects_invalid_base_branch_before_writing
    ["", "feature\nbranch", "feature\0branch", "feature branch", "feature~branch", "release.lock", "-hidden", "@{-1}"].each do |base_branch|
      Dir.mktmpdir("agent-workflow-seam-init") do |root|
        error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
          AgentWorkflowSeamDoctor.init(
            root,
            base_branch: base_branch,
            validate_command: "true",
            test_command: "true"
          )
        end

        assert_includes error.message, "base branch must be a valid Git branch name"
        refute File.exist?(File.join(root, ".agents"))
        refute File.exist?(File.join(root, "AGENTS.md"))
      end
    end
  end

  def test_init_rejects_multiline_command_before_writing
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      out, status = run_doctor(
        root,
        "--init",
        "--validate-command", "true\necho unexpected",
        "--test-command", "true"
      )

      refute status.success?
      assert_includes out, "commands must be non-empty single-line shell commands without NUL bytes"
      refute File.exist?(File.join(root, ".agents"))
      refute File.exist?(File.join(root, "AGENTS.md"))
    end
  end

  def test_init_rejects_nul_command_before_writing
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      error = assert_raises(AgentWorkflowSeamDoctor::InitError) do
        AgentWorkflowSeamDoctor.init(
          root,
          base_branch: "main",
          validate_command: "true\0unexpected",
          test_command: "true"
        )
      end

      assert_includes error.message, "commands must be non-empty single-line shell commands without NUL bytes"
      refute File.exist?(File.join(root, ".agents"))
      refute File.exist?(File.join(root, "AGENTS.md"))
    end
  end

  def test_init_reports_missing_root_without_creating_it
    Dir.mktmpdir("agent-workflow-seam-init") do |parent|
      root = File.join(parent, "missing")

      out, status = run_doctor(root, "--init")

      refute status.success?
      assert_includes out, "missing directory: #{root}"
      refute File.exist?(root)
    end
  end

  def test_init_text_and_json_report_the_same_failures
    Dir.mktmpdir("agent-workflow-seam-init-text") do |text_root|
      text, text_status = run_doctor(text_root, "--init")
      refute text_status.success?

      Dir.mktmpdir("agent-workflow-seam-init-json") do |json_root|
        json, json_status = run_doctor(json_root, "--init", "--json")
        refute json_status.success?
        payload = JSON.parse(json)

        assert_equal "FAIL", payload.fetch("status")
        payload.fetch("issues").each do |issue|
          normalized = issue.sub(json_root, text_root)
          assert_includes text, normalized
        end
      end
    end
  end

  def test_bare_init_preserves_previously_generated_valid_wrappers
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      first_out, first_status = run_doctor(
        root,
        "--init",
        "--validate-command", "true",
        "--test-command", "true"
      )
      assert first_status.success?, first_out
      paths = %w[
        AGENTS.md
        .agents/bin/README.md
        .agents/bin/validate
        .agents/bin/test
        .agents/agent-workflow.yml
        .agents/trusted-github-actors.yml
      ]
      before = paths.to_h do |path|
        [path, File.binread(File.join(root, path))]
      end

      second_out, second_status = run_doctor(root, "--init")

      assert second_status.success?, second_out
      after = paths.to_h do |path|
        [path, File.binread(File.join(root, path))]
      end
      assert_equal before, after
    end
  end

  def test_bare_init_restores_managed_wrapper_mode_without_rewriting_content
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      first_out, first_status = run_doctor(
        root,
        "--init",
        "--validate-command", "echo explicit-validate",
        "--test-command", "echo explicit-test"
      )
      assert first_status.success?, first_out
      validate_path = File.join(root, ".agents/bin/validate")
      before = File.binread(validate_path)
      File.chmod(0o644, validate_path)

      second_out, second_status = run_doctor(root, "--init")

      assert second_status.success?, second_out
      assert File.executable?(validate_path)
      assert_equal before, File.binread(validate_path)
      assert_includes File.read(validate_path), "explicit-validate"
      refute_includes File.read(validate_path), AgentWorkflowSeamDoctor::INIT_PLACEHOLDER_MARKER
    end
  end

  def test_bare_init_preserves_explicit_wrappers_when_root_commands_are_detectable
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      %w[validate test].each do |name|
        path = File.join(root, "bin", name)
        File.write(path, "#!/usr/bin/env bash\necho root-#{name}\n")
        File.chmod(0o755, path)
      end
      first_out, first_status = run_doctor(
        root,
        "--init",
        "--validate-command", "echo explicit-validate",
        "--test-command", "echo explicit-test"
      )
      assert first_status.success?, first_out
      paths = %w[.agents/bin/README.md .agents/bin/validate .agents/bin/test]
      before = paths.to_h { |path| [path, File.binread(File.join(root, path))] }

      second_out, second_status = run_doctor(root, "--init")

      assert second_status.success?, second_out
      after = paths.to_h { |path| [path, File.binread(File.join(root, path))] }
      assert_equal before, after
      assert_includes File.read(File.join(root, ".agents/bin/validate")), "explicit-validate"
      refute_includes File.read(File.join(root, ".agents/bin/validate")), "bin/validate"
    end
  end

  def test_explicit_commands_replace_previously_generated_wrappers
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      first_out, first_status = run_doctor(
        root,
        "--init",
        "--validate-command", "echo first",
        "--test-command", "echo first-test"
      )
      assert first_status.success?, first_out

      second_out, second_status = run_doctor(
        root,
        "--init",
        "--validate-command", "echo second",
        "--test-command", "echo second-test"
      )

      assert second_status.success?, second_out
      validate = File.read(File.join(root, ".agents/bin/validate"))
      test = File.read(File.join(root, ".agents/bin/test"))
      readme = File.read(File.join(root, ".agents/bin/README.md"))
      assert_includes validate, "exec echo second"
      refute_includes validate, "exec echo first"
      assert_includes test, "exec echo second-test"
      refute_includes test, "exec echo first-test"
      assert_includes readme, "`echo second`"
      assert_includes readme, "`echo second-test`"
    end
  end

  def test_init_does_not_detect_root_command_directories
    Dir.mktmpdir("agent-workflow-seam-init") do |root|
      FileUtils.mkdir_p(File.join(root, "bin/validate"))
      FileUtils.mkdir_p(File.join(root, "bin/test"))

      out, status = run_doctor(root, "--init")

      refute status.success?
      assert_includes out, "unconfigured init wrapper"
    end
  end
end
