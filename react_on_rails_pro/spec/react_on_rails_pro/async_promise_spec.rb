# frozen_string_literal: true

require_relative "spec_helper"
require "async/promise"

module ReactOnRailsPro
  RSpec.describe Async::Promise do
    it "reports resolved after resolve" do
      promise = described_class.new
      promise.resolve("result")

      expect(promise.resolved?).to be true
    end

    it "reports resolved after reject" do
      promise = described_class.new
      promise.reject(StandardError.new("boom"))

      expect(promise.resolved?).to be true
    end
  end
end
