# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require "react_on_rails_pro/rolling_deploy_adapters/http"

describe ReactOnRailsPro::RollingDeployAdapters::Http do
  describe ".extract_payload" do
    it "returns every companion asset extracted from the tarball" do
      Dir.mktmpdir("ror-pro-http-source") do |source_dir|
        Dir.mktmpdir("ror-pro-http-fetch") do |fetch_dir|
          bundle = File.join(source_dir, "server.js")
          loadable_stats = File.join(source_dir, "loadable-stats.json")
          custom_asset = File.join(source_dir, "custom-copy.json")

          File.write(bundle, "bundle")
          File.write(loadable_stats, "{}")
          File.write(custom_asset, "{}")

          tarball_body = compose_tarball(
            "bundle.js" => bundle,
            "custom-copy.json" => custom_asset,
            "loadable-stats.json" => loadable_stats
          )

          result = described_class.send(:extract_payload, tarball_body, fetch_dir, "hash123")

          expect(result[:bundle]).to eq(File.join(fetch_dir, "bundle.js"))
          expect(File.read(result[:bundle])).to eq("bundle")
          expect(result[:assets].map { |path| File.basename(path) }).to contain_exactly(
            "custom-copy.json",
            "loadable-stats.json"
          )
        end
      end
    end
  end

  describe ".http_get" do
    let(:config) do
      instance_double(
        ReactOnRailsPro::Configuration,
        rolling_deploy_previous_url: "https://example.com",
        rolling_deploy_token: "token"
      )
    end
    let(:http) { instance_double(Net::HTTP) }
    let(:response) { Net::HTTPOK.new("1.1", "200", "OK") }

    before do
      allow(ReactOnRailsPro).to receive(:configuration).and_return(config)
      allow(Net::HTTP).to receive(:new).with("example.com", 443).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:verify_mode=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive_messages(use_ssl?: true, request: response)
      allow(response).to receive(:body).and_return({ hashes: [] }.to_json)
    end

    it "enforces TLS peer verification for HTTPS requests" do
      described_class.send(:http_get, URI("https://example.com/manifest"))

      expect(http).to have_received(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
    end

    it "uses a discovery read timeout that fits inside the cache stager budget" do
      described_class.previous_bundle_hashes

      expect(http)
        .to have_received(:read_timeout=)
        .with(described_class::MANIFEST_READ_TIMEOUT_SECONDS)
    end
  end

  describe "token-not-configured short-circuit" do
    let(:config) do
      instance_double(
        ReactOnRailsPro::Configuration,
        rolling_deploy_previous_url: "https://example.com",
        rolling_deploy_token: ""
      )
    end

    before do
      allow(ReactOnRailsPro).to receive(:configuration).and_return(config)
      allow(Rails).to receive(:logger).and_return(instance_double(Logger, warn: nil))
    end

    it "returns an empty list and warns when previous_bundle_hashes runs without a token" do
      expect(Net::HTTP).not_to receive(:new)

      expect(described_class.previous_bundle_hashes).to eq([])
      expect(Rails.logger).to have_received(:warn).with(/rolling_deploy_token is not configured/)
    end

    it "returns nil and warns when fetch runs without a token" do
      expect(Net::HTTP).not_to receive(:new)

      expect(described_class.fetch("hash123")).to be_nil
      expect(Rails.logger).to have_received(:warn).with(/rolling_deploy_token is not configured/)
    end
  end

  def compose_tarball(entries)
    body = nil
    ReactOnRailsPro::RollingDeploy::Tarball.compose_to_tempfile(entries) { |io| body = io.read }
    body
  end
end
