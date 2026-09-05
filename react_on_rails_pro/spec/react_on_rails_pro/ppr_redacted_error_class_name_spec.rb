# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/ppr"

describe ReactOnRailsPro::Ppr, ".redacted_error_class_name" do
  subject(:result) { described_class.redacted_error_class_name(error) }

  context "with a named error class" do
    let(:error) { RuntimeError.new("user@example.com session token abc123") }

    it "returns the class name only" do
      expect(result).to eq("RuntimeError")
    end

    it "does not leak the raw message" do
      expect(result).not_to include("user@example.com")
    end
  end

  context "with a namespaced error class" do
    let(:error) do
      klass = Class.new(StandardError)
      stub_const("MyApp::CustomError", klass)
      MyApp::CustomError.new("sensitive data")
    end

    it "returns the full namespaced class name" do
      expect(result).to eq("MyApp::CustomError")
    end
  end

  context "with an anonymous error class" do
    let(:error) { Class.new(ArgumentError).new("should not leak") }

    it "falls back to the superclass name" do
      expect(result).to eq("ArgumentError")
    end

    it "does not leak the raw message" do
      expect(result).not_to include("should not leak")
    end
  end

  context "with a double-anonymous error class" do
    let(:error) { Class.new(Class.new(StandardError)).new("deeply nested") }

    it "returns a non-nil string" do
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it "does not leak the raw message" do
      expect(result).not_to include("deeply nested")
    end
  end

  it "never returns nil" do
    error = StandardError.new("anything")
    expect(described_class.redacted_error_class_name(error)).not_to be_nil
  end
end
