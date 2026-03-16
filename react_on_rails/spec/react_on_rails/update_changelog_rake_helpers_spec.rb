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
    it "consolidates blocks with the same heading while preserving content" do
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
      # Both Added entries should be under a single #### Added heading
      expect(collapsed).to include("- First rc change\n  - Nested detail")
      expect(collapsed).to include("- Second rc change")
      expect(collapsed.scan(/^#### Added\b/).count).to eq(1)
      # Both Fixed entries should be under a single #### Fixed heading
      expect(collapsed).to include("- Shared fix")
      expect(collapsed).to include("    code line")
      # 1 consolidated in Unreleased + 1 in 16.3.0
      expect(collapsed.scan(/^#### Fixed\b/).count).to eq(2)
      expect(collapsed).to include("### [16.3.0] - 2026-02-01")
    end

    it "preserves #### Pro header for ##### sub-sections" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        #### Fixed
        - OSS fix from unreleased

        ### [16.4.0.rc.1] - 2026-03-01

        #### Fixed
        - OSS fix from rc.1

        #### Pro

        ##### Fixed
        - Pro fix from rc.1

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Older fix
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      # OSS Fixed entries should be consolidated (1 in Unreleased + 1 in 16.3.0)
      expect(collapsed.scan(/^#### Fixed\b/).count).to eq(2)
      expect(collapsed).to include("- OSS fix from unreleased")
      expect(collapsed).to include("- OSS fix from rc.1")
      # Pro header must be preserved before ##### sub-sections
      expect(collapsed).to include("#### Pro")
      expect(collapsed).to include("##### Fixed\n- Pro fix from rc.1")
      # #### Pro should appear before ##### Fixed in the output
      pro_pos = collapsed.index("#### Pro")
      pro_fixed_pos = collapsed.index("##### Fixed")
      expect(pro_pos).to be < pro_fixed_pos
    end

    it "preserves #### Pro when it appears in multiple collapsed sections" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        ### [16.4.0.rc.1] - 2026-03-01

        #### Pro

        ##### Added
        - Pro feature from rc.1

        ### [16.4.0.rc.0] - 2026-02-28

        #### Pro

        ##### Fixed
        - Pro fix from rc.0

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Older fix
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      # Only one #### Pro header should remain
      expect(collapsed.scan("#### Pro").count).to eq(1)
      # Both Pro sub-sections should be present
      expect(collapsed).to include("- Pro feature from rc.1")
      expect(collapsed).to include("- Pro fix from rc.0")
    end

    it "deduplicates entries with the same PR number across collapsed sections" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        #### Fixed
        - **Bug fix A**. [PR 2489](https://github.com/shakacode/react_on_rails/pull/2489) by [user](https://github.com/user).

        ### [16.4.0.rc.1] - 2026-03-01
        #### Fixed
        - **Bug fix A**. [PR 2489](https://github.com/shakacode/react_on_rails/pull/2489) by [user](https://github.com/user).
        - **Bug fix B**. [PR 2490](https://github.com/shakacode/react_on_rails/pull/2490) by [user](https://github.com/user).

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Older fix
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      # PR 2489 should appear only once (deduplicated)
      expect(collapsed.scan("PR 2489").count).to eq(1)
      # PR 2490 should still be present
      expect(collapsed).to include("PR 2490")
      expect(collapsed).to include("- **Bug fix A**")
      expect(collapsed).to include("- **Bug fix B**")
    end

    it "does not leave a dangling ##### heading when deduplicating duplicate PR entries" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        ### [16.4.0.rc.1] - 2026-03-01
        #### Pro

        ##### Fixed
        - **Bug fix A**. [PR 2489](https://github.com/shakacode/react_on_rails/pull/2489) by [user](https://github.com/user).

        ### [16.4.0.rc.0] - 2026-02-28
        #### Pro

        ##### Fixed
        - **Bug fix A**. [PR 2489](https://github.com/shakacode/react_on_rails/pull/2489) by [user](https://github.com/user).
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      expect(collapsed.scan(/^##### Fixed\b/).count).to eq(1)
      expect(collapsed.scan("PR 2489").count).to eq(1)
      expect(collapsed).to include("##### Fixed\n- **Bug fix A**")
    end

    it "strips 'Changes since the last non-beta release.' marker text" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        ### [16.4.0.rc.0] - 2026-02-28
        #### Added
        - RC-specific feature

        Changes since the last non-beta release.

        #### Fixed
        - Accumulated fix

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Older fix
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      expect(collapsed).not_to include("Changes since the last non-beta release")
      expect(collapsed).to include("- RC-specific feature")
      expect(collapsed).to include("- Accumulated fix")
    end

    it "consolidates ⚠️ and non-emoji breaking-change headings together" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        #### ⚠️ Breaking Changes
        - Breaking change from unreleased

        ### [16.4.0.rc.0] - 2026-02-28
        #### Breaking Changes
        - Breaking change from rc
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      expect(collapsed.scan(/^####\s+(?:⚠️\s*)?Breaking Changes\b/).count).to eq(1)
      expect(collapsed).to include("- Breaking change from unreleased")
      expect(collapsed).to include("- Breaking change from rc")
    end

    it "does not add extra blank entries when a block body starts with blank lines" do
      block = <<~BLOCK
        #### Fixed

        - **Bug fix A**. [PR 2489](https://github.com/shakacode/react_on_rails/pull/2489) by [user](https://github.com/user).
      BLOCK

      deduped = deduplicate_block_entries(block)

      expect(deduped).to eq(<<~EXPECTED)
        #### Fixed
        - **Bug fix A**. [PR 2489](https://github.com/shakacode/react_on_rails/pull/2489) by [user](https://github.com/user).
      EXPECTED
    end

    it "keeps nested bullets attached when parent lines are duplicated" do
      block = <<~BLOCK
        #### Fixed
        - **Bug fix A**.
          - Handles edge case alpha.
        - **Bug fix A**.
          - Handles edge case beta.
      BLOCK

      deduped = deduplicate_block_entries(block)

      expect(deduped).to eq(block)
    end
  end

  describe "#cleanup_collapsed_prerelease_links" do
    it "removes orphaned prerelease compare links and updates [unreleased] to point to stable" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        #### Added
        - Merged content from rc.1 and rc.0

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Older fix

        [unreleased]: https://github.com/shakacode/react_on_rails/compare/16.4.0.rc.1...master
        [16.4.0.rc.1]: https://github.com/shakacode/react_on_rails/compare/16.4.0.rc.0...16.4.0.rc.1
        [16.4.0.rc.0]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...16.4.0.rc.0
        [16.3.0]: https://github.com/shakacode/react_on_rails/compare/v16.2.1...v16.3.0
      CHANGELOG

      result = cleanup_collapsed_prerelease_links(changelog, "16.4.0")

      expect(result).to include("[unreleased]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...master")
      expect(result).not_to include("[16.4.0.rc.1]:")
      expect(result).not_to include("[16.4.0.rc.0]:")
      expect(result).to include("[16.3.0]: https://github.com/shakacode/react_on_rails/compare/v16.2.1...v16.3.0")
    end

    it "handles a single prerelease link" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        [unreleased]: https://github.com/shakacode/react_on_rails/compare/16.4.0.rc.8...master
        [16.4.0.rc.8]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...16.4.0.rc.8
        [16.3.0]: https://github.com/shakacode/react_on_rails/compare/v16.2.1...v16.3.0
      CHANGELOG

      result = cleanup_collapsed_prerelease_links(changelog, "16.4.0")

      expect(result).to include("[unreleased]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...master")
      expect(result).not_to include("[16.4.0.rc.8]:")
      expect(result).to include("[16.3.0]:")
    end

    it "returns changelog unchanged when no prerelease links exist" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        [unreleased]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...master
        [16.3.0]: https://github.com/shakacode/react_on_rails/compare/v16.2.1...v16.3.0
      CHANGELOG

      result = cleanup_collapsed_prerelease_links(changelog, "16.4.0")

      expect(result).to eq(changelog)
    end
  end

  describe "#update_changelog_links" do
    it "updates [unreleased] and adds a new version compare link" do
      changelog = +"[unreleased]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...master\n" \
                   "[16.3.0]: https://github.com/shakacode/react_on_rails/compare/v16.2.1...v16.3.0\n"

      update_changelog_links(changelog, "16.4.0", "[16.4.0]")

      expect(changelog).to include("[unreleased]: https://github.com/shakacode/react_on_rails/compare/16.4.0...master")
      expect(changelog).to include("[16.4.0]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...16.4.0")
    end

    it "returns nil when [unreleased] compare link is absent" do
      changelog = +"### [Unreleased]\n\nSome content\n"

      result = update_changelog_links(changelog, "16.4.0", "[16.4.0]")

      expect(result).to be_nil
      expect(changelog).to eq("### [Unreleased]\n\nSome content\n")
    end
  end

  describe "#insert_version_header" do
    it "inserts after ### [Unreleased]" do
      changelog = +"### [Unreleased]\n\n#### Fixed\n- A fix\n"

      result = insert_version_header(changelog, "[16.4.0]", "2026-03-14")

      expect(result).to be true
      expect(changelog).to include("### [Unreleased]\n\n### [16.4.0] - 2026-03-14")
    end

    it "falls back to 'Changes since the last non-beta release.' marker" do
      changelog = +"Changes since the last non-beta release.\n\n#### Fixed\n- A fix\n"

      result = insert_version_header(changelog, "[16.4.0]", "2026-03-14")

      expect(result).to be true
      expect(changelog).to include("Changes since the last non-beta release.\n\n### [16.4.0] - 2026-03-14")
    end

    it "returns false when neither anchor is found" do
      changelog = +"#### Fixed\n- A fix\n"

      result = insert_version_header(changelog, "[16.4.0]", "2026-03-14")

      expect(result).to be false
      expect(changelog).to eq("#### Fixed\n- A fix\n")
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

    it "starts at rc.0 when only changelog draft prereleases exist" do
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

        expect(version).to eq("16.4.0.rc.0")
      end
    end
  end
end
