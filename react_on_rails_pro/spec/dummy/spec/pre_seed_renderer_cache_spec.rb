# frozen_string_literal: true

require "rails_helper"

# Spec lives under spec/dummy/spec/ because it requires the dummy Rails environment (Rails.root, webpack paths).
describe ReactOnRailsPro::PreSeedRendererCache do # rubocop:disable RSpec/FilePath,RSpec/SpecFilePathFormat
  subject(:pre_seed_cache) { described_class.call }

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

    # Clear env vars and deprecation warning guard
    ENV.delete("RENDERER_SERVER_BUNDLE_CACHE_PATH")
    ENV.delete("RENDERER_BUNDLE_PATH")
    ReactOnRailsPro::Utils.reset_renderer_bundle_path_deprecation_warned!
  end

  after do
    FileUtils.rm_rf(cache_dir)
    FileUtils.rm_f(server_bundle_path)
    FileUtils.rm_f(path_in_webpack_folder(asset_filename))
    FileUtils.rm_f(path_in_webpack_folder(asset_filename2))
    ENV.delete("RENDERER_SERVER_BUNDLE_CACHE_PATH")
    ENV.delete("RENDERER_BUNDLE_PATH")
  end

  context "when assets exist" do
    before do
      FileUtils.cp(fixture_path, path_in_webpack_folder(asset_filename))
      FileUtils.cp(fixture_path2, path_in_webpack_folder(asset_filename2))
    end

    it "copies server bundle into subdirectory structure" do
      pre_seed_cache

      dest_file = File.join(bundle_dir, "#{bundle_hash}.js")
      expect(File.exist?(dest_file)).to be(true)
      expect(File.read(dest_file)).to eq("// server bundle content")
      # Must be a copy, not a symlink
      expect(File.symlink?(dest_file)).to be(false)
    end

    it "copies assets into the bundle subdirectory" do
      pre_seed_cache

      expect(File.exist?(File.join(bundle_dir, asset_filename))).to be(true)
      expect(File.exist?(File.join(bundle_dir, asset_filename2))).to be(true)
    end
  end

  context "when assets don't exist" do
    it "prints warning for missing assets" do
      first_asset_path = path_in_webpack_folder(asset_filename)
      FileUtils.rm_f(first_asset_path)

      expect { pre_seed_cache }.to output(/Asset not found #{Regexp.escape(first_asset_path.to_s)}/).to_stderr
    end
  end

  context "when server bundle doesn't exist" do
    before { FileUtils.rm_f(server_bundle_path) }

    it "raises an error" do
      expect { pre_seed_cache }.to raise_error(ReactOnRailsPro::Error, /Bundle not found/)
    end
  end

  context "when RSC manifest is missing but RSC support is enabled" do
    before do
      allow(ReactOnRailsPro.configuration).to receive_messages(enable_rsc_support: true, assets_to_copy: nil)
      allow(ReactOnRailsPro::Utils).to receive_messages(
        rsc_bundle_js_file_path: server_bundle_path, # reuse existing bundle so it passes validate_bundle_exists!
        react_client_manifest_file_path: "/nonexistent/react-client-manifest.json",
        react_server_client_manifest_file_path: "/nonexistent/react-server-client-manifest.json"
      )

      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
      allow(pool).to receive(:rsc_bundle_hash).and_return("rsc-hash")
    end

    it "raises an error for missing required RSC assets" do
      expect { pre_seed_cache }.to raise_error(ReactOnRailsPro::Error, /Required RSC asset not found/)
    end
  end

  context "when RSC bundle doesn't exist but RSC support is enabled" do
    let(:client_manifest_path) { path_in_webpack_folder("react-client-manifest.json") }
    let(:server_client_manifest_path) { path_in_webpack_folder("react-server-client-manifest.json") }

    before do
      allow(ReactOnRailsPro.configuration).to receive_messages(enable_rsc_support: true, assets_to_copy: nil)
      # Manifests must point to real files so copy_assets doesn't raise "Required RSC asset not found"
      # before we reach validate_bundle_exists! for the RSC bundle.
      File.write(client_manifest_path, "{}")
      File.write(server_client_manifest_path, "{}")
      allow(ReactOnRailsPro::Utils).to receive_messages(
        rsc_bundle_js_file_path: "/nonexistent/rsc-bundle.js",
        react_client_manifest_file_path: client_manifest_path,
        react_server_client_manifest_file_path: server_client_manifest_path
      )

      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
      allow(pool).to receive(:rsc_bundle_hash).and_return("rsc-hash")
    end

    after do
      FileUtils.rm_f(client_manifest_path)
      FileUtils.rm_f(server_client_manifest_path)
    end

    it "raises an error" do
      expect { pre_seed_cache }.to raise_error(ReactOnRailsPro::Error, /Bundle not found/)
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
      pre_seed_cache

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
      expect { pre_seed_cache }.to output(/RENDERER_BUNDLE_PATH is deprecated/).to_stderr

      dest_file = File.join(custom_cache_dir, bundle_hash, "#{bundle_hash}.js")
      expect(File.exist?(dest_file)).to be(true)
    end
  end

  context "when both RENDERER_SERVER_BUNDLE_CACHE_PATH and RENDERER_BUNDLE_PATH are set" do
    let(:custom_cache_dir) { Dir.mktmpdir("renderer-cache-test") }

    before do
      ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = custom_cache_dir
      ENV["RENDERER_BUNDLE_PATH"] = "/some/old/path"
      allow(ReactOnRailsPro.configuration).to receive(:assets_to_copy).and_return(nil)
    end

    after { FileUtils.rm_rf(custom_cache_dir) }

    it "uses the preferred env var and emits no deprecation warning" do
      expect { pre_seed_cache }.not_to output(/deprecated/).to_stderr

      dest_file = File.join(custom_cache_dir, bundle_hash, "#{bundle_hash}.js")
      expect(File.exist?(dest_file)).to be(true)
    end
  end

  context "when RSC support is enabled" do
    let(:rsc_bundle_path) { Rails.root.join("public", "webpack", "production", "rsc-bundle.js").to_s }
    let(:rsc_bundle_hash) { "rsc-bundle-hash-xyz789" }
    let(:client_manifest_path) { path_in_webpack_folder("react-client-manifest.json") }
    let(:server_client_manifest_path) { path_in_webpack_folder("react-server-client-manifest.json") }

    before do
      dbl_configuration = instance_double(ReactOnRailsPro::Configuration,
                                          server_renderer: "NodeRenderer",
                                          renderer_password: "myPassword1",
                                          renderer_url: "http://localhost:3800",
                                          renderer_request_retry_limit: 5,
                                          enable_rsc_support: true,
                                          assets_to_copy: nil)
      allow(ReactOnRailsPro).to receive(:configuration).and_return(dbl_configuration)
      allow(ReactOnRailsPro::Utils).to receive_messages(
        rsc_bundle_js_file_path: rsc_bundle_path,
        react_client_manifest_file_path: client_manifest_path,
        react_server_client_manifest_file_path: server_client_manifest_path
      )

      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
      allow(pool).to receive(:rsc_bundle_hash).and_return(rsc_bundle_hash)

      FileUtils.mkdir_p(File.dirname(rsc_bundle_path))
      File.write(rsc_bundle_path, "// rsc bundle content")
      File.write(client_manifest_path, "{}")
      File.write(server_client_manifest_path, "{}")
    end

    after do
      FileUtils.rm_f(rsc_bundle_path)
      FileUtils.rm_f(client_manifest_path)
      FileUtils.rm_f(server_client_manifest_path)
    end

    it "pre-seeds both server and RSC bundle directories" do
      pre_seed_cache

      server_dest = File.join(cache_dir, bundle_hash, "#{bundle_hash}.js")
      rsc_dest = File.join(cache_dir, rsc_bundle_hash, "#{rsc_bundle_hash}.js")
      expect(File.exist?(server_dest)).to be(true)
      expect(File.exist?(rsc_dest)).to be(true)
      expect(File.read(rsc_dest)).to eq("// rsc bundle content")
    end

    it "copies RSC manifest assets into both bundle directories" do
      pre_seed_cache

      server_dir = File.join(cache_dir, bundle_hash)
      rsc_dir = File.join(cache_dir, rsc_bundle_hash)

      expect(File.exist?(File.join(server_dir, "react-client-manifest.json"))).to be(true)
      expect(File.exist?(File.join(server_dir, "react-server-client-manifest.json"))).to be(true)
      expect(File.exist?(File.join(rsc_dir, "react-client-manifest.json"))).to be(true)
      expect(File.exist?(File.join(rsc_dir, "react-server-client-manifest.json"))).to be(true)
    end
  end

  def path_in_webpack_folder(filename)
    Rails.root.join("public", "webpack", "production", filename)
  end
end
