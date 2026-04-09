# frozen_string_literal: true

shared_examples "scaffold_ci_and_scripts" do
  it "generates a GitHub Actions CI workflow" do
    assert_file ".github/workflows/ci.yml" do |content|
      expect(content).to include("name: CI")
      expect(content).to include("actions/checkout@v4")
      expect(content).to include("ruby/setup-ruby@v1")
      expect(content).to include("actions/setup-node@v4")
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

  it "CI workflow uses bin/shakapacker for bundle build" do
    assert_file ".github/workflows/ci.yml" do |content|
      expect(content).to include("bin/shakapacker")
      expect(content).to include("RAILS_ENV: test")
      expect(content).to include("NODE_ENV: test")
    end
  end

  it "adds build scripts to package.json" do
    assert_file "package.json" do |content|
      package_json = JSON.parse(content)
      scripts = package_json["scripts"] || {}
      expect(scripts).to include("build")
      expect(scripts).to include("build:test")
      expect(scripts["build"]).to include("bin/shakapacker")
      expect(scripts["build:test"]).to include("RAILS_ENV=test")
      expect(scripts["build:test"]).to include("bin/shakapacker")
    end
  end
end
