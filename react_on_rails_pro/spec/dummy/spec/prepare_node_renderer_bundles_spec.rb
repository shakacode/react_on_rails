# frozen_string_literal: true

require "rails_helper"

describe ReactOnRailsPro::PrepareNodeRenderBundles do # rubocop:disable RSpec/FilePath
  let(:asset_filename) { "loadable-stats2.json" }
  let(:asset_filename2) { "loadable-stats3.json" }
  let(:fixture_path) { File.expand_path("./spec/fixtures/#{asset_filename}") }
  let(:fixture_path2) { File.expand_path("./spec/fixtures/#{asset_filename2}") }
  let(:non_exist_fixture_path) { File.expand_path("./spec/fixtures/sample99.json") }
  let(:asset_path_expanded) { Rails.root.join(".node-renderer-bundles", asset_filename) }
  let(:asset_path_expanded2) { Rails.root.join(".node-renderer-bundles", asset_filename2) }

  before do
    dbl_configuration = instance_double("Configuration",
                                        server_renderer: "NodeRenderer",
                                        renderer_password: "myPassword1",
                                        renderer_url: "http://localhost:3800",
                                        renderer_request_retry_limit: 5,
                                        assets_to_copy: [
                                          Rails.root.join("public", "webpack", "production", "loadable-stats2.json"),
                                          Rails.root.join("public", "webpack", "production", "loadable-stats3.json")
                                        ])
    allow(ReactOnRailsPro).to receive(:configuration).and_return(dbl_configuration)
    FileUtils.mkdir_p(Rails.root.join("public", "webpack", "production"))
    File.delete(asset_path_expanded) if File.exist?(asset_path_expanded)
    File.delete(asset_path_expanded2) if File.exist?(asset_path_expanded2)
  end

  context("when assets exist") do
    before do
      FileUtils.cp(fixture_path, Rails.root.join("public", "webpack", "production", asset_filename))
      FileUtils.cp(fixture_path2, Rails.root.join("public", "webpack", "production", asset_filename2))
    end

    it "copying asset to public folder" do
      expect(asset_exist_on_renderer?(asset_filename)).to eq(false)
      expect(asset_exist_on_renderer?(asset_filename2)).to eq(false)
      described_class.call
      expect(asset_exist_on_renderer?(asset_filename)).to eq(true)
      expect(asset_exist_on_renderer?(asset_filename2)).to eq(true)
    end
  end

  context("when assets don't exist") do
    it "prints warning if asset not found" do
      first_asset_path = Rails.root.join("public", "webpack", "production", asset_filename)
      File.delete(first_asset_path) if File.exist?(first_asset_path)
      expect do
        described_class.call
      end.to raise_error(ReactOnRails::Error) { |error|
               expect(error.message).to eq "Asset not found #{first_asset_path}"
             }
    end
  end

  def asset_exist_on_renderer?(filename)
    File.exist?(Rails.root.join(".node-renderer-bundles", filename))
  end
end
