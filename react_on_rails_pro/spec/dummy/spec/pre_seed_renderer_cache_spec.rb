# frozen_string_literal: true

require "rails_helper"

describe ReactOnRailsPro::PreSeedRendererCache do # rubocop:disable RSpec/FilePath,RSpec/SpecFilePathFormat
  let(:asset_filename) { "loadable-stats2.json" }
  let(:asset_filename2) { "loadable-stats3.json" }
  let(:fixture_path) { File.expand_path("./spec/fixtures/#{asset_filename}") }
  let(:fixture_path2) { File.expand_path("./spec/fixtures/#{asset_filename2}") }
  let(:bundle_hash) { "test-bundle-hash-abc123" }
  let(:cache_dir) { Rails.root.join(".node-renderer-bundles").to_s }
  let(:bundle_dir) { File.join(cache_dir, bundle_hash) }
  let(:server_bundle_path) { Rails.root.join("public", "webpack", "production", "server-bundle.js").to_s }

  before do
    dbl_configuration = instance_double(ReactOnRailsPro::Configuration,
                                        server_renderer: "NodeRenderer",
                                        renderer_password: "myPassword1",
                                        renderer_url: "http://localhost:3800",
                                        renderer_request_retry_limit: 5,
                                        enable_rsc_support: false,
                                        assets_to_copy: [
                                          path_in_webpack_folder(asset_filename),
                                          path_in_webpack_folder(asset_filename2)
                                        ])
    allow(ReactOnRailsPro).to receive(:configuration).and_return(dbl_configuration)
    allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path).and_return(server_bundle_path)

    pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
    allow(pool).to receive(:server_bundle_hash).and_return(bundle_hash)

    FileUtils.mkdir_p(File.dirname(server_bundle_path))
    File.write(server_bundle_path, "// server bundle content")

    # Ensure clean state
    FileUtils.rm_rf(cache_dir)

    # Clear env vars
    ENV.delete("RENDERER_SERVER_BUNDLE_CACHE_PATH")
    ENV.delete("RENDERER_BUNDLE_PATH")
  end

  after do
    FileUtils.rm_rf(cache_dir)
    ENV.delete("RENDERER_SERVER_BUNDLE_CACHE_PATH")
    ENV.delete("RENDERER_BUNDLE_PATH")
  end

  context "when assets exist" do
    before do
      FileUtils.cp(fixture_path, path_in_webpack_folder(asset_filename))
      FileUtils.cp(fixture_path2, path_in_webpack_folder(asset_filename2))
    end

    it "copies server bundle into subdirectory structure" do
      described_class.call

      dest_file = File.join(bundle_dir, "#{bundle_hash}.js")
      expect(File.exist?(dest_file)).to be(true)
      expect(File.read(dest_file)).to eq("// server bundle content")
      # Must be a copy, not a symlink
      expect(File.symlink?(dest_file)).to be(false)
    end

    it "copies assets into the bundle subdirectory" do
      described_class.call

      expect(File.exist?(File.join(bundle_dir, asset_filename))).to be(true)
      expect(File.exist?(File.join(bundle_dir, asset_filename2))).to be(true)
    end
  end

  context "when assets don't exist" do
    it "prints warning for missing assets" do
      first_asset_path = path_in_webpack_folder(asset_filename)
      FileUtils.rm_f(first_asset_path)

      expect { described_class.call }.to output(/Asset not found #{Regexp.escape(first_asset_path.to_s)}/).to_stderr
    end
  end

  context "when server bundle doesn't exist" do
    before { FileUtils.rm_f(server_bundle_path) }

    it "raises an error" do
      expect { described_class.call }.to raise_error(ReactOnRailsPro::Error, /Bundle not found/)
    end
  end

  context "with RENDERER_SERVER_BUNDLE_CACHE_PATH env var" do
    let(:custom_cache_dir) { Dir.mktmpdir("renderer-cache-test") }

    before do
      ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = custom_cache_dir
      # No assets for this test
      allow(ReactOnRailsPro.configuration).to receive(:assets_to_copy).and_return(nil)
    end

    after { FileUtils.rm_rf(custom_cache_dir) }

    it "uses the env var path" do
      described_class.call

      dest_file = File.join(custom_cache_dir, bundle_hash, "#{bundle_hash}.js")
      expect(File.exist?(dest_file)).to be(true)
    end
  end

  context "with deprecated RENDERER_BUNDLE_PATH env var" do
    let(:custom_cache_dir) { Dir.mktmpdir("renderer-cache-test") }

    before do
      ENV["RENDERER_BUNDLE_PATH"] = custom_cache_dir
      # No assets for this test
      allow(ReactOnRailsPro.configuration).to receive(:assets_to_copy).and_return(nil)
    end

    after { FileUtils.rm_rf(custom_cache_dir) }

    it "uses the deprecated env var with a warning" do
      expect { described_class.call }.to output(/RENDERER_BUNDLE_PATH is deprecated/).to_stderr

      dest_file = File.join(custom_cache_dir, bundle_hash, "#{bundle_hash}.js")
      expect(File.exist?(dest_file)).to be(true)
    end
  end

  def path_in_webpack_folder(filename)
    Rails.root.join("public", "webpack", "production", filename)
  end
end
