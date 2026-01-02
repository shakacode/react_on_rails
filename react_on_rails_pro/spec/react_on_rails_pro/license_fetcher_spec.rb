# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRailsPro::LicenseFetcher do
  let(:mock_logger) { instance_double(Logger, debug: nil, warn: nil) }
  let(:api_url) { "https://licenses.example.com" }
  let(:license_key) { "lic_abc123def456ghi789" }
  let(:api_endpoint) { "#{api_url}/api/license" }

  before do
    WebMock.disable_net_connect!
    allow(Rails).to receive(:logger).and_return(mock_logger)
    ReactOnRailsPro.instance_variable_set(:@configuration, nil)
  end

  after do
    WebMock.reset!
    ReactOnRailsPro.instance_variable_set(:@configuration, nil)
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE_KEY")
  end

  describe ".fetch" do
    context "when auto_refresh is disabled" do
      before do
        ReactOnRailsPro.configure do |config|
          config.auto_refresh_license = false
        end
      end

      it "returns nil without making HTTP request" do
        result = described_class.fetch
        expect(result).to be_nil
        expect(WebMock).not_to have_requested(:get, api_endpoint)
      end
    end

    context "when auto_refresh is enabled but license_key is not set" do
      before do
        ReactOnRailsPro.configure do |config|
          config.auto_refresh_license = true
          config.license_key = nil
        end
      end

      it "returns nil without making HTTP request" do
        result = described_class.fetch
        expect(result).to be_nil
      end
    end

    context "when auto_refresh is enabled and license_key is set" do
      before do
        ReactOnRailsPro.configure do |config|
          config.auto_refresh_license = true
          config.license_api_url = api_url
          config.license_key = license_key
        end
      end

      context "when request succeeds with 200" do
        let(:response_body) do
          {
            "token" => "eyJhbGciOiJSUzI1NiJ9.test_token",
            "expires_at" => "2026-01-01T00:00:00Z"
          }
        end

        before do
          stub_request(:get, api_endpoint)
            .with(headers: { "Authorization" => "Bearer #{license_key}" })
            .to_return(status: 200, body: response_body.to_json)
        end

        it "returns parsed JSON response" do
          result = described_class.fetch
          expect(result).to eq(response_body)
        end

        it "logs debug message on success" do
          expect(mock_logger).to receive(:debug)
          described_class.fetch
        end

        it "sends correct authorization header" do
          described_class.fetch
          expect(WebMock).to have_requested(:get, api_endpoint)
            .with(headers: { "Authorization" => "Bearer #{license_key}" })
        end
      end

      context "when request returns 401 Unauthorized" do
        before do
          stub_request(:get, api_endpoint)
            .to_return(status: 401, body: '{"error": "Invalid license key"}')
        end

        it "returns nil" do
          result = described_class.fetch
          expect(result).to be_nil
        end
      end

      context "when request returns 404 Not Found" do
        before do
          stub_request(:get, api_endpoint)
            .to_return(status: 404, body: '{"error": "Not found"}')
        end

        it "returns nil" do
          result = described_class.fetch
          expect(result).to be_nil
        end
      end

      context "when request returns 500 Server Error" do
        before do
          stub_request(:get, api_endpoint)
            .to_return(status: 500, body: '{"error": "Internal server error"}')
        end

        it "returns nil" do
          result = described_class.fetch
          expect(result).to be_nil
        end
      end

      context "when request times out" do
        before do
          stub_request(:get, api_endpoint).to_timeout
        end

        it "returns nil" do
          result = described_class.fetch
          expect(result).to be_nil
        end
      end

      context "when network error occurs" do
        before do
          stub_request(:get, api_endpoint).to_raise(Errno::ECONNREFUSED)
        end

        it "returns nil" do
          result = described_class.fetch
          expect(result).to be_nil
        end
      end

      context "when response body is invalid JSON" do
        before do
          stub_request(:get, api_endpoint)
            .to_return(status: 200, body: "not valid json {{{")
        end

        it "returns nil" do
          result = described_class.fetch
          expect(result).to be_nil
        end

        it "logs warning message" do
          expect(mock_logger).to receive(:warn)
          described_class.fetch
        end
      end

      context "when license_key is set via ENV variable" do
        let(:env_license_key) { "lic_env_key_from_environment" }

        before do
          ENV["REACT_ON_RAILS_PRO_LICENSE_KEY"] = env_license_key
          stub_request(:get, api_endpoint)
            .with(headers: { "Authorization" => "Bearer #{env_license_key}" })
            .to_return(status: 200, body: '{"token": "test"}')
        end

        it "uses ENV variable over configured license_key" do
          described_class.fetch
          expect(WebMock).to have_requested(:get, api_endpoint)
            .with(headers: { "Authorization" => "Bearer #{env_license_key}" })
        end
      end
    end
  end
end
