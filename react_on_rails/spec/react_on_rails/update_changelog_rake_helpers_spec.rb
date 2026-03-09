# frozen_string_literal: true

require_relative "simplecov_helper"
require_relative "spec_helper"

RSpec.describe "update_changelog.rake helper methods" do
  before do
    next if Object.instance_variable_defined?(:@update_changelog_rake_helpers_loaded)

    load File.expand_path("../../rakelib/update_changelog.rake", __dir__)
    Object.instance_variable_set(:@update_changelog_rake_helpers_loaded, true)
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
    it "collapses prior prerelease sections for the same base version" do
      changelog = <<~CHANGELOG
        ### [Unreleased]

        #### Fixed
        - New fix

        ### [16.4.0.rc.1] - 2026-03-01
        #### Added
        - First rc change
        - Shared line

        ### [16.4.0.rc.0] - 2026-02-28
        #### Changed
        - Zeroth rc change
        - Shared line

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Older fix
      CHANGELOG

      collapsed = collapse_prerelease_sections(changelog, "16.4.0", "rc")

      expect(collapsed).not_to include("### [16.4.0.rc.1]")
      expect(collapsed).not_to include("### [16.4.0.rc.0]")
      expect(collapsed).to include("First rc change")
      expect(collapsed).to include("Zeroth rc change")
      expect(collapsed.scan("Shared line").size).to eq(1)
      expect(collapsed).to include("### [16.3.0] - 2026-02-01")
    end
  end
end
