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
  end

  it "documents and switches to Ruby 4.0 for the latest local CI configuration" do
    expect(read_repo_file("README.md")).to include("Ruby >= 3.3 (CI tested: 3.3 - 4.0)")
    expect(read_repo_file("README.md")).to include("CI tested: 8.2.0 - 10.1.0")
    expect(read_repo_file(".github/read-me.md")).to include("Only latest dependency versions (Ruby 4.0, Node 22)")

    ci_switch_config = read_repo_file("bin/ci-switch-config")
    expect(ci_switch_config).to include(
      "Target: Ruby $LATEST_RUBY_MINOR_VERSION, Node 22, Shakapacker 10.1.0"
    )
    expect(ci_switch_config).to include('LATEST_RUBY_VERSION="4.0.5"')
    expect(ci_switch_config).to include('set_ruby_version "$LATEST_RUBY_VERSION"')

    switching_guide = read_repo_file("SWITCHING_CI_CONFIGS.md")
    expect(switching_guide).to include("Switch back to latest dependencies (Ruby 4.0, Node 22)")
    expect(switching_guide).to include("Create `.tool-versions` with Ruby 4.0.5 and Node 22.12.0")

    expect(read_repo_file(".claude/docs/replicating-ci-failures.md")).to include(
      "Ruby 4.0, Node 22, Shakapacker 10.1.0, React 19"
    )
    expect(read_repo_file("internal/contributor-info/ci-optimization.md")).to include(
      "| Ruby versions | 3.3, 4.0        | 4.0 only"
    )
  end
end
