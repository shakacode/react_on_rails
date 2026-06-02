# frozen_string_literal: true

require "yaml"

shared_examples "scaffold_ci_and_scripts" do
  it "generates a GitHub Actions CI workflow" do
    assert_file ".github/workflows/ci.yml" do |content|
      expect(content).to include("name: CI")
      expect(content).to include("actions/checkout@v4")
      expect(content).to include("ruby/setup-ruby@v1")
      expect(content).to include("actions/setup-node@v4")
    end
  end

  it "generates a CI workflow that parses as valid YAML" do
    assert_file ".github/workflows/ci.yml" do |content|
      expect { YAML.safe_load(content, aliases: true) }.not_to raise_error
    end
  end

  it "CI workflow includes db:prepare when Active Record is present" do
    assert_file ".github/workflows/ci.yml" do |content|
      expect(content).to include("db:prepare")
    end
  end

  it "CI workflow builds JS bundles before running tests" do
    assert_file ".github/workflows/ci.yml" do |content|
      build_step_pos = content.index("Build JavaScript bundles")
      test_step_pos = content.index("Run tests")
      expect(build_step_pos).not_to be_nil
      expect(test_step_pos).not_to be_nil
      expect(build_step_pos).to be < test_step_pos
    end
  end

  it "CI workflow runs the auto-bundle hook before building JS bundles" do
    assert_file ".github/workflows/ci.yml" do |content|
      expect(content).to match(
        %r{bin/shakapacker-precompile-hook\s*\n\s*SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true bin/shakapacker}
      )
      expect(content).to include("RAILS_ENV: test")
      expect(content).to include("NODE_ENV: test")
    end
  end

  it "CI workflow detects RSpec and uses bundle exec rspec" do
    assert_file ".github/workflows/ci.yml" do |content|
      expect(content).to include("bundle exec rspec")
      expect(content).not_to include("bin/rails test")
    end
  end

  it "adds build scripts to package.json" do
    assert_file "package.json" do |content|
      package_json = JSON.parse(content)
      scripts = package_json["scripts"] || {}
      expect(scripts).to include("build")
      expect(scripts).to include("build:test")
      expect(scripts["build"]).to eq(
        "RAILS_ENV=production NODE_ENV=production bin/shakapacker-precompile-hook && " \
        "SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true RAILS_ENV=production NODE_ENV=production bin/shakapacker"
      )
      expect(scripts["build:test"]).to eq(
        "RAILS_ENV=test NODE_ENV=test bin/shakapacker-precompile-hook && " \
        "SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true RAILS_ENV=test NODE_ENV=test bin/shakapacker"
      )
      expect(scripts["build:test"]).to include("RAILS_ENV=test")
    end
  end
end
