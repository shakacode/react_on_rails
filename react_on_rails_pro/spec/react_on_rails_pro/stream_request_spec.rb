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

  describe "#process_response_chunks" do
    subject(:request) { described_class.send(:new) { nil } }

    let(:error_body) { +"" }

    it "treats responses without status delegation as error responses" do
      response = Class.new do
        def each
          yield "Failed request body"
        end

        def status
          raise NoMethodError, "undefined method `status`"
        end
      end.new

      yielded_chunks = []
      expect do
        request.send(:process_response_chunks, response, error_body) do |chunk|
          yielded_chunks << chunk
        end
      end.not_to raise_error

      expect(error_body).to eq("Failed request body")
      expect(yielded_chunks).to be_empty
    end
  end
end
