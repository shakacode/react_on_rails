# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

module ShakaTrustConfigHelper
  GitHubTrustFixture = Struct.new(:repository, :contents) do
    def graphql(_query, owner:, name:, expression:)
      expected_expression = "#{'a' * 40}:.agents/trusted-github-actors.yml"
      raise "unexpected trust repository" unless [owner, name].join("/") == repository
      raise "unexpected trust expression: #{expression}" unless expression == expected_expression

      object = {
        "__typename" => "Blob", "text" => contents, "isBinary" => false,
        "isTruncated" => false, "byteSize" => contents.bytesize
      }
      { "repository" => { "object" => object } }
    end
  end

  def load_trust_config(contents)
    github = GitHubTrustFixture.new("shakacode/react_on_rails", contents)

    Dir.mktmpdir("shaka-trust") do |root|
      machine_path = File.join(root, "missing-machine-trust.yml")
      Shaka::PublicComments::TrustConfig.new(github, machine_path:).load(base_oid: "a" * 40)
    end
  end
end

module ShakaSeamFixtureHelper
  def with_valid_seam
    Dir.mktmpdir("shaka-seam-check") do |root|
      execution_marker = File.join(root, "candidate-wrapper-executed")
      FileUtils.mkdir_p(File.join(root, ".agents/bin"))
      File.write(File.join(root, ".agents/agent-workflow.yml"), <<~YAML)
        ---
        version: 1
        base_branch: main
        review:
          required: meaningful_changes
          ci_review_jobs:
            - claude-review
          local_review_agents:
            - provider: anthropic
              model_family: claude
        merge:
          preference: ask
      YAML
      %w[setup validate test].each do |name|
        command = File.join(root, ".agents/bin", name)
        File.write(command, "#!/bin/sh\ntouch #{execution_marker.dump}\n")
        File.chmod(0o755, command)
      end
      yield root
      refute File.exist?(execution_marker), "candidate seam validation must not execute repository wrappers"
    end
  end

  def run_check(root, *mode)
    mode = ["--local"] if mode.empty?
    Open3.capture3(self.class::SHAKA_COMMAND, "seam", "check", "--root", root, *mode)
  end

  def commit_fixture(root)
    git = ["git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-C", root]
    commands = [
      %w[init -q],
      %w[add .],
      ["-c", "user.name=Shaka Test", "-c", "user.email=shaka-test@example.com", "commit", "-qm", "fixture"]
    ]
    commands.each do |arguments|
      _output, error, status = Open3.capture3(*git, *arguments)
      raise "fixture git command failed: #{error}" unless status.success?
    end
    output, error, status = Open3.capture3(*git, "rev-parse", "HEAD")
    raise "fixture git rev-parse failed: #{error}" unless status.success?

    output.strip
  end

  def assert_rejected(root, message)
    output, error, status = run_check(root)

    refute status.success?, output
    assert_includes error, message
  end

  def append_config(root, content)
    File.open(File.join(root, ".agents/agent-workflow.yml"), "a") { |file| file.write(content) }
  end

  def replace_config(root, old_value, new_value)
    path = File.join(root, ".agents/agent-workflow.yml")
    source = File.read(path)
    raise "missing fixture value: #{old_value}" unless source.include?(old_value)

    File.write(path, source.sub(old_value, new_value))
  end

  def update_config(root)
    path = File.join(root, ".agents/agent-workflow.yml")
    config = YAML.safe_load_file(path, permitted_classes: [], aliases: false)
    yield config
    File.write(path, YAML.dump(config))
  end
end

class ShakaSeamCheckTest < Minitest::Test
  SHAKA_COMMAND = File.expand_path(ENV.fetch("SHAKA_COMMAND"))
  SHAKA_COMMAND_ROOT = File.dirname(File.realpath(SHAKA_COMMAND))
  SHAKA_SKILL_ROOT = [
    File.expand_path("..", SHAKA_COMMAND_ROOT),
    File.expand_path("../skills/shaka", SHAKA_COMMAND_ROOT)
  ].find { |root| File.file?(File.join(root, "lib/shaka/public_comments/trust_config.rb")) }
  REPOSITORY_ROOT = File.expand_path("..", __dir__)

  if SHAKA_SKILL_ROOT
    $LOAD_PATH.unshift(File.join(SHAKA_SKILL_ROOT, "lib"))
    require "shaka/public_comments/trust_config"
  end

  include ShakaTrustConfigHelper
  include ShakaSeamFixtureHelper

  def test_valid_candidate_reports_no_authority
    with_valid_seam do |root|
      output, error, status = run_check(root)

      assert status.success?, error
      validation = JSON.parse(output).fetch("validation")
      assert_equal "local/candidate", validation.fetch("mode")
      assert_equal false, validation.fetch("grants_policy")
      assert_equal false, validation.fetch("grants_merge_authority")
    end
  end

  def test_trusted_ref_ignores_candidate_policy
    with_valid_seam do |root|
      trusted_ref = commit_fixture(root)
      replace_config(root, "preference: ask", "preference: auto")

      output, error, status = run_check(root, "--ref", trusted_ref)

      assert status.success?, error
      config = JSON.parse(output)
      assert_equal "ask", config.fetch("merge").fetch("preference")
      assert_equal "trusted/ref", config.dig("validation", "mode")
      assert_equal true, config.dig("validation", "grants_policy")
      assert_equal trusted_ref, config.dig("validation", "sha")
    end
  end

  def test_unknown_top_level_key_is_rejected
    with_valid_seam do |root|
      append_config(root, "surprise: true\n")

      assert_rejected(root, "unknown .agents/agent-workflow.yml key: surprise")
    end
  end

  def test_invalid_review_value_is_rejected
    with_valid_seam do |root|
      replace_config(root, "required: meaningful_changes", "required: sometimes")

      assert_rejected(root, "review.required must be always, meaningful_changes, or none")
    end
  end

  def test_missing_review_is_rejected
    with_valid_seam do |root|
      update_config(root) { |config| config.delete("review") }

      assert_rejected(root, "missing .agents/agent-workflow.yml key: review")
    end
  end

  def test_empty_review_is_rejected
    with_valid_seam do |root|
      update_config(root) { |config| config["review"] = {} }

      assert_rejected(root, "missing review key: required")
    end
  end

  def test_invalid_merge_value_is_rejected
    with_valid_seam do |root|
      replace_config(root, "preference: ask", "preference: sometimes")

      assert_rejected(root, "merge.preference must be ask or auto")
    end
  end

  def test_duplicate_yaml_key_is_rejected
    with_valid_seam do |root|
      append_config(root, "merge:\n  preference: ask\n")

      assert_rejected(root, "duplicate key: merge")
    end
  end

  def test_unknown_branch_placeholder_is_rejected
    with_valid_seam do |root|
      append_config(root, "branches:\n  name: '{issue}-{base_branch}'\n")

      assert_rejected(root, "branches.name has unknown placeholder: base_branch")
    end
  end

  def test_required_command_resolving_outside_repository_is_rejected
    with_valid_seam do |root|
      Dir.mktmpdir("shaka-outside") do |outside_root|
        outside_command = File.join(outside_root, "command")
        File.write(outside_command, "#!/bin/sh\nexit 0\n")
        File.chmod(0o755, outside_command)
        FileUtils.rm(File.join(root, ".agents/bin/test"))
        File.symlink(outside_command, File.join(root, ".agents/bin/test"))

        assert_rejected(root, ".agents/bin/test must resolve inside the repository")
      end
    end
  end

  def test_missing_required_command_is_rejected
    with_valid_seam do |root|
      FileUtils.rm(File.join(root, ".agents/bin/validate"))

      assert_rejected(root, ".agents/bin/validate does not exist")
    end
  end

  def test_non_executable_required_command_is_rejected
    with_valid_seam do |root|
      File.chmod(0o644, File.join(root, ".agents/bin/setup"))

      assert_rejected(root, ".agents/bin/setup is not executable")
    end
  end

  def test_repository_trust_config_is_accepted_by_shaka
    skip "installed Shaka does not expose its skill library" unless SHAKA_SKILL_ROOT

    trust_path = File.join(REPOSITORY_ROOT, ".agents/trusted-github-actors.yml")

    merged = load_trust_config(File.binread(trust_path))

    assert_empty merged.fetch(:bots) & merged.fetch(:metadata_bots)
  end

  def test_overlapping_trust_bot_roles_are_rejected_by_shaka
    skip "installed Shaka does not expose its skill library" unless SHAKA_SKILL_ROOT

    contents = <<~YAML
      trusted_bots:
        - github-actions
      trusted_metadata_bots:
        - github-actions
    YAML

    error = assert_raises(Shaka::Error) { load_trust_config(contents) }

    assert_equal "A trust bot is also metadata-only.", error.message
  end
end
