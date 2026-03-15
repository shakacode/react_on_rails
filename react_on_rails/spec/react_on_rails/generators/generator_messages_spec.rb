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
    expect(message).to include('stream_react_component("HelloServer", props: @hello_server_props)')
    expect(message).not_to include("prerender: true")
    expect(message).not_to include('react_component("HelloServer", props: @hello_server_props, prerender: true)')
  end

  it "shows react_component in non-RSC install message" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world",
      rsc: false
    )

    expect(message).to include('react_component("HelloWorld", props: @hello_world_props, prerender: true)')
  end

  describe ".detect_package_manager" do
    it "returns bun when bun.lock exists" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("yarn.lock").and_return(false)
      allow(File).to receive(:exist?).with("pnpm-lock.yaml").and_return(false)
      allow(File).to receive(:exist?).with("bun.lock").and_return(true)

      expect(described_class.detect_package_manager).to eq("bun")
    end

    it "returns bun when bun.lockb exists" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("yarn.lock").and_return(false)
      allow(File).to receive(:exist?).with("pnpm-lock.yaml").and_return(false)
      allow(File).to receive(:exist?).with("bun.lock").and_return(false)
      allow(File).to receive(:exist?).with("bun.lockb").and_return(true)

      expect(described_class.detect_package_manager).to eq("bun")
    end
  end
end
