# frozen_string_literal: true

require "rails_helper"

describe ReactOnRailsPro::RollingDeployCacheStager do # rubocop:disable RSpec/FilePath,RSpec/SpecFilePathFormat
  let(:cache_dir) { Dir.mktmpdir("rolling-deploy-test") }
  # rubocop:disable RSpec/VerifiedDoubleReference -- adapter is a user-supplied duck-typed module with no real class to reference
  let(:adapter) { class_double("RollingDeployAdapter") }
  # rubocop:enable RSpec/VerifiedDoubleReference

  before do
    allow(ReactOnRailsPro.configuration).to receive(:rolling_deploy_adapter).and_return(adapter)
    ENV.delete("PREVIOUS_BUNDLE_HASHES")
  end

  after do
    FileUtils.rm_rf(cache_dir)
    ENV.delete("PREVIOUS_BUNDLE_HASHES")
  end

  def source_file(name, contents: "// #{name}")
    path = File.join(cache_dir, "__sources", name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
    path
  end

  context "when adapter is not configured and no env override" do
    before { allow(ReactOnRailsPro.configuration).to receive(:rolling_deploy_adapter).and_return(nil) }

    it "is a no-op" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: ["cur"], mode: :copy) }
        .not_to raise_error
      expect(Dir.children(cache_dir)).to eq([])
    end
  end

  context "when adapter returns hashes and fetch succeeds" do
    let(:src_bundle) { source_file("bundle-abc.js") }
    let(:src_asset) { source_file("loadable-stats.json", contents: '{"chunks":{}}') }

    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch).with("abc123").and_return(
        server_bundle: src_bundle,
        rsc_bundle: nil,
        assets: [src_asset]
      )
    end

    it "copies bundle + assets into <cache>/<hash>/ in :copy mode" do
      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy)

      bundle_dir = File.join(cache_dir, "abc123")
      expect(File.exist?(File.join(bundle_dir, "abc123.js"))).to be(true)
      expect(File.exist?(File.join(bundle_dir, "loadable-stats.json"))).to be(true)
      expect(File.symlink?(File.join(bundle_dir, "abc123.js"))).to be(false)
    end

    it "symlinks bundle + assets in :symlink mode" do
      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :symlink)

      expect(File.symlink?(File.join(cache_dir, "abc123", "abc123.js"))).to be(true)
      expect(File.symlink?(File.join(cache_dir, "abc123", "loadable-stats.json"))).to be(true)
    end

    it "deduplicates against the current hash" do
      described_class.call(cache_dir: cache_dir, current_hashes: ["abc123"], mode: :copy)
      expect(adapter).not_to have_received(:fetch)
    end
  end

  context "when PREVIOUS_BUNDLE_HASHES env override is set" do
    let(:src_bundle) { source_file("bundle-xyz.js") }

    before do
      ENV["PREVIOUS_BUNDLE_HASHES"] = "xyz999"
      allow(adapter).to receive(:previous_bundle_hashes)
      allow(adapter).to receive(:fetch).with("xyz999").and_return(server_bundle: src_bundle, assets: [])
    end

    it "skips previous_bundle_hashes discovery and uses the env list" do
      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy)
      expect(adapter).not_to have_received(:previous_bundle_hashes)
      expect(File.exist?(File.join(cache_dir, "xyz999", "xyz999.js"))).to be(true)
    end
  end

  context "when adapter#fetch returns nil" do
    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["missing-hash"])
      allow(adapter).to receive(:fetch).with("missing-hash").and_return(nil)
    end

    it "warns and continues" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/returned nil/).to_stderr
      expect(Dir.children(cache_dir)).to eq([])
    end
  end

  context "when adapter#fetch raises" do
    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["broken-hash"])
      allow(adapter).to receive(:fetch).with("broken-hash").and_raise(StandardError, "network exploded")
    end

    it "warns but does not propagate" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/Failed to seed previous bundle hash broken-hash/).to_stderr
    end
  end

  context "when adapter#previous_bundle_hashes raises" do
    before { allow(adapter).to receive(:previous_bundle_hashes).and_raise(StandardError, "discovery failed") }

    it "warns and skips seeding" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/previous_bundle_hashes raised/).to_stderr
    end
  end

  context "when adapter returns payload without :server_bundle" do
    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["bad-hash"])
      allow(adapter).to receive(:fetch).with("bad-hash").and_return(assets: [])
    end

    it "warns and skips that hash" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/without.*valid :server_bundle path/m).to_stderr
    end
  end
end
