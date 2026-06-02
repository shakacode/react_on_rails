# frozen_string_literal: true

RSpec.describe "Ruby version support" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }

  def read_repo_file(path)
    File.read(File.join(repo_root, path))
  end

  # These literal checks intentionally make future version bumps update the CI matrix,
  # helper scripts, and docs together.
  it "allows Ruby 4 in the gemspec" do
    gemspec = Gem::Specification.load(File.join(repo_root, "react_on_rails/react_on_rails.gemspec"))

    expect(gemspec.required_ruby_version).to be_satisfied_by(Gem::Version.new("3.3.0"))
    expect(gemspec.required_ruby_version).not_to be_satisfied_by(Gem::Version.new("3.2.9"))
    expect(gemspec.required_ruby_version).to be_satisfied_by(Gem::Version.new("4.0.0"))
  end

  it "uses a Ruby 4-compatible Bundler version in OSS lockfiles" do
    ["react_on_rails/Gemfile.lock", "react_on_rails/spec/dummy/Gemfile.lock"].each do |path|
      lockfile = read_repo_file(path)
      bundler_version = lockfile.match(/\nBUNDLED WITH\n\s+(\S+)/)[1]

      expect(Gem::Version.new(bundler_version)).to be >= Gem::Version.new("4.0.0")
    end
  end

  it "tests Ruby 4.0 as the latest OSS CI runtime while keeping Ruby 3.3 as the minimum" do
    expect(read_repo_file(".github/workflows/gem-tests.yml")).to include(
      '"ruby-version":"4.0","dependency-level":"latest"',
      '"ruby-version":"3.3","dependency-level":"minimum"'
    )
    expect(read_repo_file(".github/workflows/examples.yml")).to include(
      '"ruby-version":"4.0","dependency-level":"latest"',
      '"ruby-version":"3.3","dependency-level":"minimum"'
    )
    expect(read_repo_file(".github/workflows/integration-tests.yml")).to include(
      '"ruby-version":"4.0","node-version":"22","dependency-level":"latest"',
      '"ruby-version":"3.3","node-version":"20","dependency-level":"minimum"'
    )

    lint_workflow = read_repo_file(".github/workflows/lint-js-and-ruby.yml")
    # Counts intentionally cover every Ruby setup in these single-lane workflows.
    expect(lint_workflow.scan("ruby-version: '4.0'").count).to eq(3)

    precompile_workflow = read_repo_file(".github/workflows/precompile-check.yml")
    expect(precompile_workflow.scan("ruby-version: '4.0'").count).to eq(2)
  end

  it "documents and switches to Ruby 4.0 for the latest local CI configuration" do
    expect(read_repo_file("README.md")).to include("Ruby >= 3.3 (CI tested: 3.3 - 4.0)")
    expect(read_repo_file("README.md")).to include("CI tested: 8.2.0 - 10.1.0")
    expect(read_repo_file(".github/read-me.md")).to include("Only latest dependency versions (Ruby 4.0, Node 22)")

    ci_switch_config = read_repo_file("bin/ci-switch-config")
    # $LATEST_RUBY_MINOR_VERSION is a shell variable name, not Ruby interpolation.
    expect(ci_switch_config).to include(
      "Target: Ruby $LATEST_RUBY_MINOR_VERSION, Node 22, Shakapacker 10.1.0"
    )
    expect(ci_switch_config).to include('LATEST_RUBY_VERSION="4.0.5"')
    expect(ci_switch_config).to match(/set_ruby_version "\$LATEST_RUBY_VERSION"/)
    expect(ci_switch_config).to include('[[ "${REACT_ROOT}" =~ ^\^?19(\.|$) ]]')
    expect(ci_switch_config).to include("bundle config set --local path vendor/bundle")
    expect(ci_switch_config).not_to include("bundle install --path")

    ci_rerun_failures = read_repo_file("bin/ci-rerun-failures")
    latest_job_description = [
      'JOB_VERSION_MAP["dummy-app-integration-tests (4.0, 22, latest)"]=',
      '"Ruby 4.0, Node 22, Shakapacker 10.1.0, React 19"'
    ].join
    expect(ci_rerun_failures).to include(latest_job_description)

    switching_guide = read_repo_file("SWITCHING_CI_CONFIGS.md")
    expect(switching_guide).to include("Switch back to latest dependencies (Ruby 4.0, Node 22)")
    expect(switching_guide).to include("Create `.tool-versions` with Ruby 4.0.5 and Node 22.12.0")

    expect(read_repo_file(".claude/docs/replicating-ci-failures.md")).to include(
      "Ruby 4.0, Node 22, Shakapacker 10.1.0, React 19"
    )
    # Exact table spacing is intentional: keeps the Markdown column padding in sync.
    expect(read_repo_file("internal/contributor-info/ci-optimization.md")).to include(
      "| Ruby versions | 3.3, 4.0        | 4.0 only"
    )
  end
end
