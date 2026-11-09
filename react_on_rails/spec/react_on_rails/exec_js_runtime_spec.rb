# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/exec_js_runtime"

# Issue #5288: ExecJS 2.9+ autodetects Bun ahead of Node.js, and Bun fails to evaluate
# some server bundles, so React on Rails prefers Node.js for its own server rendering.
describe ReactOnRails::ExecJSRuntime do
  let(:bun) { instance_double(ExecJS::ExternalRuntime, name: "Bun.sh") }
  let(:mini_racer) { instance_double(ExecJS::Runtime, name: "mini_racer (V8)") }

  around do |example|
    original = ENV.fetch("EXECJS_RUNTIME", nil)
    ENV.delete("EXECJS_RUNTIME")
    example.run
  ensure
    original.nil? ? ENV.delete("EXECJS_RUNTIME") : ENV["EXECJS_RUNTIME"] = original
  end

  describe ".for_server_rendering" do
    context "when ExecJS autodetected Bun and Node.js is available" do
      before do
        allow(ExecJS).to receive(:runtime).and_return(bun)
        allow(ExecJS::Runtimes::Node).to receive(:available?).and_return(true)
      end

      it "uses Node.js" do
        expect(described_class.for_server_rendering).to equal(ExecJS::Runtimes::Node)
      end

      it "leaves the global ExecJS runtime unchanged" do
        expect(ExecJS).not_to receive(:runtime=)

        described_class.for_server_rendering

        expect(ExecJS.runtime).to equal(bun)
      end
    end

    context "when ExecJS autodetected Bun and Node.js is not installed" do
      before do
        allow(ExecJS).to receive(:runtime).and_return(bun)
        allow(ExecJS::Runtimes::Node).to receive(:available?).and_return(false)
      end

      it "keeps Bun" do
        expect(described_class.for_server_rendering).to equal(bun)
      end
    end

    context "when EXECJS_RUNTIME explicitly selects Bun" do
      before do
        ENV["EXECJS_RUNTIME"] = "Bun"
        allow(ExecJS).to receive(:runtime).and_return(bun)
        allow(ExecJS::Runtimes::Node).to receive(:available?).and_return(true)
      end

      it "respects the explicit choice" do
        expect(described_class.for_server_rendering).to equal(bun)
      end
    end

    context "when ExecJS selected a runtime other than Bun" do
      before do
        allow(ExecJS).to receive(:runtime).and_return(mini_racer)
        allow(ExecJS::Runtimes::Node).to receive(:available?).and_return(true)
      end

      it "keeps that runtime" do
        expect(described_class.for_server_rendering).to equal(mini_racer)
      end
    end
  end
end
