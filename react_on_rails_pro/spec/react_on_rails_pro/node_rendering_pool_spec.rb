# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool do
  describe ".renderer_bundle_file_name" do
    it "uses the pool server bundle hash" do
      allow(described_class).to receive(:server_bundle_hash).and_return("server-hash")
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("stale-utils-hash")

      expect(described_class.renderer_bundle_file_name).to eq("server-hash.js")
    end
  end

  describe ".rsc_renderer_bundle_file_name" do
    it "uses the pool RSC bundle hash" do
      allow(described_class).to receive(:rsc_bundle_hash).and_return("rsc-hash")
      allow(ReactOnRailsPro::Utils).to receive(:rsc_bundle_hash).and_return("stale-rsc-utils-hash")

      expect(described_class.rsc_renderer_bundle_file_name).to eq("rsc-hash.js")
    end
  end
end
