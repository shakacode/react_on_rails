require_relative "../simplecov_helper"

describe GeneratorMessages do
  it "has an empty messages array" do
    expect(GeneratorMessages.messages).to be_empty
  end

  it "has a method that can add errors" do
    GeneratorMessages.add_error "Test error"
    expect(GeneratorMessages.messages)
      .to match_array([GeneratorMessages.format_error("Test error")])
  end

  it "has a method that can add warnings" do
    GeneratorMessages.add_warning "Test warning"
    expect(GeneratorMessages.messages)
      .to match_array([GeneratorMessages.format_warning("Test warning")])
  end

  it "has a method that can add info messages" do
    GeneratorMessages.add_info "Test info message"
    expect(GeneratorMessages.messages)
      .to match_array([GeneratorMessages.format_info("Test info message")])
  end
end
