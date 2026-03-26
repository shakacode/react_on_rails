# frozen_string_literal: true

require_relative "../react_on_rails_pro/spec_helper"
require "async/promise"

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
    expect(promise.wait).to eq("first")
  end

  it "reports resolved after reject" do
    promise = described_class.new
    promise.reject(StandardError.new("boom"))

    expect(promise.resolved?).to be true
  end
end
