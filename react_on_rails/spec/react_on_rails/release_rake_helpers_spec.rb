# frozen_string_literal: true

require_relative "simplecov_helper"
require_relative "spec_helper"
require "tmpdir"

RSpec.describe "release.rake helper methods" do
  before do
    next if Object.instance_variable_defined?(:@release_rake_helpers_loaded)

    load File.expand_path("../../../rakelib/release.rake", __dir__)
    Object.instance_variable_set(:@release_rake_helpers_loaded, true)
  end

  describe "#parse_release_tag_to_gem_version" do
    it "parses stable tag versions" do
      expect(parse_release_tag_to_gem_version("v16.4.0")).to eq("16.4.0")
    end

    it "parses dotted prerelease tag versions" do
      expect(parse_release_tag_to_gem_version("v16.4.0.rc.1")).to eq("16.4.0.rc.1")
    end

    it "parses dashed prerelease tag versions" do
      expect(parse_release_tag_to_gem_version("v16.4.0-rc.1")).to eq("16.4.0.rc.1")
    end
  end

  describe "#version_bump_type" do
    it "detects major bumps" do
      bump_type = version_bump_type(previous_stable_gem_version: "16.3.0", target_gem_version: "17.0.0")
      expect(bump_type).to eq(:major)
    end

    it "detects minor bumps" do
      bump_type = version_bump_type(previous_stable_gem_version: "16.3.0", target_gem_version: "16.4.0")
      expect(bump_type).to eq(:minor)
    end

    it "detects patch bumps" do
      bump_type = version_bump_type(previous_stable_gem_version: "16.3.0", target_gem_version: "16.3.1")
      expect(bump_type).to eq(:patch)
    end
  end

  describe "#compute_target_gem_version" do
    it "computes semver keyword bumps from the current version" do
      expect(compute_target_gem_version(current_gem_version: "16.3.4", version_input: "patch")).to eq("16.3.5")
      expect(compute_target_gem_version(current_gem_version: "16.3.4", version_input: "minor")).to eq("16.4.0")
      expect(compute_target_gem_version(current_gem_version: "16.3.4", version_input: "major")).to eq("17.0.0")
    end

    it "passes through explicit versions unchanged" do
      expect(compute_target_gem_version(current_gem_version: "16.3.4",
                                        version_input: "16.4.0.rc.1")).to eq("16.4.0.rc.1")
    end
  end

  describe "#npm_dist_tag_for_version" do
    it "defaults stable releases to latest" do
      expect(npm_dist_tag_for_version("16.4.0")).to eq("latest")
    end

    it "extracts the prerelease channel for prerelease versions" do
      expect(npm_dist_tag_for_version("16.4.0-rc.1")).to eq("rc")
      expect(npm_dist_tag_for_version("16.4.0-beta.2")).to eq("beta")
    end
  end

  describe "#normalize_otp_code" do
    it "returns nil for nil input" do
      expect(normalize_otp_code(nil, service_name: "NPM")).to be_nil
    end

    it "strips valid numeric OTP values" do
      expect(normalize_otp_code(" 123456 ", service_name: "NPM")).to eq("123456")
    end

    it "rejects non-numeric OTP values" do
      expect do
        normalize_otp_code("12 34", service_name: "NPM")
      end.to raise_error(SystemExit, /Invalid OTP for NPM/)
    end
  end

  describe "#expected_bump_type_from_changelog_section" do
    it "returns major for breaking changes" do
      section = <<~MARKDOWN
        ### [16.4.0] - 2026-03-08
        #### Breaking Changes
        - Something changed
      MARKDOWN
      expect(expected_bump_type_from_changelog_section(section)).to eq(:major)
    end

    it "returns minor for added sections" do
      section = <<~MARKDOWN
        ### [16.4.0] - 2026-03-08
        #### Added
        - New feature
      MARKDOWN
      expect(expected_bump_type_from_changelog_section(section)).to eq(:minor)
    end

    it "returns patch for fixed sections" do
      section = <<~MARKDOWN
        ### [16.4.0] - 2026-03-08
        #### Fixed
        - Bug fix
      MARKDOWN
      expect(expected_bump_type_from_changelog_section(section)).to eq(:patch)
    end
  end

  describe "#extract_changelog_section" do
    it "extracts the matching changelog section" do
      changelog = <<~CHANGELOG
        # Change Log

        ### [Unreleased]

        ### [16.4.0] - 2026-03-08
        #### Added
        - Feature A

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Bug B
      CHANGELOG

      Dir.mktmpdir do |dir|
        changelog_path = File.join(dir, "CHANGELOG.md")
        File.write(changelog_path, changelog)

        section = extract_changelog_section(changelog_path: changelog_path, version: "16.4.0")
        expect(section).to include("Feature A")
        expect(section).not_to include("### [16.4.0] - 2026-03-08")
        expect(section).not_to include("Bug B")
      end
    end
  end

  describe "#run_release_preflight_checks!" do
    it "checks both npm and GitHub auth before a real release" do
      expect(self).to receive(:verify_npm_auth)
      expect(self).to receive(:verify_gh_auth).with(monorepo_root: "/tmp/repo")

      run_release_preflight_checks!(monorepo_root: "/tmp/repo", dry_run: false)
    end

    it "skips auth checks for dry runs" do
      expect(self).not_to receive(:verify_npm_auth)
      expect(self).not_to receive(:verify_gh_auth)

      run_release_preflight_checks!(monorepo_root: "/tmp/repo", dry_run: true)
    end
  end

  describe "#resolve_version_input" do
    it "uses the latest changelog version when it is newer than the current gem version" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.4.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")

      expect(resolve_version_input("", "/tmp/repo")).to eq("16.4.0")
    end

    it "falls back to a patch bump when the changelog does not introduce a newer version" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.3.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")

      expect(resolve_version_input("", "/tmp/repo")).to eq("patch")
    end
  end

  describe "#publish_gem_with_retry" do
    it "passes OTP via environment instead of shell interpolation" do
      expect(self).to receive(:sh_args_in_dir_for_release).with(
        "/tmp/gem",
        "gem",
        "release",
        env: { "GEM_HOST_OTP_CODE" => "123456" }
      )

      publish_gem_with_retry("/tmp/gem", "react_on_rails", otp: "123456", max_retries: 1)
    end
  end

  describe "#publish_npm_with_retry" do
    it "passes OTP as a dedicated CLI argument" do
      expect(self).to receive(:sh_args_in_dir_for_release).with(
        "/tmp/pkg",
        "pnpm",
        "publish",
        "--tag",
        "rc",
        "--otp",
        "123456"
      )

      publish_npm_with_retry(
        "/tmp/pkg",
        "react-on-rails@16.4.0-rc.1",
        base_args: ["--tag", "rc"],
        otp: "123456",
        max_retries: 1
      )
    end
  end

  describe "#validate_release_version_policy!" do
    it "skips downstream checks for same-base prerelease bumps" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.4.0.rc.0"])

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "16.4.0.rc.1",
          allow_override: false,
          fetch_tags: false
        )
      end.to output(/Skipping all downstream checks for same-base prerelease bump/).to_stdout
    end

    it "raises when the changelog-implied bump does not match the requested stable release version" do
      allow(self).to receive(:tagged_release_gem_versions).with("/tmp/repo", fetch_tags: false).and_return(["16.3.0"])
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "16.3.1")
        .and_return("#### Added\n- New feature\n")

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "16.3.1",
          allow_override: false,
          fetch_tags: false
        )
      end.to raise_error(SystemExit, /Version bump mismatch/)
    end
  end
end
