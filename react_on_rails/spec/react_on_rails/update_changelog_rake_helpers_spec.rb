# frozen_string_literal: true

require "open3"
require_relative "simplecov_helper"
require_relative "spec_helper"

RSpec.describe "update_changelog.rake helper methods" do
  before do
    next if Object.instance_variable_defined?(:@update_changelog_rake_helpers_loaded)

    load File.expand_path("../../rakelib/update_changelog.rake", __dir__)
    Object.instance_variable_set(:@update_changelog_rake_helpers_loaded, true)
  end

  def run_git!(*args, chdir:)
    output, status = Open3.capture2e("git", *args, chdir: chdir)
    raise "git #{args.join(' ')} failed:\n#{output}" unless status.success?

    output.strip
  end

  def init_git_repo!(repo_dir)
    run_git!("init", chdir: repo_dir)
    run_git!("config", "user.email", "test@example.com", chdir: repo_dir)
    run_git!("config", "user.name", "Test User", chdir: repo_dir)
    File.write(File.join(repo_dir, "README.md"), "test\n")
    run_git!("add", "README.md", chdir: repo_dir)
    run_git!("commit", "-m", "Initial commit", chdir: repo_dir)
  end

  describe "#normalize_version_string" do
    it "normalizes stable tags" do
      expect(normalize_version_string("v16.4.0")).to eq("16.4.0")
    end

    it "normalizes dashed prereleases to gem format" do
      expect(normalize_version_string("16.4.0-rc.1")).to eq("16.4.0.rc.1")
    end
  end

  describe "#inferred_bump_type_from_unreleased" do
    it "infers major bumps from breaking changes" do
      changelog = <<~CHANGELOG
        ### [Unreleased]
        #### Breaking Changes
        - Breaking change
      CHANGELOG
      expect(inferred_bump_type_from_unreleased(changelog)).to eq(:major)
    end

    it "infers minor bumps from added sections" do
      changelog = <<~CHANGELOG
        ### [Unreleased]
        #### Added
        - Added feature
      CHANGELOG
      expect(inferred_bump_type_from_unreleased(changelog)).to eq(:minor)
    end

    it "infers patch bumps from fixed sections" do
      changelog = <<~CHANGELOG
        ### [Unreleased]
        #### Fixed
        - Fixed bug
      CHANGELOG
      expect(inferred_bump_type_from_unreleased(changelog)).to eq(:patch)
    end
  end

  describe "#collapse_prerelease_sections" do
    it "preserves heading structure and indentation while collapsing sections" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        ### [16.4.0.rc.1] - 2026-03-01
        #### Added
        - First rc change
          - Nested detail

        #### Fixed
        - Shared fix

        ### [16.4.0.rc.0] - 2026-02-28
        #### Added
        - Second rc change

        #### Fixed
            code line

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Older fix
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      expect(collapsed).not_to include("### [16.4.0.rc.1]")
      expect(collapsed).not_to include("### [16.4.0.rc.0]")
      expect(collapsed).to include("#### Added\n- First rc change\n  - Nested detail")
      expect(collapsed).to include("#### Added\n- Second rc change")
      expect(collapsed).to include("#### Fixed\n- Shared fix")
      expect(collapsed).to include("#### Fixed\n    code line")
      expect(collapsed).to include("### [16.3.0] - 2026-02-01")
    end
  end

  describe "#fetch_git_tags!" do
    it "refreshes local tags from origin when a remote exists" do
      Dir.mktmpdir do |dir|
        remote_dir = File.join(dir, "remote.git")
        source_dir = File.join(dir, "source")
        local_dir = File.join(dir, "local")

        run_git!("init", "--bare", remote_dir, chdir: dir)
        run_git!("clone", remote_dir, source_dir, chdir: dir)
        init_git_repo!(source_dir)
        run_git!("tag", "v16.3.0", chdir: source_dir)
        run_git!("push", "origin", "HEAD", chdir: source_dir)
        run_git!("push", "origin", "--tags", chdir: source_dir)

        run_git!("clone", remote_dir, local_dir, chdir: dir)

        run_git!("tag", "v16.4.0", chdir: source_dir)
        run_git!("push", "origin", "--tags", chdir: source_dir)

        expect(stable_tag_versions(local_dir)).to contain_exactly("16.3.0")

        fetch_git_tags!(local_dir)

        expect(stable_tag_versions(local_dir)).to contain_exactly("16.3.0", "16.4.0")
      end
    end
  end

  describe "#prerelease_indices_from_tags" do
    it "recognizes dash-form prerelease tags" do
      Dir.mktmpdir do |repo_dir|
        init_git_repo!(repo_dir)
        run_git!("tag", "v16.4.0-rc.0", chdir: repo_dir)

        expect(prerelease_indices_from_tags(repo_dir, "16.4.0", "rc")).to eq([0])
      end
    end
  end

  describe "#compute_auto_version" do
    it "uses active prerelease content when inferring a release version" do
      Dir.mktmpdir do |repo_dir|
        init_git_repo!(repo_dir)
        run_git!("tag", "v16.3.0", chdir: repo_dir)

        changelog = <<~CHANGELOG
          ### [Unreleased]

          ### [16.4.0.rc.1] - 2026-03-01
          #### Added
          - Feature from RC
        CHANGELOG

        prepared_changelog = prepare_changelog_for_auto_version(changelog, repo_dir)
        version = compute_auto_version(changelog, "release", repo_dir, changelog_for_bump: prepared_changelog)

        expect(version).to eq("16.4.0")
        expect(prepared_changelog).to include("Feature from RC")
        expect(prepared_changelog).not_to include("### [16.4.0.rc.1]")
      end
    end

    it "continues the active rc series even when Unreleased is sparse" do
      Dir.mktmpdir do |repo_dir|
        init_git_repo!(repo_dir)
        run_git!("tag", "v16.3.0", chdir: repo_dir)

        changelog = <<~CHANGELOG
          ### [Unreleased]

          ### [16.4.0.rc.0] - 2026-03-01
          #### Added
          - Feature from RC
        CHANGELOG

        prepared_changelog = prepare_changelog_for_auto_version(changelog, repo_dir)
        version = compute_auto_version(changelog, "rc", repo_dir, changelog_for_bump: prepared_changelog)

        expect(version).to eq("16.4.0.rc.1")
      end
    end
  end
end
