# frozen_string_literal: true

require "securerandom"
require_relative "spec_helper"
require "react_on_rails_pro/renderer_cache_helpers"

describe ReactOnRailsPro::RendererCacheHelpers do
  describe ".collect_assets" do
    let(:config) do
      instance_double(ReactOnRailsPro::Configuration, assets_to_copy: [custom_asset], enable_rsc_support: false)
    end
    let(:custom_asset) { "/app/public/webpack/production/custom.json" }
    let(:loadable_stats_path) do
      File.join(Dir.tmpdir, "renderer-cache-helper-loadable-stats-#{Process.pid}-#{SecureRandom.hex(6)}.json")
    end

    before do
      allow(ReactOnRailsPro).to receive(:configuration).and_return(config)
      allow(ReactOnRails::PackerUtils).to receive(:asset_uri_from_packer)
        .with("loadable-stats.json")
        .and_return(loadable_stats_path)
    end

    after { FileUtils.rm_f(loadable_stats_path) }

    it "includes loadable-stats.json when it exists" do
      File.write(loadable_stats_path, "{}")

      expect(described_class.collect_assets.map(&:to_s)).to contain_exactly(custom_asset, loadable_stats_path)
    end

    it "does not add loadable-stats.json when it does not exist" do
      expect(described_class.collect_assets.map(&:to_s)).to contain_exactly(custom_asset)
    end

    it "does not add loadable-stats.json when packer cannot resolve the asset path" do
      allow(ReactOnRails::PackerUtils).to receive(:asset_uri_from_packer)
        .with("loadable-stats.json")
        .and_raise(KeyError, "missing manifest entry")

      expect(described_class.collect_assets.map(&:to_s)).to contain_exactly(custom_asset)
    end

    it "lets unexpected errors propagate rather than silently dropping the asset" do
      allow(ReactOnRails::PackerUtils).to receive(:asset_uri_from_packer)
        .with("loadable-stats.json")
        .and_raise(NoMethodError, "undefined method 'foo'")

      expect { described_class.collect_assets }.to raise_error(NoMethodError)
    end

    it "deduplicates collected assets" do
      allow(config).to receive(:assets_to_copy).and_return([custom_asset, loadable_stats_path])
      File.write(loadable_stats_path, "{}")

      expect(described_class.collect_assets.map(&:to_s)).to contain_exactly(custom_asset, loadable_stats_path)
    end
  end
end
