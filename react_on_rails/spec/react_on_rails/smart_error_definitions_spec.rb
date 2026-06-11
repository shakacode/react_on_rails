# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe SmartError, ".error_definitions" do
    it "publishes unique stable codes for every SmartError type" do
      codes = described_class.error_definitions.values.map { |definition| definition.fetch(:code) }

      # Extend this exhaustive list when adding a new SmartError code.
      expect(codes).to eq(%w[ROR001 ROR002 ROR003 ROR004 ROR005 ROR006 ROR007])
    end

    it "builds a canonical docs URL for each published code" do
      described_class.error_definitions.each do |error_type, definition|
        code = definition.fetch(:code).downcase

        expect(described_class.docs_url_for(error_type))
          .to eq("https://reactonrails.com/docs/reference/error-reference##{code}")
      end
    end

    it "falls back to the unknown code without a docs URL" do
      error = described_class.new(error_type: :totally_unknown)

      expect(error.code).to eq("ROR000")
      expect(error.docs_url).to be_nil
      expect(error.message).to include("[ROR000]")
      expect(error.message).not_to include("Docs:")
    end

    it "can render every published SmartError sample context" do
      described_class.error_definitions.each do |error_type, definition|
        error = described_class.new(error_type:, **definition.fetch(:sample_context))

        expect(error.code).to eq(definition.fetch(:code))
        expect(error.docs_url).to eq(described_class.docs_url_for(error_type))
        expect(error.message).to include("[#{definition.fetch(:code)}]")
        expect(error.message).to include(error.docs_url)
      end
    end
  end
end
