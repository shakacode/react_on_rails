# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool do
  describe ".renderer_bundle_file_name" do
    it "uses the cached server bundle hash for consistency with render paths" do
      allow(described_class).to receive(:server_bundle_hash).and_return("server-hash")
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("different-hash")

      expect(described_class.renderer_bundle_file_name).to eq("server-hash.js")
    end
  end

  describe ".rsc_renderer_bundle_file_name" do
    it "uses the cached RSC bundle hash for consistency with render paths" do
      allow(described_class).to receive(:rsc_bundle_hash).and_return("rsc-hash")
      allow(ReactOnRailsPro::Utils).to receive(:rsc_bundle_hash).and_return("different-rsc-hash")

      expect(described_class.rsc_renderer_bundle_file_name).to eq("rsc-hash.js")
    end
  end
end
