# frozen_string_literal: true

require "yaml"
require "fileutils"
require "open3"
require "shellwords"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "Ruby version support" do
  # From spec/react_on_rails/ up through spec/ and react_on_rails/ to the repo root.
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:ruby_setup_actions) { ["./.github/actions/setup-ruby", "./.github/actions/setup-bundle"] }

  def read_repo_file(path)
    File.read(File.join(repo_root, path))
  end

  def tool_versions(path)
    read_repo_file(path).lines.each_with_object({}) do |line, versions|
      tool, version = line.split
      next if tool.nil? || tool.start_with?("#")

      versions[tool] = version
    end
  end

  def committed_tool_versions(path)
    stdout, stderr, status = Open3.capture3("git", "-C", repo_root, "show", "HEAD:#{path}")

    expect(status).to be_success, "#{stdout}\n#{stderr}"
    stdout
  end

  def minor_version(version)
    version.split(".").take(2).join(".")
  end

  def major_version(version)
    version.split(".").first
  end

  # The action executes the shared bin/read-tool-version helper from the workspace root.
  def install_shared_tool_version_helper(tmpdir)
    helper_copy_path = File.join(tmpdir, "bin/read-tool-version")

    FileUtils.mkdir_p(File.dirname(helper_copy_path))
    FileUtils.cp(File.join(repo_root, "bin/read-tool-version"), helper_copy_path)
    FileUtils.chmod("+x", helper_copy_path)
  end

  def read_tool_versions_action_outputs
    action = YAML.safe_load(read_repo_file(".github/actions/read-tool-versions/action.yml"))
    run_script = action.fetch("runs").fetch("steps").find { |step| step["id"] == "versions" }.fetch("run")

    Dir.mktmpdir do |tmpdir|
      github_output = File.join(tmpdir, "github-output")

      File.write(File.join(tmpdir, ".tool-versions"), committed_tool_versions(".tool-versions"))
      FileUtils.cp(File.join(repo_root, ".minimum.tool-versions"), File.join(tmpdir, ".minimum.tool-versions"))
      install_shared_tool_version_helper(tmpdir)

      stdout, stderr, status = Open3.capture3(
        { "GITHUB_OUTPUT" => github_output }, "bash", "-c", run_script, chdir: tmpdir
      )

      expect(status).to be_success, "#{stdout}\n#{stderr}"
      File.read(github_output).lines.to_h { |line| line.strip.split("=", 2) }
    end
  end

  def ci_switch_tool_version_outputs
    latest_versions_content = committed_tool_versions(".tool-versions")
    minimum_versions_content = committed_tool_versions(".minimum.tool-versions")
    # Feed committed file contents through env vars so the sourced script's
    # read_tool_version parser reads the same temp-file shape as the workflow action.
    script = [
      "source #{Shellwords.escape(File.join(repo_root, 'bin/ci-switch-config'))}",
      "latest_tool_versions=$(mktemp)",
      "minimum_tool_versions=$(mktemp)",
      'trap \'rm -f "$latest_tool_versions" "$minimum_tool_versions"\' EXIT',
      'printf "%s\n" "$LATEST_TOOL_VERSIONS" > "$latest_tool_versions"',
      'printf "%s\n" "$MINIMUM_TOOL_VERSIONS" > "$minimum_tool_versions"',
      'echo "ruby-version=$(read_tool_version "$latest_tool_versions" ruby)"',
      'echo "node-version=$(read_tool_version "$latest_tool_versions" nodejs)"',
      'echo "minimum-ruby-version=$(read_tool_version "$minimum_tool_versions" ruby)"',
      'echo "minimum-node-version=$(read_tool_version "$minimum_tool_versions" nodejs)"'
    ].join("\n")

    stdout, stderr, status = Open3.capture3(
      { "LATEST_TOOL_VERSIONS" => latest_versions_content, "MINIMUM_TOOL_VERSIONS" => minimum_versions_content },
      "bash", "-c", script, chdir: repo_root
    )

    expect(status).to be_success, "#{stdout}\n#{stderr}"
    expect(stderr).not_to include("Error:")

    stdout.lines.to_h { |line| line.strip.split("=", 2) }
  end

  # Only use this helper on workflows that hardcode `ruby-version` in steps. Matrix-driven
  # workflows store the unexpanded `${{ matrix.ruby-version }}` expression in that field.
  def workflow_ruby_versions(path)
    workflow = YAML.safe_load(read_repo_file(path), aliases: true)

    workflow.fetch("jobs").values.flat_map do |job|
      # Jobs that call reusable workflows with `uses:` do not have their own steps.
      Array(job["steps"] || []).filter_map do |step|
        next unless ruby_setup_actions.include?(step["uses"])

        step.dig("with", "ruby-version")
      end
    end
  end

  it "uses the merge queue base SHA for merge_group change detection" do
    expected_base_expression = [
      "github.event.pull_request.base.sha",
      "github.event.merge_group.base_sha",
      "github.event.before",
      "'origin/main'"
    ].join(" || ")

    [
      ".github/workflows/ci-required.yml",
      ".github/workflows/examples.yml",
      ".github/workflows/gem-tests.yml",
      ".github/workflows/integration-tests.yml",
      ".github/workflows/lint-js-and-ruby.yml",
      ".github/workflows/package-js-tests.yml",
      ".github/workflows/playwright.yml",
      ".github/workflows/precompile-check.yml",
      ".github/workflows/pro-integration-tests.yml",
      ".github/workflows/pro-test-package-and-gem.yml"
    ].each do |path|
      workflow = read_repo_file(path)

      expect(workflow).to include("merge_group:"), "#{path} must run on merge queue events"
      expect(workflow).to include(expected_base_expression), "#{path} must diff merge queue runs from base_sha"
    end
  end

  # These checks intentionally make future version bumps update the committed
  # runtime files, CI matrix readers, helper scripts, and docs together.
  it "allows Ruby 4 in the gemspec" do
    gemspec = Gem::Specification.load(File.join(repo_root, "react_on_rails/react_on_rails.gemspec"))

    expect(gemspec.required_ruby_version).to be_satisfied_by(Gem::Version.new("3.3.0"))
    expect(gemspec.required_ruby_version).not_to be_satisfied_by(Gem::Version.new("3.2.9"))
    expect(gemspec.required_ruby_version).to be_satisfied_by(Gem::Version.new("4.0.0"))
  end

  it "uses a Ruby 4-compatible Bundler version in OSS lockfiles" do
    ["react_on_rails/Gemfile.lock", "react_on_rails/spec/dummy/Gemfile.lock"].each do |path|
      lockfile = read_repo_file(path)
      match = lockfile.match(/\nBUNDLED WITH\n\s+(\S+)/)
      expect(match).not_to be_nil, "BUNDLED WITH stanza not found in #{path}"
      bundler_version = match[1]

      expect(Gem::Version.new(bundler_version)).to be >= Gem::Version.new("4.0.0")
    end
  end

  it "stores latest and minimum CI runtime versions in committed tool-version files" do
    # Runtime bumps start in the committed tool-version files; this snapshot and
    # SWITCHING_CI_CONFIGS.md follow those source-of-truth versions.
    latest_versions = tool_versions(".tool-versions")
    minimum_versions = tool_versions(".minimum.tool-versions")

    # Verify major/minor contracts; exact patch versions live in the source files above.
    expect(minor_version(latest_versions.fetch("ruby"))).to eq("4.0")
    expect(major_version(latest_versions.fetch("nodejs"))).to eq("22")
    expect(minor_version(minimum_versions.fetch("ruby"))).to eq("3.3")
    expect(major_version(minimum_versions.fetch("nodejs"))).to eq("20")
    expect(Gem::Version.new(latest_versions.fetch("ruby")))
      .to be > Gem::Version.new(minimum_versions.fetch("ruby"))
    expect(Gem::Version.new(latest_versions.fetch("nodejs")))
      .to be > Gem::Version.new(minimum_versions.fetch("nodejs"))
  end

  it "keeps the workflow action and local CI switch tool-version parsers in sync" do
    action_outputs = read_tool_versions_action_outputs
    ci_switch_outputs = ci_switch_tool_version_outputs

    expect(action_outputs).to include(
      "ruby-version" => ci_switch_outputs.fetch("ruby-version"),
      "node-version" => ci_switch_outputs.fetch("node-version"),
      "minimum-ruby-version" => ci_switch_outputs.fetch("minimum-ruby-version"),
      "minimum-node-version" => ci_switch_outputs.fetch("minimum-node-version")
    )
    expect(action_outputs.fetch("ruby-minor-version")).to eq(minor_version(ci_switch_outputs.fetch("ruby-version")))
    expect(action_outputs.fetch("node-major-version")).to eq(major_version(ci_switch_outputs.fetch("node-version")))
    expect(action_outputs.fetch("minimum-ruby-minor-version")).to eq(
      minor_version(ci_switch_outputs.fetch("minimum-ruby-version"))
    )
    expect(action_outputs.fetch("minimum-node-major-version")).to eq(
      major_version(ci_switch_outputs.fetch("minimum-node-version"))
    )
  end

  it "tests Ruby 4.0 as the latest OSS CI runtime while keeping Ruby 3.3 as the minimum" do
    latest_ruby_minor = minor_version(tool_versions(".tool-versions").fetch("ruby"))
    minimum_ruby_minor = minor_version(tool_versions(".minimum.tool-versions").fetch("ruby"))
    latest_node_major = major_version(tool_versions(".tool-versions").fetch("nodejs"))
    minimum_node_major = major_version(tool_versions(".minimum.tool-versions").fetch("nodejs"))

    expect(latest_ruby_minor).to eq("4.0")
    expect(minimum_ruby_minor).to eq("3.3")
    expect(latest_node_major).to eq("22")
    expect(minimum_node_major).to eq("20")

    [".github/workflows/gem-tests.yml", ".github/workflows/examples.yml"].each do |path|
      workflow = read_repo_file(path)

      expect(workflow).to include("uses: ./.github/actions/read-tool-versions")
      expect(workflow).to include("steps.tool-versions.outputs.ruby-minor-version")
      expect(workflow).to include("steps.tool-versions.outputs.minimum-ruby-minor-version")
      expect(workflow).not_to match(/"ruby-version":"\d/)
    end

    integration_workflow = read_repo_file(".github/workflows/integration-tests.yml")
    expect(integration_workflow).to include("uses: ./.github/actions/read-tool-versions")
    expect(integration_workflow).to include("steps.tool-versions.outputs.ruby-minor-version")
    expect(integration_workflow).to include("steps.tool-versions.outputs.minimum-ruby-minor-version")
    expect(integration_workflow).to include("steps.tool-versions.outputs.node-major-version")
    expect(integration_workflow).to include("steps.tool-versions.outputs.minimum-node-major-version")
    expect(integration_workflow).not_to match(/"(ruby|node)-version":"\d/)

    lint_ruby_versions = workflow_ruby_versions(".github/workflows/lint-js-and-ruby.yml")
    precompile_ruby_versions = workflow_ruby_versions(".github/workflows/precompile-check.yml")
    expected_latest_ruby = "${{ steps.tool-versions.outputs.ruby-minor-version }}"
    expected_minimum_ruby = "${{ steps.tool-versions.outputs.minimum-ruby-version }}"

    expect(lint_ruby_versions).to all(eq(expected_latest_ruby))
    expect(lint_ruby_versions).not_to be_empty
    expect(precompile_ruby_versions).to all(eq(expected_latest_ruby))
    expect(precompile_ruby_versions).not_to be_empty
    expect(workflow_ruby_versions(".github/workflows/pro-test-package-and-gem.yml")).to all(eq(expected_minimum_ruby))
    expect(read_repo_file(".github/workflows/pro-test-package-and-gem.yml")).not_to include("env.RUBY_VERSION")

    examples_workflow = read_repo_file(".github/workflows/examples.yml")
    playwright_workflow = read_repo_file(".github/workflows/playwright.yml")
    [examples_workflow, playwright_workflow].each do |workflow|
      expect(workflow).to include("steps.tool-versions.outputs.minimum-node-version")
      expect(workflow).not_to include("node-version-file: .minimum.tool-versions")
    end

    benchmark_suite = read_repo_file(".github/workflows/benchmark-suite.yml")
    expect(benchmark_suite).to include("steps.tool-versions.outputs.minimum-ruby-version")
    expect(benchmark_suite).to include("steps.tool-versions.outputs.node-version")
    expect(benchmark_suite).not_to include("steps.tool-versions.outputs.minimum-node-version")
  end

  it "documents and switches to Ruby 4.0 for the latest local CI configuration" do
    expect(read_repo_file("README.md")).to include("Ruby >= 3.3 (CI tested: 3.3 - 4.0)")
    expect(read_repo_file("README.md")).to include("CI tested: 8.2.0 - 10.2.0")
    expect(read_repo_file(".github/read-me.md")).to include("Only latest dependency versions (Ruby 4.0, Node 22)")

    ci_switch_config = read_repo_file("bin/ci-switch-config")
    # These are shell variable names, not Ruby interpolation.
    expect(ci_switch_config).to include(
      "Target: Ruby $LATEST_RUBY_MINOR_VERSION, Node $LATEST_NODE_MAJOR_VERSION, " \
      "Shakapacker $LATEST_SHAKAPACKER_VERSION"
    )
    expect(ci_switch_config).to include(
      "matches CI: Ruby $MINIMUM_RUBY_MINOR_VERSION, Node $MINIMUM_NODE_MAJOR_VERSION, minimum deps"
    )
    expect(ci_switch_config).to include(
      "matches CI: Ruby $LATEST_RUBY_MINOR_VERSION, Node $LATEST_NODE_MAJOR_VERSION, latest deps"
    )
    expect(ci_switch_config).to include(
      "Switch to Ruby $LATEST_RUBY_MINOR_VERSION, Node $LATEST_NODE_MAJOR_VERSION, latest dependencies"
    )
    expect(ci_switch_config).to include(
      "latest   - Switch to Ruby $LATEST_RUBY_MINOR_VERSION, Node $LATEST_NODE_MAJOR_VERSION, " \
      "latest dependencies " \
      "(Shakapacker $LATEST_SHAKAPACKER_VERSION, React $LATEST_REACT_VERSION)"
    )
    expect(ci_switch_config).to include('MINIMUM_RUBY_MINOR_VERSION="${MINIMUM_RUBY_VERSION%.*}"')
    expect(ci_switch_config).to include(
      'MINIMUM_RUBY_VERSION="$(read_tool_version "$MINIMUM_TOOL_VERSIONS_FILE" ruby)"'
    )
    expect(ci_switch_config).to include(
      'MINIMUM_NODE_VERSION="$(read_tool_version "$MINIMUM_TOOL_VERSIONS_FILE" nodejs)"'
    )
    expect(ci_switch_config).to include('MINIMUM_NODE_MAJOR_VERSION="${MINIMUM_NODE_VERSION%%.*}"')
    expect(ci_switch_config).to include(
      'MINIMUM_SHAKAPACKER_VERSION="$(read_tool_version "$CI_DEPENDENCY_VERSIONS_FILE" minimum-shakapacker)"'
    )
    expect(ci_switch_config).to include(
      'MINIMUM_REACT_VERSION="$(read_tool_version "$CI_DEPENDENCY_VERSIONS_FILE" minimum-react)"'
    )
    expect(ci_switch_config).to include('MINIMUM_REACT_MAJOR_VERSION="${MINIMUM_REACT_VERSION%%.*}"')
    expect(ci_switch_config).to include('MAXIMUM_TOOL_VERSIONS_HEAD_FILE="$PROJECT_ROOT/.maximum.tool-versions.head"')
    expect(ci_switch_config).to include("saved_tool_versions_valid_for_restore()")
    expect(ci_switch_config).to include("set_tool_versions_to_minimum()")
    expect(ci_switch_config).to include("restore_tool_versions_to_latest()")
    expect(ci_switch_config).to include("read_committed_tool_version()")
    expect(ci_switch_config).to include("read_latest_tool_version()")
    expect(ci_switch_config).to include("reload_latest_tool_version_globals()")
    expect(ci_switch_config).to include("reload_latest_tool_version_globals false")
    expect(ci_switch_config).to include(
      'LATEST_RUBY_VERSION="$(read_latest_tool_version ruby "$emit_warnings")"'
    )
    expect(ci_switch_config).to include(
      'LATEST_NODE_VERSION="$(read_latest_tool_version nodejs "$emit_warnings")"'
    )
    expect(ci_switch_config).to include('LATEST_NODE_MAJOR_VERSION="${LATEST_NODE_VERSION%%.*}"')
    expect(ci_switch_config).to include(
      'LATEST_SHAKAPACKER_VERSION="$(read_tool_version "$CI_DEPENDENCY_VERSIONS_FILE" latest-shakapacker)"'
    )
    expect(ci_switch_config).to include(
      'LATEST_REACT_VERSION="$(read_tool_version "$CI_DEPENDENCY_VERSIONS_FILE" latest-react)"'
    )
    expect(ci_switch_config).to include('LATEST_REACT_MAJOR_VERSION="${LATEST_REACT_VERSION%%.*}"')

    # The dependency profile matrix itself lives in the committed data file.
    dependency_versions = tool_versions(".ci-dependency-versions")
    expect(dependency_versions.fetch("minimum-shakapacker")).to eq("8.2.0")
    expect(dependency_versions.fetch("minimum-react")).to eq("18.0.0")
    expect(dependency_versions.fetch("latest-shakapacker")).to eq("10.2.0")
    expect(dependency_versions.fetch("latest-react")).to eq("19.0.0")
    expect(ci_switch_config).to match(/set_ruby_version "\$LATEST_RUBY_VERSION"/)
    expect(ci_switch_config).to match(/set_node_version "\$LATEST_NODE_VERSION"/)
    expect(ci_switch_config).to include('[[ "${REACT_ROOT}" =~ ^\^?${MINIMUM_REACT_MAJOR_VERSION}(\.|$) ]]')
    expect(ci_switch_config).to include('[[ "${REACT_ROOT}" =~ ^\^?${LATEST_REACT_MAJOR_VERSION}(\.|$) ]]')
    expect(ci_switch_config).to include('local lockfile="$bundle_dir/Gemfile.lock"')
    expect(ci_switch_config).to include("bundle config set --local path vendor/bundle")
    expect(ci_switch_config).to include('gem list bundler -i -v "$bundler_version"')
    expect(ci_switch_config).to include('gem install bundler -v "$bundler_version"')
    expect(ci_switch_config).to include('bundle "_${bundler_version}_" install')
    expect(ci_switch_config).to include('install_bundle_to_vendor "$PWD"')
    expect(ci_switch_config).not_to include("bundle install --path")

    ci_rerun_failures = read_repo_file("bin/ci-rerun-failures")
    latest_job_description = [
      'JOB_VERSION_MAP["dummy-app-integration-tests (4.0, 22, latest)"]=',
      '"Ruby 4.0, Node 22, Shakapacker 10.2.0, React 19"'
    ].join
    expect(ci_rerun_failures).to include(latest_job_description)

    switching_guide = read_repo_file("SWITCHING_CI_CONFIGS.md")
    expect(switching_guide).to include("Switch back to the latest runtime/dependency profile")
    expect(switching_guide).to include("Restore `.tool-versions` from `.maximum.tool-versions`")

    expect(read_repo_file(".claude/docs/replicating-ci-failures.md")).to include(
      "Ruby 4.0, Node 22, Shakapacker 10.2.0, React 19"
    )
    # Exact table spacing is intentional: keeps the Markdown column padding in sync.
    expect(read_repo_file("internal/contributor-info/ci-optimization.md")).to include(
      "| Ruby versions | 3.3, 4.0          | 4.0 only"
    )
  end
end
