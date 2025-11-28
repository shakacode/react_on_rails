# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRailsPro
  RSpec.describe ImmediateAsyncValue do
    describe "#initialize" do
      it "stores the value" do
        immediate_value = described_class.new("<div>Cached</div>")
        expect(immediate_value.value).to eq("<div>Cached</div>")
      end
    end

    describe "#value" do
      it "returns the stored value immediately" do
        immediate_value = described_class.new("<div>Cached Content</div>")
        expect(immediate_value.value).to eq("<div>Cached Content</div>")
      end
    end

    describe "#resolved?" do
      it "always returns true" do
        immediate_value = described_class.new("any value")
        expect(immediate_value.resolved?).to be true
      end
    end

    describe "#to_s" do
      it "returns the string representation of the value" do
        immediate_value = described_class.new("<div>Content</div>")
        expect(immediate_value.to_s).to eq("<div>Content</div>")
      end
    end

    describe "#html_safe" do
      it "returns the html_safe version of the value" do
        html_content = "<div>Content</div>"
        immediate_value = described_class.new(html_content)
        result = immediate_value.html_safe

        expect(result).to be_html_safe
        expect(result).to eq("<div>Content</div>")
      end
    end
  end
end
