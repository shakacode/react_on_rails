# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/license_scanner"

RSpec.describe ReactOnRails::LicenseScanner do
  subject(:scanner) { described_class.new }

  describe "#scan" do
    it "scans ruby gems and returns a result" do
      result = scanner.scan
      expect(result).to be_a(described_class::Result)
      expect(result.scanned_count).to be_positive
      expect(result.violations).to be_an(Array)
      expect(result.warnings).to be_an(Array)
    end

    it "reports no violations for the react_on_rails dependency tree" do
      result = scanner.scan
      expect(result.violations).to be_empty
    end
  end

  describe "license classification" do
    let(:result_struct) { described_class::Result }

    describe "DISALLOWED_LICENSES" do
      it "includes GPL and AGPL variants" do
        expect(described_class::DISALLOWED_LICENSES).to include("GPL-2.0", "GPL-3.0", "AGPL-3.0")
      end
    end

    describe "PERMISSIVE_LICENSES" do
      it "includes common permissive licenses" do
        expect(described_class::PERMISSIVE_LICENSES).to include("MIT", "Apache-2.0", "BSD-2-Clause")
      end
    end
  end

  describe "multi-licensed gems" do
    it "treats dual MIT/GPL as a warning, not a violation" do
      result = scanner.scan

      gpl_violations = result.violations.select { |v| v.licenses.any? { |l| l.include?("GPL") } }
      expect(gpl_violations).to be_empty

      diff_lcs_warning = result.warnings.find { |w| w.name == "diff-lcs" }
      expect(diff_lcs_warning.licenses).to include("MIT") if diff_lcs_warning
    end
  end
end
