# frozen_string_literal: true

require_relative "spec_helper"
require "rack/deflater"

RSpec.describe ReactOnRailsPro::CompressionMiddlewareGuard do
  let(:middleware_entry_class) { Struct.new(:klass, :args) }
  let(:logger) { instance_double(Logger, debug: nil) }

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

    it "does not flag middleware without an :if callback" do
      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [])]
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

    it "does not crash on callable objects without source_location" do
      callable_class = Class.new do
        def call(*args)
          body = args.last
          sum = 0
          body.each { |chunk| sum += chunk.bytesize }
          sum > 512
        end
      end

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: callable_class.new }])]
      )

      expect(guard.findings.map(&:source_location)).to eq([nil])
    end

    it "flags callbacks that iterate via Enumerable helpers" do
      condition = lambda { |*, body|
        body.sum(&:bytesize) > 512
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: condition }])]
      )

      expect(guard.findings.map(&:middleware_name)).to eq(["Rack::Deflater"])
    end

    it "flags callbacks that rescue StandardError after iterating body.each" do
      condition = lambda { |*, body|
        begin
          body.each(&:bytesize)
        rescue StandardError
          true
        end
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: condition }])]
      )

      expect(guard.findings.map(&:middleware_name)).to eq(["Rack::Deflater"])
    end

    it "flags callbacks that only iterate when Brotli is accepted" do
      stub_const("Rack::Brotli", Class.new)

      condition = lambda { |env, _status, _headers, body|
        next false unless env["HTTP_ACCEPT_ENCODING"].include?("br")

        body.each(&:bytesize)
        true
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Brotli, [{ if: condition }])]
      )

      expect(guard.findings.map(&:middleware_name)).to eq(["Rack::Brotli"])
    end

    it "logs probe failures at debug and returns no findings" do
      condition = lambda { |_env, *_rest|
        raise ArgumentError, "unexpected"
      }

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: condition }])],
        logger: logger
      )

      expect(guard.findings).to be_empty
      expect(logger).to have_received(:debug)
    end

    it "treats timed out probes as non-findings and logs debug" do
      condition = lambda { |_env, *_rest|
        sleep 5
      }
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: condition }])],
        logger: logger
      )

      expect(guard.findings).to be_empty
      expect(logger).to have_received(:debug)
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

    it "formats warnings cleanly when source_location is unavailable" do
      callable_class = Class.new do
        def call(*args)
          body = args.last
          body.each(&:bytesize)
          true
        end
      end

      guard = described_class.new(
        middlewares: [middleware_entry_class.new(Rack::Deflater, [{ if: callable_class.new }])]
      )

      message = guard.warning_messages(root: File.expand_path("../../..", __dir__)).first

      expect(message).to include("custom `:if` callback that calls `body.each`")
      expect(message).not_to include("callbackthat")
    end
  end
end
