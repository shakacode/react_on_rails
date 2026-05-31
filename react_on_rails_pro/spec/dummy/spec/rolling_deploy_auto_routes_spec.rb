# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rolling-deploy auto routes", type: :request do
  let(:config) { ReactOnRailsPro.configuration }
  let(:default_path) { ReactOnRailsPro::Configuration::DEFAULT_ROLLING_DEPLOY_MOUNT_PATH }
  let(:token) { "a" * 32 }

  around do |example|
    original_adapter = config.rolling_deploy_adapter
    original_mount_path = config.rolling_deploy_mount_path
    original_token = config.rolling_deploy_token

    example.run
  ensure
    config.rolling_deploy_adapter = original_adapter
    config.rolling_deploy_mount_path = original_mount_path
    config.rolling_deploy_token = original_token
    Rails.application.reload_routes!
  end

  def configure_rolling_deploy_routes(adapter:, mount_path:, rolling_deploy_token: token)
    config.rolling_deploy_adapter = adapter
    config.rolling_deploy_mount_path = mount_path
    config.rolling_deploy_token = rolling_deploy_token
    Rails.application.reload_routes!
  end

  def route_for(path)
    Rails.application.routes.recognize_path(path, method: :get)
  end

  def route_set_with_auto_mount
    path = default_path

    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.prepend do
        ReactOnRailsPro::RollingDeploy::BundlesController.draw_routes(
          self,
          path: path,
          # Must match ReactOnRailsPro::Engine::ROLLING_DEPLOY_AUTO_ROUTE_PREFIX.
          as_prefix: "react_on_rails_pro_auto_rolling_deploy"
        )
      end
    end
  end

  it "auto-mounts the bundles controller when the built-in HTTP adapter is configured" do
    configure_rolling_deploy_routes(
      adapter: ReactOnRailsPro::RollingDeployAdapters::Http,
      mount_path: default_path
    )
    allow(ReactOnRailsPro::RendererCacheHelpers).to receive(:bundle_sources).and_return([])

    get "#{default_path}/manifest", headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to include("hashes" => [])
  end

  it "keeps the auto-mounted routes after Rails reloads routes" do
    configure_rolling_deploy_routes(
      adapter: ReactOnRailsPro::RollingDeployAdapters::Http,
      mount_path: default_path
    )

    expect { Rails.application.reload_routes! }.not_to raise_error
    expect(route_for("#{default_path}/manifest")).to include(
      controller: "react_on_rails_pro/rolling_deploy/bundles",
      action: "manifest"
    )
  end

  it "does not collide with an existing manual mount that uses the default helper prefix" do
    routes = route_set_with_auto_mount
    path = default_path

    expect do
      routes.draw do
        ReactOnRailsPro::RollingDeploy::BundlesController.draw_routes(self, path: path)
      end
    end.not_to raise_error
    expect(routes.named_routes.helper_names).to include(
      "react_on_rails_pro_auto_rolling_deploy_manifest_path",
      "react_on_rails_pro_rolling_deploy_manifest_path"
    )
  end

  it "keeps the auto-mounted routes ahead of application catch-all routes" do
    routes = route_set_with_auto_mount
    routes.draw do
      get "*all", to: "pages#index", as: :catch_all
    end

    expect(routes.recognize_path("#{default_path}/manifest", method: :get)).to include(
      controller: "react_on_rails_pro/rolling_deploy/bundles",
      action: "manifest"
    )
  end

  it "mounts at the configured custom path" do
    configure_rolling_deploy_routes(
      adapter: ReactOnRailsPro::RollingDeployAdapters::Http,
      mount_path: "/internal/rolling-deploy"
    )

    expect(route_for("/internal/rolling-deploy/manifest")).to include(
      controller: "react_on_rails_pro/rolling_deploy/bundles",
      action: "manifest"
    )
    expect { route_for("#{default_path}/manifest") }.to raise_error(ActionController::RoutingError)
  end

  it "does not route bundle requests with invalid hash segments" do
    configure_rolling_deploy_routes(
      adapter: ReactOnRailsPro::RollingDeployAdapters::Http,
      mount_path: default_path
    )

    expect(route_for("#{default_path}/bundles/valid_hash-123.js")).to include(
      controller: "react_on_rails_pro/rolling_deploy/bundles",
      action: "show",
      hash: "valid_hash-123.js"
    )
    expect { route_for("#{default_path}/bundles/valid!trailing") }
      .to raise_error(ActionController::RoutingError)
  end

  it "does not mount the routes when the rolling-deploy adapter is nil" do
    configure_rolling_deploy_routes(adapter: nil, mount_path: default_path, rolling_deploy_token: nil)

    expect { route_for("#{default_path}/manifest") }.to raise_error(ActionController::RoutingError)
  end

  it "does not mount the routes for non-HTTP custom adapters" do
    custom_adapter = Module.new do
      def self.previous_bundle_hashes = []
      def self.fetch(_hash) = nil
      def self.upload(_bundle:, _assets: []) = nil
    end

    configure_rolling_deploy_routes(
      adapter: custom_adapter,
      mount_path: default_path,
      rolling_deploy_token: nil
    )

    expect { route_for("#{default_path}/manifest") }.to raise_error(ActionController::RoutingError)
  end

  [nil, ""].each do |mount_path|
    it "treats #{mount_path.inspect} mount path as an auto-mount opt-out" do
      configure_rolling_deploy_routes(
        adapter: ReactOnRailsPro::RollingDeployAdapters::Http,
        mount_path: mount_path
      )

      expect { route_for("#{default_path}/manifest") }.to raise_error(ActionController::RoutingError)
    end
  end
end
