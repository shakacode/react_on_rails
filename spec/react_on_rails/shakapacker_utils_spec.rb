# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe ShakapackerUtils do
    describe ".using_shakapacker?" do
      subject do
        described_class.using_shakapacker?
      end

      it { is_expected.to be(true) }
    end

    describe ".shackapacker_version_requirement_met?" do
      minimum_version = [7, 2, 1]

      it "returns false when version is lower than minimum_version" do
        allow(described_class).to receive(:shakapacker_version).and_return("7.2.0")
        expect(described_class.shackapacker_version_requirement_met?(minimum_version)).to be(false)

        allow(described_class).to receive(:shakapacker_version).and_return("7.1.0")
        expect(described_class.shackapacker_version_requirement_met?(minimum_version)).to be(false)

        allow(described_class).to receive(:shakapacker_version).and_return("6.6.0")
        expect(described_class.shackapacker_version_requirement_met?(minimum_version)).to be(false)
      end

      it "returns true when version is equal to minimum_version" do
        allow(described_class).to receive(:shakapacker_version).and_return("7.2.1")
        expect(described_class.shackapacker_version_requirement_met?(minimum_version)).to be(true)
      end

      it "returns true when version is greater than minimum_version" do
        allow(described_class).to receive(:shakapacker_version).and_return("7.2.3")
        expect(described_class.shackapacker_version_requirement_met?(minimum_version)).to be(true)

        allow(described_class).to receive(:shakapacker_version).and_return("7.3.0")
        expect(described_class.shackapacker_version_requirement_met?(minimum_version)).to be(true)

        allow(described_class).to receive(:shakapacker_version).and_return("8.0.0")
        expect(described_class.shackapacker_version_requirement_met?(minimum_version)).to be(true)
      end
    end
  end
end
