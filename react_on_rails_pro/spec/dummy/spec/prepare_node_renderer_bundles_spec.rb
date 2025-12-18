# frozen_string_literal: true

require "rails_helper"

describe ReactOnRailsPro::PrepareNodeRenderBundles do # rubocop:disable RSpec/FilePath,RSpec/SpecFilePathFormat
  let(:asset_filename) { "loadable-stats2.json" }
  let(:asset_filename2) { "loadable-stats3.json" }
  let(:fixture_path) { File.expand_path("./spec/fixtures/#{asset_filename}") }
  let(:fixture_path2) { File.expand_path("./spec/fixtures/#{asset_filename2}") }
  let(:non_exist_fixture_path) { File.expand_path("./spec/fixtures/sample99.json") }
  let(:asset_path_expanded) { path_in_bundles_folder(asset_filename) }
  let(:asset_path_expanded2) { path_in_bundles_folder(asset_filename2) }

  before do
    dbl_configuration = instance_double(ReactOnRailsPro::Configuration,
                                        server_renderer: "NodeRenderer",
                                        renderer_password: "myPassword1",
                                        renderer_url: "http://localhost:3800",
                                        renderer_request_retry_limit: 5,
                                        assets_to_copy: [
                                          path_in_webpack_folder(asset_filename),
                                          path_in_webpack_folder(asset_filename2)
                                        ])
    allow(ReactOnRailsPro).to receive(:configuration).and_return(dbl_configuration)
    FileUtils.mkdir_p(Rails.root.join("public", "webpack", "production"))
    FileUtils.rm_f(asset_path_expanded)
    FileUtils.rm_f(asset_path_expanded2)
  end

  context("when assets exist") do
    before do
      FileUtils.cp(fixture_path, path_in_webpack_folder(asset_filename))
      FileUtils.cp(fixture_path2, path_in_webpack_folder(asset_filename2))
    end

    it "copying asset to public folder" do
      expect(asset_exist_on_renderer?(asset_filename)).to be(false)
      expect(asset_exist_on_renderer?(asset_filename2)).to be(false)
      described_class.call
      expect(asset_exist_on_renderer?(asset_filename)).to be(true)
      expect(asset_exist_on_renderer?(asset_filename2)).to be(true)
      expect(Pathname.new(File.readlink(asset_path_expanded)).relative?).to be(true)
      expect(File.realpath(asset_path_expanded)).to eq(path_in_webpack_folder(asset_filename).to_s)
    end
  end

  context("when assets don't exist") do
    it "prints warning if asset not found" do
      first_asset_path = path_in_webpack_folder(asset_filename)
      FileUtils.rm_f(first_asset_path)
      expect do
        described_class.call
      end.to output("Asset not found #{first_asset_path}\n").to_stderr
    end
  end

  def path_in_bundles_folder(filename)
    Rails.root.join(".node-renderer-bundles", filename)
  end

  def path_in_webpack_folder(filename)
    Rails.root.join("public", "webpack", "production", filename)
  end

  def asset_exist_on_renderer?(filename)
    File.exist?(path_in_bundles_folder(filename))
  end
end
