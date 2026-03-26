# frozen_string_literal: true

require_relative "../react_on_rails_pro/spec_helper"
require "async/promise"

# Contract canary for the Async::Promise semantics that consumer_stream_async relies on.
# These examples only call wait on already-settled promises, so they do not require a
# running reactor to observe the resolved/rejected behavior under test.
RSpec.describe Async::Promise do
  it "reports unresolved before resolution" do
    promise = described_class.new

    expect(promise.resolved?).to be false
  end

  it "reports resolved after resolve" do
    promise = described_class.new
    promise.resolve("result")

    expect(promise.resolved?).to be true
  end

  it "ignores a second resolve call" do
    promise = described_class.new

    expect { promise.resolve("first") }.not_to raise_error
    expect { promise.resolve("second") }.not_to raise_error
    expect(promise.wait).to eq("first") # safe: already resolved, no fiber yield needed
  end

  it "reports resolved after reject" do
    promise = described_class.new
    promise.reject(StandardError.new("boom"))

    expect(promise.resolved?).to be true
  end

  it "re-raises the exception on wait after reject" do
    promise = described_class.new
    promise.reject(StandardError.new("boom"))

    expect { promise.wait }.to raise_error(StandardError, "boom")
  end
end
