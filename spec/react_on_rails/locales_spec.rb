# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Locales do
    describe ".compile" do
      before do
        @orginal_output_format = ReactOnRails.configuration.i18n_output_format
      end

      after do
        ReactOnRails.configuration.i18n_output_format = @orginal_output_format
      end

      it "by default compiles to JSON" do
        ReactOnRails.configuration.i18n_output_format = nil

        expect(ReactOnRails::Locales::ToJson).to receive(:new)

        described_class.compile
      end

      it "by compiles to JS when specified" do
        ReactOnRails.configuration.i18n_output_format = "js"

        expect(ReactOnRails::Locales::ToJs).to receive(:new)

        described_class.compile
      end

      it "compiles to JSON" do
        ReactOnRails.configuration.i18n_output_format = "JSON"

        expect(ReactOnRails::Locales::ToJson).to receive(:new)

        described_class.compile
      end
    end
  end
end
