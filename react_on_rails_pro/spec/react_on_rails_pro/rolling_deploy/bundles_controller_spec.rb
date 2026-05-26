# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../../app/controllers/react_on_rails_pro/rolling_deploy/bundles_controller"

describe ReactOnRailsPro::RollingDeploy::BundlesController do
  describe "base class" do
    # Regression guard: this controller is bearer-token authenticated, so it
    # must not inherit the CSRF middleware that ActionController::Base ships
    # with. CodeQL flags `protect_from_forgery with: :null_session` on a Base
    # controller as weakened CSRF; the fix is to use ActionController::API,
    # which omits the RequestForgeryProtection module entirely.
    it "inherits from ActionController::API (omits CSRF middleware)" do
      expect(described_class.ancestors).to include(ActionController::API)
      expect(described_class.ancestors).not_to include(ActionController::RequestForgeryProtection)
    end
  end

  describe ".draw_routes" do
    let(:mapper) { instance_spy(ActionDispatch::Routing::Mapper) }

    it "uses the default route helper prefix" do
      described_class.draw_routes(mapper, path: "/rolling")

      expect(mapper).to have_received(:get).with(
        "/rolling/manifest",
        hash_including(as: :react_on_rails_pro_rolling_deploy_manifest)
      )
      expect(mapper).to have_received(:get).with(
        "/rolling/bundles/:hash",
        hash_including(as: :react_on_rails_pro_rolling_deploy_bundle)
      )
    end

    it "honors a custom as_prefix so the controller can be mounted twice without collisions" do
      described_class.draw_routes(mapper, path: "/internal/ror", as_prefix: "internal_rolling")

      expect(mapper).to have_received(:get).with(
        "/internal/ror/manifest",
        hash_including(as: :internal_rolling_manifest)
      )
      expect(mapper).to have_received(:get).with(
        "/internal/ror/bundles/:hash",
        hash_including(as: :internal_rolling_bundle)
      )
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

  describe "#tarball_entries" do
    let(:controller) { described_class.new }

    before do
      allow(Rails).to receive(:logger).and_return(instance_double(Logger, warn: nil))
    end

    it "keeps the bundle when no companions are present" do
      allow(controller).to receive(:companion_assets).and_return([])

      expect(controller.send(:tarball_entries, "/srv/bundle-hash.js"))
        .to eq("bundle.js" => "/srv/bundle-hash.js")
    end

    it "skips a companion whose basename collides with the bundle entry" do
      allow(controller).to receive(:companion_assets).and_return([
                                                                   "/srv/other/bundle.js",
                                                                   "/srv/loadable-stats.json"
                                                                 ])

      entries = controller.send(:tarball_entries, "/srv/server-hash.js")

      expect(entries).to eq(
        "bundle.js" => "/srv/server-hash.js",
        "loadable-stats.json" => "/srv/loadable-stats.json"
      )
      expect(Rails.logger).to have_received(:warn).with(/basename collides with bundle entry/)
    end

    it "skips duplicate companion basenames and keeps the first" do
      allow(controller).to receive(:companion_assets).and_return([
                                                                   "/srv/a/manifest.json",
                                                                   "/srv/b/manifest.json"
                                                                 ])

      entries = controller.send(:tarball_entries, "/srv/bundle.js")

      expect(entries).to eq(
        "bundle.js" => "/srv/bundle.js",
        "manifest.json" => "/srv/a/manifest.json"
      )
      expect(Rails.logger).to have_received(:warn).with(/duplicate companion basename/)
    end

    it "skips companions whose basename is not a safe tarball entry name" do
      allow(controller).to receive(:companion_assets).and_return([
                                                                   "/srv/.hidden.json",
                                                                   "/srv/loadable-stats.json"
                                                                 ])

      entries = controller.send(:tarball_entries, "/srv/bundle.js")

      expect(entries).to eq(
        "bundle.js" => "/srv/bundle.js",
        "loadable-stats.json" => "/srv/loadable-stats.json"
      )
      expect(Rails.logger).to have_received(:warn).with(/is not a safe tarball entry name/)
    end
  end

  describe "#safe_current_bundle_sources" do
    let(:controller) { described_class.new }
    let(:pool) { class_double(ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool) }

    before do
      stub_const("ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool", pool)
      allow(ReactOnRailsPro).to receive(:configuration).and_return(
        instance_double(ReactOnRailsPro::Configuration, node_renderer?: true)
      )
      allow(Rails).to receive(:logger).and_return(instance_double(Logger, warn: nil))
    end

    it "returns an empty array when bundle_sources raises a non-ReactOnRailsPro error" do
      allow(ReactOnRailsPro::RendererCacheHelpers)
        .to receive(:bundle_sources)
        .and_raise(NoMethodError, "undefined method `bundle_hash' for nil:NilClass")

      expect(controller.send(:safe_current_bundle_sources)).to eq([])
      expect(Rails.logger).to have_received(:warn).with(/bundle source discovery failed/)
    end
  end
end
