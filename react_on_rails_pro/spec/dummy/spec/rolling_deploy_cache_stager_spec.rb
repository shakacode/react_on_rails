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

  context "when symlink mode refreshes a hash from files already inside its cache directory" do
    let(:bundle_dir) { File.join(cache_dir, "abc123") }
    let(:existing_bundle) { File.join(bundle_dir, "abc123.js") }
    let(:existing_asset) { File.join(bundle_dir, "loadable-stats.json") }

    before do
      FileUtils.mkdir_p(bundle_dir)
      File.write(existing_bundle, "// existing bundle")
      File.write(existing_asset, '{"chunks":{}}')
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch)
        .with("abc123")
        .and_return(bundle: existing_bundle, assets: [existing_asset])
    end

    it "copies cache-local sources so promoted files cannot become self-referential symlinks" do
      described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :symlink)

      expect(File.symlink?(existing_bundle)).to be(false)
      expect(File.symlink?(existing_asset)).to be(false)
      expect(File.read(existing_bundle)).to eq("// existing bundle")
      expect(File.read(existing_asset)).to eq('{"chunks":{}}')
    end
  end

  context "when PREVIOUS_BUNDLE_HASHES env override is set" do
    let(:src_bundle) { source_file("bundle-xyz.js") }
    let(:src_asset) { source_file("loadable-stats.json", contents: "{}") }

    before do
      ENV["PREVIOUS_BUNDLE_HASHES"] = "xyz999"
      allow(adapter).to receive(:previous_bundle_hashes)
      allow(adapter).to receive(:fetch).with("xyz999").and_return(bundle: src_bundle, assets: [src_asset])
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

  context "when adapter#fetch returns a directory as the bundle path" do
    let(:bundle_directory) { File.join(cache_dir, "not-a-file") }

    before do
      FileUtils.mkdir_p(bundle_directory)
      allow(adapter).to receive_messages(previous_bundle_hashes: ["directory-bundle"])
      allow(adapter).to receive(:fetch)
        .with("directory-bundle")
        .and_return(bundle: bundle_directory, assets: [])
    end

    it "warns with bundle-file attribution and skips that hash" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/returned payload without a valid :bundle file path/).to_stderr
      expect(File.exist?(File.join(cache_dir, "directory-bundle"))).to be(false)
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
    let(:src_asset) { source_file("loadable-stats.json", contents: "{}") }

    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["..", "safe-hash"])
      allow(adapter).to receive(:fetch).with("safe-hash").and_return(bundle: src_bundle, assets: [src_asset])
    end

    it "rejects the unsafe adapter hash before any file staging" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/previous_bundle_hashes returned invalid hash values \(rejected\): \["\.\."\]/).to_stderr

      expect(adapter).not_to have_received(:fetch).with("..")
      expect(File.exist?(File.join(cache_dir, "safe-hash", "safe-hash.js"))).to be(true)
    end
  end

  context "when the adapter omits loadable-stats.json" do
    let(:src_bundle) { source_file("bundle-without-stats.js") }

    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["no-stats"])
      allow(adapter).to receive(:fetch).with("no-stats").and_return(bundle: src_bundle, assets: [])
    end

    it "warns but still stages the bundle for adapters that intentionally omit it" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/missing loadable-stats\.json/).to_stderr

      expect(File.exist?(File.join(cache_dir, "no-stats", "no-stats.js"))).to be(true)
    end
  end

  context "when an asset stage fails mid-way" do
    let(:src_bundle) { source_file("bundle-partial.js") }

    before do
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch).with("abc123").and_return(
        bundle: src_bundle,
        assets: ["/nonexistent/chunk.js"]
      )
    end

    it "rolls back the entire hash directory so the renderer sees 410, not a bundle without manifests" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/\A(?!.*missing loadable-stats\.json).*returned missing asset path/m).to_stderr

      bundle_dir = File.join(cache_dir, "abc123")
      expect(File.exist?(bundle_dir)).to be(false)
    end
  end

  context "when refreshing an existing seeded hash fails during staging" do
    let(:src_bundle) { source_file("bundle-refresh.js") }
    let(:src_asset) { source_file("loadable-stats.json", contents: "{}") }
    let(:bundle_dir) { File.join(cache_dir, "abc123") }
    let(:existing_bundle) { File.join(bundle_dir, "abc123.js") }

    before do
      FileUtils.mkdir_p(bundle_dir)
      File.write(existing_bundle, "// existing bundle")
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch).with("abc123").and_return(bundle: src_bundle, assets: [src_asset])
      allow(FileUtils).to receive(:cp).and_call_original
      allow(FileUtils).to receive(:cp).with(src_asset, anything).and_raise(Errno::EIO, "disk full")
    end

    it "keeps the previous valid cache entry and removes only this attempt's temp directory" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/Failed to seed previous bundle hash abc123/).to_stderr

      expect(File.read(existing_bundle)).to eq("// existing bundle")
      expect(Dir.children(cache_dir).grep(/abc123\.staging/)).to be_empty
    end
  end

  context "when refreshing an existing seeded hash cannot move the old directory to backup" do
    let(:src_bundle) { source_file("bundle-new.js", contents: "// new bundle") }
    let(:src_asset) { source_file("loadable-stats.json", contents: "{}") }
    let(:bundle_dir) { File.join(cache_dir, "abc123") }
    let(:existing_bundle) { File.join(bundle_dir, "abc123.js") }

    before do
      FileUtils.mkdir_p(bundle_dir)
      File.write(existing_bundle, "// existing bundle")
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch).with("abc123").and_return(bundle: src_bundle, assets: [src_asset])
      allow(FileUtils).to receive(:mv).and_wrap_original do |original, source, destination, *args|
        if File.basename(source) == "abc123" && destination.to_s.include?("abc123.previous-")
          raise Errno::EACCES, "permission denied"
        end

        original.call(source, destination, *args)
      end
    end

    it "keeps the previous valid cache entry in place" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/Failed to seed previous bundle hash abc123/).to_stderr

      expect(File.read(existing_bundle)).to eq("// existing bundle")
      expect(Dir.children(cache_dir).grep(/abc123\.staging/)).to be_empty
      expect(Dir.children(cache_dir).grep(/abc123\.previous/)).to be_empty
    end
  end

  context "when refreshing an existing seeded hash cannot remove the old backup after promotion" do
    let(:src_bundle) { source_file("bundle-new.js", contents: "// new bundle") }
    let(:src_asset) { source_file("loadable-stats.json", contents: "{}") }
    let(:bundle_dir) { File.join(cache_dir, "abc123") }
    let(:existing_bundle) { File.join(bundle_dir, "abc123.js") }

    before do
      FileUtils.mkdir_p(bundle_dir)
      File.write(existing_bundle, "// existing bundle")
      allow(adapter).to receive_messages(previous_bundle_hashes: ["abc123"])
      allow(adapter).to receive(:fetch).with("abc123").and_return(bundle: src_bundle, assets: [src_asset])
      allow(FileUtils).to receive(:rm_rf).and_call_original
      allow(FileUtils).to receive(:rm_rf)
        .with(a_string_matching(/abc123\.previous-/))
        .and_raise(Errno::EACCES, "permission denied")
    end

    it "keeps the promoted bundle and leaves stale backup cleanup for a later sweep" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/Could not remove stale rolling-deploy backup directory/).to_stderr

      expect(File.read(existing_bundle)).to eq("// new bundle")
      expect(Dir.children(cache_dir).grep(/abc123\.previous/)).not_to be_empty
    end
  end

  context "when stale temporary bundle directories are present" do
    let(:stale_staging_dir) { File.join(cache_dir, "abc123.staging-123-deadbeef") }
    let(:fresh_previous_dir) { File.join(cache_dir, "abc123.previous-123-feedface") }

    before do
      stub_const("ReactOnRailsPro::RollingDeployCacheStager::STALE_TEMP_DIR_TTL_SECONDS", 60)
      allow(adapter).to receive_messages(previous_bundle_hashes: [])
      FileUtils.mkdir_p(stale_staging_dir)
      FileUtils.mkdir_p(fresh_previous_dir)
      old_time = Time.now - 120
      File.utime(old_time, old_time, stale_staging_dir)
    end

    it "removes stale temp directories and keeps fresh ones" do
      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/Removed stale rolling-deploy temp directory/).to_stderr
        .and output(/No previous bundle hashes/).to_stdout

      expect(File.exist?(stale_staging_dir)).to be(false)
      expect(File.exist?(fresh_previous_dir)).to be(true)
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

    it "identifies required RSC asset paths that are present in the payload but missing on disk" do
      missing_client_manifest = File.join(cache_dir, "__sources", "react-client-manifest.json")
      FileUtils.rm_f(missing_client_manifest)
      allow(adapter).to receive(:fetch).with("rsc-hash").and_return(
        bundle: src_bundle,
        assets: [missing_client_manifest, server_client_manifest]
      )

      expect { described_class.call(cache_dir: cache_dir, current_hashes: [], mode: :copy) }
        .to output(/missing required RSC asset path/).to_stderr

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
    let(:src_asset) { source_file("loadable-stats.json", contents: "{}") }

    before do
      ENV["PREVIOUS_BUNDLE_HASHES"] = "dup-hash,dup-hash"
      allow(adapter).to receive(:previous_bundle_hashes)
      allow(adapter).to receive(:fetch).with("dup-hash").and_return(bundle: src_bundle, assets: [src_asset])
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
        .to output(/without.*valid :bundle file path/m).to_stderr
    end
  end
end
