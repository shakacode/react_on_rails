# frozen_string_literal: true

require_relative "./simplecov_helper"
require_relative "./spec_helper"
require_relative "./support/version_test_helpers"
require_relative "../../lib/react_on_rails/version_syntax_converter"

RSpec.describe ReactOnRails::VersionSyntaxConverter do
  subject(:converter) { described_class.new }

  describe "#rubygem_to_npm" do
    context "when gem version is 1.0.0" do
      specify { expect(converter.rubygem_to_npm("1.0.0")).to eq "1.0.0" }
    end

    context "when gem version is 10.20.30.rc.4" do
      specify { expect(converter.rubygem_to_npm("10.20.30.rc.4")).to eq "10.20.30-rc.4" }
    end
  end

  describe "#npm_to_rubygem" do
    context "with an npm version of '0.0.2'" do
      specify { expect(converter.npm_to_rubygem("0.0.2")).to eq("0.0.2") }
    end

    context "with an npm version of '^14.0.0-beta.2'" do
      specify { expect(converter.npm_to_rubygem("^14.0.0-beta.2")).to eq("14.0.0.beta.2") }
    end

    context "with an npm version of '../../..'" do
      specify { expect(converter.npm_to_rubygem("../../..")).to be_nil }
    end
  end
end
