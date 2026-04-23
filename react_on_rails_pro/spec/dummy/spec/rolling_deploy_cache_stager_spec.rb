# frozen_string_literal: true

require "rails_helper"

describe ReactOnRailsPro::RollingDeployCacheStager do # rubocop:disable RSpec/FilePath,RSpec/SpecFilePathFormat
  let(:cache_dir) { Dir.mktmpdir("rolling-deploy-test") }
  # rubocop:disable RSpec/VerifiedDoubleReference -- adapter is a user-supplied duck-typed module with no real class to reference
  let(:adapter) { class_double("RollingDeployAdapter") }
  # rubocop:enable RSpec/VerifiedDoubleReference

  before do
    allow(ReactOnRailsPro.configuration).to receive_messages(
      rolling_deploy_adapter: adapter,
      enable_rsc_support: false
    )
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

  context "when adapter is not configured but PREVIOUS_BUNDLE_HASHES is set" do
    before do
      allow(ReactOnRailsPro.configuration).to receive(:rolling_deploy_adapter).and_return(nil)
      ENV["PREVIOUS_BUNDLE_HASHES"] = "abc,def"
    end

    it "warns and skips seeding rather than crashing on nil adapter" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/no rolling_deploy_adapter is configured/).to_stderr
      expect(Dir.children(cache_dir)).to eq([])
    end
  end

  context "when adapter returns hashes and fetch succeeds" do
    let(:src_bundle) { source_file("bundle-abc.js") }
    let(:src_asset) { source_file("loadable-stats.json", contents: '{"chunks":{}}') }

    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch).with("abc123").and_return(bundle: src_bundle, assets: [src_asset])
    end

    it "copies bundle + assets into <cache>/<hash>/ in :copy mode" do
      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy)

      bundle_dir = File.join(cache_dir, "abc123")
      expect(File.exist?(File.join(bundle_dir, "abc123.js"))).to be(true)
      expect(File.exist?(File.join(bundle_dir, "loadable-stats.json"))).to be(true)
      expect(File.symlink?(File.join(bundle_dir, "abc123.js"))).to be(false)
    end

    it "creates relative symlinks in :symlink mode" do
      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :symlink)

      dest = File.join(cache_dir, "abc123", "abc123.js")
      expect(File.symlink?(dest)).to be(true)
      # relative_path_from produces a path that doesn't start with /
      expect(File.readlink(dest)).not_to start_with("/")
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
      allow(adapter).to receive(:fetch).with("xyz999").and_return(bundle: src_bundle, assets: [])
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

    it "warns with targeted fetch attribution and does not propagate" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/rolling_deploy_adapter#fetch\("broken-hash"\) raised StandardError: network exploded/).to_stderr
    end
  end

  context "when adapter#fetch times out" do
    before do
      stub_const("ReactOnRailsPro::RollingDeployCacheStager::FETCH_TIMEOUT_SECONDS", 0.05)
      allow(adapter).to receive_messages(previous_bundle_hashes: ["slow-hash"])
      allow(adapter).to receive(:fetch) do
        sleep 1
      end
    end

    it "warns and continues rather than blocking" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/timed out after/).to_stderr
    end
  end

  context "when adapter#previous_bundle_hashes raises" do
    before { allow(adapter).to receive(:previous_bundle_hashes).and_raise(StandardError, "discovery failed") }

    it "warns and skips seeding" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/previous_bundle_hashes raised/).to_stderr
    end
  end

  context "when adapter#previous_bundle_hashes times out" do
    before do
      stub_const("ReactOnRailsPro::RollingDeployCacheStager::DISCOVERY_TIMEOUT_SECONDS", 0.05)
      allow(adapter).to receive(:previous_bundle_hashes) { sleep 1 }
    end

    it "warns and skips seeding rather than blocking" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/previous_bundle_hashes timed out after/).to_stderr
    end
  end

  context "when PREVIOUS_BUNDLE_HASHES contains an unsafe path-traversal value" do
    let(:src_bundle) { source_file("bundle-ok.js") }

    before do
      ENV["PREVIOUS_BUNDLE_HASHES"] = ".,..,../../../etc,safe-hash"
      allow(adapter).to receive(:previous_bundle_hashes)
      allow(adapter).to receive(:fetch).with("safe-hash").and_return(bundle: src_bundle, assets: [])
    end

    it "rejects the unsafe value with a warning and stages only the safe one" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/invalid hash values \(rejected\).*etc/m).to_stderr

      expect(adapter).not_to have_received(:fetch).with("../../../etc")
      expect(adapter).not_to have_received(:fetch).with(".")
      expect(adapter).not_to have_received(:fetch).with("..")
      expect(File.exist?(File.join(cache_dir, "safe-hash", "safe-hash.js"))).to be(true)
    end
  end

  context "when adapter returns an unsafe hash" do
    let(:src_bundle) { source_file("bundle-ok.js") }

    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["..", "safe-hash"])
      allow(adapter).to receive(:fetch).with("safe-hash").and_return(bundle: src_bundle, assets: [])
    end

    it "rejects the unsafe adapter hash before any file staging" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/previous_bundle_hashes returned invalid hash values \(rejected\): \["\.\."\]/).to_stderr

      expect(adapter).not_to have_received(:fetch).with("..")
      expect(File.exist?(File.join(cache_dir, "safe-hash", "safe-hash.js"))).to be(true)
    end
  end

  context "when an asset stage fails mid-way" do
    let(:src_bundle) { source_file("bundle-partial.js") }

    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch).with("abc123").and_return(
        bundle: src_bundle,
        assets: ["/nonexistent/loadable-stats.json"]
      )
    end

    it "rolls back the entire hash directory so the renderer sees 410, not a bundle without manifests" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/returned missing asset path/).to_stderr

      bundle_dir = File.join(cache_dir, "abc123")
      expect(File.exist?(bundle_dir)).to be(false)
    end
  end

  context "when RSC support is enabled" do
    let(:src_bundle) { source_file("bundle-rsc.js") }
    let(:client_manifest) { source_file("react-client-manifest.json", contents: "{}") }
    let(:server_client_manifest) { source_file("react-server-client-manifest.json", contents: "{}") }

    before do
      allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(true)
      allow(adapter).to receive_messages(previous_bundle_hashes: ["rsc-hash"])
    end

    it "skips previous hashes that omit required RSC companion assets" do
      allow(adapter).to receive(:fetch).with("rsc-hash").and_return(bundle: src_bundle, assets: [])

      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/missing required RSC companion asset/).to_stderr

      expect(File.exist?(File.join(cache_dir, "rsc-hash"))).to be(false)
    end

    it "stages previous hashes when required RSC companion assets are present" do
      allow(adapter).to receive(:fetch).with("rsc-hash").and_return(
        bundle: src_bundle,
        assets: [client_manifest, server_client_manifest]
      )

      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy)

      bundle_dir = File.join(cache_dir, "rsc-hash")
      expect(File.exist?(File.join(bundle_dir, "rsc-hash.js"))).to be(true)
      expect(File.exist?(File.join(bundle_dir, "react-client-manifest.json"))).to be(true)
      expect(File.exist?(File.join(bundle_dir, "react-server-client-manifest.json"))).to be(true)
    end
  end

  context "when PREVIOUS_BUNDLE_HASHES contains duplicate hashes" do
    let(:src_bundle) { source_file("bundle-dup.js") }

    before do
      ENV["PREVIOUS_BUNDLE_HASHES"] = "dup-hash,dup-hash"
      allow(adapter).to receive(:previous_bundle_hashes)
      allow(adapter).to receive(:fetch).with("dup-hash").and_return(bundle: src_bundle, assets: [])
    end

    it "deduplicates before staging so a late failure can't rollback an earlier successful stage" do
      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy)

      expect(adapter).to have_received(:fetch).with("dup-hash").once
      expect(File.exist?(File.join(cache_dir, "dup-hash", "dup-hash.js"))).to be(true)
    end
  end

  context "when adapter returns payload without :bundle" do
    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["bad-hash"])
      allow(adapter).to receive(:fetch).with("bad-hash").and_return(assets: [])
    end

    it "warns and skips that hash" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/without.*valid :bundle path/m).to_stderr
    end
  end
end
