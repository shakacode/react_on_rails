# frozen_string_literal: true

require_relative "spec_helper"
require "rack/deflater"

RSpec.describe ReactOnRailsPro::CompressionMiddlewareGuard do
  let(:middleware_entry_class) { Struct.new(:klass, :args) }

  describe "#findings" do
    it "flags Rack::Deflater callbacks that iterate the body" do
      condition = lambda { |*, body|
        sum = 0
        body.each { |chunk| sum += chunk.bytesize }
        sum > 512
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: condition }])]
      )

      expect(guard.findings.map(&:middleware_name)).to eq(["Rack::Deflater"])
      expect(guard.findings.first.source_location).to eq(condition.source_location)
    end

    it "does not flag safe callbacks that gate on to_ary" do
      condition = lambda { |*, body|
        return true unless body.respond_to?(:to_ary)

        body.to_ary.sum(&:bytesize) > 512
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: condition }])]
      )

      expect(guard.findings).to be_empty
    end

    it "flags Rack::Brotli by class name without loading the gem" do
      stub_const("Rack::Brotli", Class.new)

      condition = lambda { |*, body|
        chunks = 0
        body.each { |_chunk| chunks += 1 }
        chunks.positive?
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Brotli, [{ if: condition }])]
      )

      expect(guard.findings.map(&:middleware_name)).to eq(["Rack::Brotli"])
    end

    it "ignores non-compression middleware" do
      stub_const("ExampleMiddleware", Class.new)

      condition = lambda { |*, body|
        chunks = 0
        body.each { |_chunk| chunks += 1 }
        chunks.positive?
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(ExampleMiddleware, [{ if: condition }])]
      )

      expect(guard.findings).to be_empty
    end
  end

  describe "#warning_messages" do
    it "includes the middleware source location and remediation" do
      condition = lambda { |*, body|
        chunks = 0
        body.each { |_chunk| chunks += 1 }
        chunks.positive?
      }

      repo_root = File.expand_path("../../..", __dir__)
      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: condition }])]
      )

      message = guard.warning_messages(root: repo_root).first

      expect(message).to include("Rack::Deflater has a custom `:if` callback")
      expect(message).to include("compression_middleware_guard_spec.rb:#{condition.source_location.last}")
      expect(message).to include("return true unless body.respond_to?(:to_ary)")
      expect(message).to include(described_class::COMPATIBILITY_GUIDE_PATH)
    end
  end
end
