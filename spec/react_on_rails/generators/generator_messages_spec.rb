# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

describe GeneratorMessages do
  it "has an empty messages array" do
    expect(described_class.messages).to be_empty
  end

  it "has a method that can add errors" do
    described_class.add_error "Test error"
    expect(described_class.messages)
      .to match_array([described_class.format_error("Test error")])
  end

  it "has a method that can add warnings" do
    described_class.add_warning "Test warning"
    expect(described_class.messages)
      .to match_array([described_class.format_warning("Test warning")])
  end

  it "has a method that can add info messages" do
    described_class.add_info "Test info message"
    expect(described_class.messages)
      .to match_array([described_class.format_info("Test info message")])
  end
end
