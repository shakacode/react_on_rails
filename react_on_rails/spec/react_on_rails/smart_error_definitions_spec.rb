# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe SmartError, ".error_definitions" do
    it "publishes unique stable codes for every SmartError type" do
      codes = described_class.error_definitions.values.map { |definition| definition.fetch(:code) }

      expect(codes).to eq(%w[ROR001 ROR002 ROR003 ROR004 ROR005 ROR006 ROR007])
      expect(codes.uniq).to eq(codes)
    end

    it "builds a canonical docs URL for each published code" do
      described_class.error_definitions.each do |error_type, definition|
        code = definition.fetch(:code).downcase

        expect(described_class.docs_url_for(error_type))
          .to eq("https://reactonrails.com/docs/reference/error-reference##{code}")
      end
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
