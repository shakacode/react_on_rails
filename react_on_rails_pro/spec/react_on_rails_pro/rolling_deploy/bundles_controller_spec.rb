# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../../app/controllers/react_on_rails_pro/rolling_deploy/bundles_controller"

describe ReactOnRailsPro::RollingDeploy::BundlesController do
  describe ".forgery protection" do
    # Regression guard: CodeQL flags both `protect_from_forgery with:
    # :null_session` (weakened) and the absence of `protect_from_forgery`
    # (not enabled). For a GET-only bearer-token API the strategy never
    # actually fires (Rails skips CSRF on GET), so `:exception` is the
    # form that satisfies CodeQL without changing runtime behavior.
    it "uses Rails exception CSRF protection" do
      expect(described_class.forgery_protection_strategy)
        .to eq(ActionController::RequestForgeryProtection::ProtectionMethods::Exception)
    end
  end

  describe ".draw_routes" do
    let(:mapper) { instance_spy(ActionDispatch::Routing::Mapper) }

    def route_hash_pattern_matches_segment?(hash)
      Regexp.new("\\A(?:#{described_class::ROUTE_HASH_PATTERN.source})\\z").match?(hash)
    end

    it "keeps the route hash pattern derived from the safe hash pattern without anchors" do
      expect(described_class::ROUTE_HASH_PATTERN.source)
        .to eq(described_class::SAFE_HASH_PATTERN.source.delete_prefix("\\A").delete_suffix("\\z"))
    end

    {
      "abc123" => true,
      "_hash" => true,
      "hash-with.dots" => true,
      "valid_hash-123.js" => true,
      "" => false,
      ".starts_with_dot" => false,
      "-starts-with-dash" => false,
      "has!bang" => false,
      "../traversal" => false,
      "slash/path" => false
    }.each do |hash, expected|
      it "#{expected ? 'accepts' : 'rejects'} hash segment #{hash.inspect}" do
        expect(route_hash_pattern_matches_segment?(hash)).to eq(expected)
      end
    end

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

  describe "#set_no_store_headers" do
    it "sets no-store and content-sniffing guard headers" do
      controller = described_class.new
      headers = {}

      allow(controller).to receive(:response).and_return(instance_double(ActionDispatch::Response, headers: headers))

      controller.send(:set_no_store_headers)

      expect(headers).to eq(
        "Cache-Control" => "no-store",
        "Pragma" => "no-cache",
        "X-Content-Type-Options" => "nosniff"
      )
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

  describe "#authenticate_rolling_deploy_request" do
    let(:controller) { described_class.new }
    let(:valid_token) { "a" * 32 }

    def stub_token(token)
      allow(ReactOnRailsPro).to receive(:configuration).and_return(
        instance_double(ReactOnRailsPro::Configuration, rolling_deploy_token: token)
      )
    end

    def stub_request_headers(headers)
      allow(controller).to receive(:request).and_return(
        instance_double(ActionDispatch::Request, headers: headers)
      )
    end

    before do
      # Spy on `head` so the spec doesn't need a real response cycle.
      allow(controller).to receive(:head)
    end

    context "when no token is configured" do
      before { stub_token("") }

      it "returns 401 with no Authorization header" do
        stub_request_headers({})
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).to have_received(:head).with(:unauthorized)
      end

      it "returns 401 even when a syntactically valid Bearer header is provided" do
        stub_request_headers({ "Authorization" => "Bearer #{valid_token}" })
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).to have_received(:head).with(:unauthorized)
      end
    end

    context "when a token is configured" do
      before { stub_token(valid_token) }

      it "returns 401 when the Authorization header is missing" do
        stub_request_headers({})
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).to have_received(:head).with(:unauthorized)
      end

      it "returns 401 when the Authorization scheme is not Bearer" do
        stub_request_headers({ "Authorization" => "Token #{valid_token}" })
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).to have_received(:head).with(:unauthorized)
      end

      it "returns 401 when the Bearer value is empty" do
        stub_request_headers({ "Authorization" => "Bearer " })
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).to have_received(:head).with(:unauthorized)
      end

      it "returns 401 when the token bytes are wrong but the length matches" do
        stub_request_headers({ "Authorization" => "Bearer #{'b' * 32}" })
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).to have_received(:head).with(:unauthorized)
      end

      it "returns 401 when the token is the right value but the wrong length (truncation guard)" do
        stub_request_headers({ "Authorization" => "Bearer #{valid_token[0..-2]}" })
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).to have_received(:head).with(:unauthorized)
      end

      it "passes through (no head invocation) when the Bearer token matches exactly" do
        stub_request_headers({ "Authorization" => "Bearer #{valid_token}" })
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).not_to have_received(:head)
      end

      it "accepts the lowercase 'bearer' scheme prefix" do
        stub_request_headers({ "Authorization" => "bearer #{valid_token}" })
        controller.send(:authenticate_rolling_deploy_request)
        expect(controller).not_to have_received(:head)
      end
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

    it "warns and returns [] when node_renderer? is false so operators see the misconfiguration" do
      allow(ReactOnRailsPro).to receive(:configuration).and_return(
        instance_double(ReactOnRailsPro::Configuration, node_renderer?: false)
      )

      expect(controller.send(:safe_current_bundle_sources)).to eq([])
      expect(Rails.logger).to have_received(:warn).with(/node_renderer\? is false/)
    end
  end
end
