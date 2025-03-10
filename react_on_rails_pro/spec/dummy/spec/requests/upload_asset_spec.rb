# frozen_string_literal: true

require "rails_helper"

describe "Upload asset" do
  let(:asset_filename) { "loadable-stats2.json" }
  let(:asset_filename2) { "loadable-stats3.json" }
  let(:fixture_path) { File.expand_path("./spec/fixtures/#{asset_filename}") }
  let(:fixture_path2) { File.expand_path("./spec/fixtures/#{asset_filename2}") }
  let(:non_exist_fixture_path) { File.expand_path("./spec/fixtures/sample99.json") }
  let(:asset_path_expanded) { File.expand_path(asset_filename, "#{__dir__}/../../.node-renderer-bundles") }
  let(:asset_path_expanded2) { File.expand_path(asset_filename2, "#{__dir__}/../../.node-renderer-bundles") }

  before do
    dbl_configuration = instance_double(ReactOnRailsPro::Configuration,
                                        enable_rsc_support: false,
                                        server_renderer: "NodeRenderer",
                                        renderer_password: "myPassword1",
                                        renderer_url: "http://localhost:3800",
                                        renderer_http_pool_size: 1,
                                        renderer_http_pool_timeout: 5,
                                        renderer_http_pool_warn_timeout: 0.25,
                                        renderer_request_retry_limit: 5,
                                        ssr_timeout: 5,
                                        assets_to_copy: [
                                          Rails.root.join("public", "webpack", "production", "loadable-stats2.json"),
                                          Rails.root.join("public", "webpack", "production", "loadable-stats3.json")
                                        ])
    allow(ReactOnRailsPro).to receive(:configuration).and_return(dbl_configuration)
    ReactOnRailsPro::Request.reset_connection
    FileUtils.mkdir_p(Rails.root.join("public", "webpack", "production"))
    FileUtils.rm_f(asset_path_expanded)
    FileUtils.rm_f(asset_path_expanded2)
  end

  context("when assets exist") do
    before do
      FileUtils.cp(fixture_path, Rails.root.join("public", "webpack", "production", asset_filename))
      FileUtils.cp(fixture_path2, Rails.root.join("public", "webpack", "production", asset_filename2))
    end

    it "copying asset to public folder" do
      expect(asset_exist_on_renderer?(asset_filename)).to be(false)
      expect(asset_exist_on_renderer?(asset_filename2)).to be(false)
      ReactOnRailsPro::Request.upload_assets
      expect(asset_exist_on_renderer?(asset_filename)).to be(true)
      expect(asset_exist_on_renderer?(asset_filename2)).to be(true)
    end

    it "throws error if can't connect to node-renderer" do
      WebMock.disable_net_connect!(allow_localhost: false)
      stub_request(:any, /upload-assets/).to_timeout
      allow(ReactOnRailsPro.configuration).to receive(:ssr_timeout).and_return(0.5)
      ReactOnRailsPro::Request.reset_connection
      expect do
        ReactOnRailsPro::Request.upload_assets
      end.to raise_exception(ReactOnRailsPro::Error)
      WebMock.allow_net_connect!
    end
  end

  context("when assets don't exist") do
    it "prints warning if asset not found" do
      first_asset_path = Rails.root.join("public", "webpack", "production", asset_filename)
      FileUtils.rm_f(first_asset_path)
      expect do
        ReactOnRailsPro::Request.upload_assets
      end.to output("Asset not found #{first_asset_path}\n").to_stderr
    end
  end

  def asset_exist_on_renderer?(filename)
    ReactOnRailsPro::Request.asset_exists_on_vm_renderer?(filename)
  end
end
