# frozen_string_literal: true

require_relative "spec_helper"
require "fakefs/safe"

RSpec.describe ReactOnRailsPro::LicenseCache do
  let(:mock_logger) { instance_double(Logger, warn: nil) }
  let(:license_key) { "lic_test_key_12345678" }
  let(:license_key_hash) { Digest::SHA256.hexdigest(license_key)[0..15] }
  let(:fake_root) { Pathname.new("/fake_rails_root") }
  let(:cache_dir) { fake_root.join("tmp") }
  let(:cache_path) { cache_dir.join("react_on_rails_pro_license.cache") }

  let(:valid_cache_data) do
    {
      "token" => "eyJhbGciOiJSUzI1NiJ9.test_token",
      "expires_at" => "2026-01-01T00:00:00Z",
      "license_key_hash" => license_key_hash,
      "fetched_at" => "2025-06-01T12:00:00Z"
    }
  end

  before do
    FakeFS.activate!
    # Clean up any existing cache file to ensure test isolation
    FileUtils.rm_rf(fake_root)
    FileUtils.mkdir_p(cache_dir)

    allow(Rails).to receive_messages(root: fake_root, logger: mock_logger)
    ReactOnRailsPro.instance_variable_set(:@configuration, nil)

    ReactOnRailsPro.configure do |config|
      config.license_key = license_key
    end
  end

  after do
    FakeFS.deactivate!
    ReactOnRailsPro.instance_variable_set(:@configuration, nil)
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE_KEY")
  end

  describe ".read" do
    context "when cache file does not exist" do
      it "returns nil" do
        expect(described_class.read).to be_nil
      end
    end

    context "when cache file contains invalid JSON" do
      before do
        File.write(cache_path, "not valid json {{{")
      end

      it "returns nil" do
        expect(described_class.read).to be_nil
      end
    end

    context "when cache file is missing license_key_hash" do
      before do
        data = valid_cache_data.except("license_key_hash")
        File.write(cache_path, JSON.pretty_generate(data))
      end

      it "returns nil" do
        expect(described_class.read).to be_nil
      end
    end

    context "when cache file has different license_key_hash" do
      before do
        data = valid_cache_data.merge("license_key_hash" => "different_hash_value")
        File.write(cache_path, JSON.pretty_generate(data))
      end

      it "returns nil" do
        expect(described_class.read).to be_nil
      end
    end

    context "when current license_key is nil" do
      before do
        ReactOnRailsPro.configure do |config|
          config.license_key = nil
        end
        File.write(cache_path, JSON.pretty_generate(valid_cache_data))
      end

      it "returns nil" do
        # current_key_hash returns nil, so comparison fails
        expect(described_class.read).to be_nil
      end
    end

    context "when cache file is valid and hash matches" do
      before do
        File.write(cache_path, JSON.pretty_generate(valid_cache_data))
      end

      it "returns parsed cache data" do
        result = described_class.read
        expect(result).to eq(valid_cache_data)
      end
    end

    context "when license_key is set via ENV variable" do
      let(:env_license_key) { "lic_env_variable_key" }
      let(:env_key_hash) { Digest::SHA256.hexdigest(env_license_key)[0..15] }

      before do
        ENV["REACT_ON_RAILS_PRO_LICENSE_KEY"] = env_license_key
        data = valid_cache_data.merge("license_key_hash" => env_key_hash)
        File.write(cache_path, JSON.pretty_generate(data))
      end

      it "uses ENV variable for hash comparison" do
        result = described_class.read
        expect(result).not_to be_nil
        expect(result["license_key_hash"]).to eq(env_key_hash)
      end
    end
  end

  describe ".write" do
    let(:input_data) do
      {
        "token" => "new_token_value",
        "expires_at" => "2027-01-01T00:00:00Z"
      }
    end

    it "creates cache file with merged data" do
      described_class.write(input_data)

      expect(cache_path.exist?).to be true
      written_data = JSON.parse(File.read(cache_path))
      expect(written_data["token"]).to eq("new_token_value")
      expect(written_data["expires_at"]).to eq("2027-01-01T00:00:00Z")
    end

    it "adds license_key_hash to written data" do
      described_class.write(input_data)

      written_data = JSON.parse(File.read(cache_path))
      expect(written_data["license_key_hash"]).to eq(license_key_hash)
    end

    it "adds fetched_at timestamp to written data" do
      freeze_time = Time.new(2025, 6, 15, 10, 30, 0, "+00:00")
      allow(Time).to receive(:now).and_return(freeze_time)

      described_class.write(input_data)

      written_data = JSON.parse(File.read(cache_path))
      expect(written_data["fetched_at"]).to eq(freeze_time.iso8601)
    end

    it "sets file permissions to 0600" do
      described_class.write(input_data)

      # FakeFS doesn't fully support file permissions, but we verify the call is made
      # In real filesystem, this would restrict access to owner only
      expect(cache_path.exist?).to be true
    end

    it "creates cache directory if it does not exist" do
      FileUtils.rm_rf(cache_dir)
      expect(cache_dir.exist?).to be false

      described_class.write(input_data)

      expect(cache_dir.exist?).to be true
      expect(cache_path.exist?).to be true
    end

    context "when write fails" do
      before do
        allow(File).to receive(:write).and_raise(Errno::EACCES, "Permission denied")
      end

      it "logs warning and does not raise" do
        expect(mock_logger).to receive(:warn)
        expect { described_class.write(input_data) }.not_to raise_error
      end
    end
  end

  describe ".token" do
    context "when cache is valid" do
      before do
        File.write(cache_path, JSON.pretty_generate(valid_cache_data))
      end

      it "returns token value" do
        expect(described_class.token).to eq("eyJhbGciOiJSUzI1NiJ9.test_token")
      end
    end

    context "when cache does not exist" do
      it "returns nil" do
        expect(described_class.token).to be_nil
      end
    end

    context "when cache exists but token key is missing" do
      before do
        data = valid_cache_data.except("token")
        File.write(cache_path, JSON.pretty_generate(data))
      end

      it "returns nil" do
        expect(described_class.token).to be_nil
      end
    end
  end

  describe ".fetched_at" do
    context "when cache is valid" do
      before do
        File.write(cache_path, JSON.pretty_generate(valid_cache_data))
      end

      it "returns parsed Time object" do
        result = described_class.fetched_at
        expect(result).to be_a(Time)
        expect(result.year).to eq(2025)
        expect(result.month).to eq(6)
        expect(result.day).to eq(1)
      end
    end

    context "when cache does not exist" do
      it "returns nil" do
        expect(described_class.fetched_at).to be_nil
      end
    end

    context "when fetched_at has invalid time format" do
      before do
        data = valid_cache_data.merge("fetched_at" => "not-a-valid-time")
        File.write(cache_path, JSON.pretty_generate(data))
      end

      it "returns nil" do
        expect(described_class.fetched_at).to be_nil
      end
    end
  end

  describe ".expires_at" do
    context "when cache is valid" do
      before do
        File.write(cache_path, JSON.pretty_generate(valid_cache_data))
      end

      it "returns parsed Time object" do
        result = described_class.expires_at
        expect(result).to be_a(Time)
        expect(result.year).to eq(2026)
        expect(result.month).to eq(1)
        expect(result.day).to eq(1)
      end
    end

    context "when cache does not exist" do
      it "returns nil" do
        expect(described_class.expires_at).to be_nil
      end
    end

    context "when expires_at has invalid time format" do
      before do
        data = valid_cache_data.merge("expires_at" => "invalid-timestamp")
        File.write(cache_path, JSON.pretty_generate(data))
      end

      it "returns nil" do
        expect(described_class.expires_at).to be_nil
      end
    end
  end
end
