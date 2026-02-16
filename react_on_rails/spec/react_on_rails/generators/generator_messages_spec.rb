# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

describe GeneratorMessages do
  it "has an empty messages array" do
    expect(described_class.messages).to be_empty
  end

  it "has a method that can add errors" do
    described_class.add_error "Test error"
    expect(described_class.messages)
      .to contain_exactly(described_class.format_error("Test error"))
  end

  it "has a method that can add warnings" do
    described_class.add_warning "Test warning"
    expect(described_class.messages)
      .to contain_exactly(described_class.format_warning("Test warning"))
  end

  it "has a method that can add info messages" do
    described_class.add_info "Test info message"
    expect(described_class.messages)
      .to contain_exactly(described_class.format_info("Test info message"))
  end

  it "shows stream_react_component in RSC install message" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloServer",
      route: "hello_server",
      rsc: true
    )

    expect(message).to include("stream_react_component")
    expect(message).not_to include('react_component("HelloServer"')
  end

  it "shows react_component in non-RSC install message" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world",
      rsc: false
    )

    expect(message).to include('react_component("HelloWorld"')
  end
end
