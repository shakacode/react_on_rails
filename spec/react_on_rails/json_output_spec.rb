# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/json_output"

module ReactOnRails
  describe JsonOutput do
    let(:hash_value) do
      {
        simple: "hello world",
        special: '<>&\u2028\u2029'
      }
    end

    let(:escaped_json) do
      '{"simple":"hello world","special":"\\u003c\\u003e\\u0026\\\\u2028\\\\u2029"}'
    end

    shared_examples "escaped json" do
      it "returns a well-formatted json with escaped characters" do
        expect(subject).to eq(escaped_json)
      end
    end

    describe ".escape" do
      subject { described_class.escape(hash_value.to_json) }

      it_behaves_like "escaped json"
    end

    describe ".escaped_without_erb_utils" do
      subject { described_class.escape_without_erb_util(hash_value.to_json) }

      it_behaves_like "escaped json"
    end
  end
end
