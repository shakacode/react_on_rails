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

    shared_examples :escaped_json do
      it "returns a well-formatted json with escaped characters" do
        expect(subject).to eq(escaped_json)
      end
    end

    describe ".escape" do
      subject { described_class.escape(hash_value.to_json) }

      context "with Rails version 4.1.1 and higher" do
        before { allow(Rails).to receive(:version).and_return("4.1.1") }

        it_behaves_like :escaped_json
      end

      context "with Rails version lower than 4.1.1" do
        before { allow(Rails).to receive(:version).and_return("4.1.0") }

        it_behaves_like :escaped_json
      end
    end

    describe ".escaped_without_erb_utils" do
      subject { described_class.escape_without_erb_util(hash_value.to_json) }

      it_behaves_like :escaped_json
    end
  end
end
