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

      it "escapes </script> in props so the payload cannot terminate the surrounding script tag" do
        payload = { x: "</script><script>alert('xss')</script>" }.to_json

        escaped = described_class.escape(payload)

        expect(escaped).to eq(
          '{"x":"\\u003c/script\\u003e\\u003cscript\\u003ealert(\'xss\')\\u003c/script\\u003e"}'
        )
        expect(escaped).not_to include("</script>")
      end
    end
  end
end
