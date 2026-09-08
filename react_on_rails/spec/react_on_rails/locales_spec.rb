# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Locales do
    describe ".compile" do
      before do
        @original_output_format = ReactOnRails.configuration.i18n_output_format
        allow(ReactOnRails.configuration).to receive_messages(i18n_dir: nil, i18n_yml_dir: nil)
      end

      after do
        ReactOnRails.configuration.i18n_output_format = @original_output_format
      end

      it "by default compiles to JSON" do
        ReactOnRails.configuration.i18n_output_format = nil

        expect(ReactOnRails::Locales::ToJson).to receive(:new).and_call_original

        described_class.compile
      end

      it "by compiles to JS when specified" do
        ReactOnRails.configuration.i18n_output_format = "js"

        expect(ReactOnRails::Locales::ToJs).to receive(:new).and_call_original

        described_class.compile
      end

      it "compiles to JSON" do
        ReactOnRails.configuration.i18n_output_format = "JSON"

        expect(ReactOnRails::Locales::ToJson).to receive(:new).and_call_original

        described_class.compile
      end

      it "passes force parameter to ToJson" do
        ReactOnRails.configuration.i18n_output_format = nil

        expect(ReactOnRails::Locales::ToJson).to receive(:new).with(force: true).and_call_original

        described_class.compile(force: true)
      end

      it "passes force parameter to ToJs" do
        ReactOnRails.configuration.i18n_output_format = "js"

        expect(ReactOnRails::Locales::ToJs).to receive(:new).with(force: true).and_call_original

        described_class.compile(force: true)
      end
    end
  end
end
