# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../../app/controllers/react_on_rails_pro/rolling_deploy/bundles_controller"

describe ReactOnRailsPro::RollingDeploy::BundlesController do
  describe ".forgery protection" do
    it "uses Rails null-session CSRF protection" do
      expect(described_class.forgery_protection_strategy)
        .to eq(ActionController::RequestForgeryProtection::ProtectionMethods::NullSession)
    end
  end

  describe "#companion_assets" do
    it "rejects absolute companion asset paths outside Rails.root" do
      Dir.mktmpdir("ror-pro-rails-root") do |rails_root|
        Dir.mktmpdir("ror-pro-outside-root") do |outside_root|
          inside_asset = File.join(rails_root, "public", "webpack", "loadable-stats.json")
          outside_asset = File.join(outside_root, "secret.json")
          FileUtils.mkdir_p(File.dirname(inside_asset))
          File.write(inside_asset, "{}")
          File.write(outside_asset, "{}")

          allow(Rails).to receive(:root).and_return(Pathname.new(rails_root))
          allow(ReactOnRailsPro::RendererCacheHelpers)
            .to receive(:collect_assets)
            .and_return([inside_asset, outside_asset])

          expect(described_class.new.send(:companion_assets)).to contain_exactly(inside_asset)
        end
      end
    end
  end
end
