# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"

RSpec.describe ReactOnRailsPro::StreamRequest do
  describe ".create" do
    it "returns a StreamDecorator instance" do
      result = described_class.create { mock_response }
      expect(result).to be_a(ReactOnRailsPro::StreamDecorator)
    end
  end
end
