# frozen_string_literal: true

require "jwt"
require_relative "spec_helper"

RSpec.describe ReactOnRailsPro::LicenseValidator do
  let(:test_private_key) do
    OpenSSL::PKey::RSA.new(2048)
  end

  let(:test_public_key) do
    test_private_key.public_key
  end

  let(:valid_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i,
      exp: Time.now.to_i + 3600 # Valid for 1 hour
    }
  end

  let(:expired_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i - 7200,
      exp: Time.now.to_i - 3600 # Expired 1 hour ago
    }
  end

  let(:mock_logger) { instance_double(Logger, error: nil, info: nil) }
  let(:mock_root) { instance_double(Pathname, join: config_file_path) }
  let(:config_file_path) { instance_double(Pathname, exist?: false) }

  before do
    described_class.reset!
    # Stub the public key constant to use our test key
    stub_const("ReactOnRailsPro::LicensePublicKey::KEY", test_public_key)
    # Clear ENV variable
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")

    # Stub Rails.logger to avoid nil errors in unit tests
    # Stub Rails.root for config file path tests
    allow(Rails).to receive_messages(logger: mock_logger, root: mock_root)
  end

  after do
    described_class.reset!
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
  end

  describe ".validated_license_data!" do
    context "with valid license in ENV" do
      before do
        valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
      end

      it "returns license data hash" do
        data = described_class.validated_license_data!
        expect(data).to be_a(Hash)
        expect(data["exp"]).to be_a(Integer)
      end

      it "caches the result" do
        expect(described_class).to receive(:load_and_decode_license).once.and_call_original
        described_class.validated_license_data!
        described_class.validated_license_data! # Second call should use cache
      end
    end

    context "with expired license" do
      before do
        expired_token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = expired_token
      end

      context "when in development/test environment" do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        end

        it "raises error immediately" do
          expect do
            described_class.validated_license_data!
          end.to raise_error(ReactOnRailsPro::Error, /License has expired/)
        end

        it "includes FREE license information in error message" do
          expect do
            described_class.validated_license_data!
          end.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
        end
      end

      context "when in production environment" do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        end

        context "with grace period (expired < 1 month ago)" do
          let(:expired_within_grace) do
            {
              sub: "test@example.com",
              iat: Time.now.to_i - (15 * 24 * 60 * 60), # Issued 15 days ago
              exp: Time.now.to_i - (10 * 24 * 60 * 60)  # Expired 10 days ago (within 1 month grace)
            }
          end

          before do
            token = JWT.encode(expired_within_grace, test_private_key, "RS256")
            ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
          end

          it "does not raise error" do
            expect { described_class.validated_license_data! }.not_to raise_error
          end

          it "logs warning with grace period remaining" do
            expect(mock_logger).to receive(:error)
              .with(/WARNING:.*License has expired.*Grace period:.*day\(s\) remaining/)
            described_class.validated_license_data!
          end

          it "returns license data" do
            data = described_class.validated_license_data!
            expect(data).to be_a(Hash)
          end
        end

        context "when outside grace period (expired > 1 month ago)" do
          let(:expired_outside_grace) do
            {
              sub: "test@example.com",
              iat: Time.now.to_i - (60 * 24 * 60 * 60), # Issued 60 days ago
              exp: Time.now.to_i - (35 * 24 * 60 * 60)  # Expired 35 days ago (outside 1 month grace)
            }
          end

          before do
            token = JWT.encode(expired_outside_grace, test_private_key, "RS256")
            ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
          end

          it "raises error" do
            expect do
              described_class.validated_license_data!
            end.to raise_error(ReactOnRailsPro::Error, /License has expired/)
          end

          it "includes FREE license information in error message" do
            expect do
              described_class.validated_license_data!
            end.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
          end
        end
      end
    end

    context "with license missing exp field" do
      let(:payload_without_exp) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i
          # exp field is missing
        }
      end

      before do
        token_without_exp = JWT.encode(payload_without_exp, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token_without_exp
      end

      it "raises error" do
        expect { described_class.validated_license_data! }
          .to raise_error(ReactOnRailsPro::Error, /License is missing required expiration field/)
      end

      it "includes FREE license information in error message" do
        expect do
          described_class.validated_license_data!
        end.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
      end
    end

    context "with invalid signature" do
      before do
        wrong_key = OpenSSL::PKey::RSA.new(2048)
        invalid_token = JWT.encode(valid_payload, wrong_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = invalid_token
      end

      it "raises error" do
        expect do
          described_class.validated_license_data!
        end.to raise_error(ReactOnRailsPro::Error, /Invalid license signature/)
      end

      it "includes FREE license information in error message" do
        expect do
          described_class.validated_license_data!
        end.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
      end
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
        # config_file_path is already set to exist?: false in the let block
      end

      it "raises error" do
        expect { described_class.validated_license_data! }.to raise_error(ReactOnRailsPro::Error, /No license found/)
      end

      it "includes FREE license information in error message" do
        expect { described_class.validated_license_data! }
          .to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
      end
    end

    context "with license in config file" do
      let(:valid_token) { JWT.encode(valid_payload, test_private_key, "RS256") }
      let(:file_config_path) { instance_double(Pathname, exist?: true) }

      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
        allow(mock_root).to receive(:join)
          .with("config", "react_on_rails_pro_license.key")
          .and_return(file_config_path)
        allow(File).to receive(:read).with(file_config_path).and_return(valid_token)
      end

      it "returns license data" do
        data = described_class.validated_license_data!
        expect(data).to be_a(Hash)
      end
    end
  end

  # Removed .license_data and .validation_error as they're no longer part of the public API
  # Use validated_license_data! instead

  describe ".reset!" do
    before do
      valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
      described_class.validated_license_data! # Cache the result
    end

    it "clears the cached validation result" do
      expect(described_class.instance_variable_get(:@license_data)).not_to be_nil
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@license_data)).to be false
    end
  end

  describe "license auto-refresh" do
    let(:valid_token) { JWT.encode(valid_payload, test_private_key, "RS256") }

    before do
      ReactOnRailsPro.instance_variable_set(:@configuration, nil)
      ENV.delete("REACT_ON_RAILS_PRO_LICENSE_KEY")
    end

    after do
      ReactOnRailsPro.instance_variable_set(:@configuration, nil)
      ENV.delete("REACT_ON_RAILS_PRO_LICENSE_KEY")
    end

    describe "token source priority" do
      context "when auto-refresh is enabled and cache has token" do
        before do
          ReactOnRailsPro.configure do |config|
            config.auto_refresh_license = true
            config.license_key = "lic_test_key"
          end
          allow(ReactOnRailsPro::LicenseCache).to receive_messages(token: valid_token, expires_at: nil)
        end

        it "uses cached token" do
          data = described_class.validated_license_data!
          expect(data).to be_a(Hash)
          expect(ReactOnRailsPro::LicenseCache).to have_received(:token)
        end
      end

      context "when auto-refresh is disabled" do
        before do
          ReactOnRailsPro.configure do |config|
            config.auto_refresh_license = false
          end
          ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
        end

        it "does not check cache and uses ENV" do
          expect(ReactOnRailsPro::LicenseCache).not_to receive(:token)
          data = described_class.validated_license_data!
          expect(data).to be_a(Hash)
        end
      end

      context "when auto-refresh is enabled but cache is empty" do
        before do
          ReactOnRailsPro.configure do |config|
            config.auto_refresh_license = true
            config.license_key = "lic_test_key"
          end
          allow(ReactOnRailsPro::LicenseCache).to receive_messages(token: nil, expires_at: nil)
          ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
        end

        it "falls back to ENV" do
          data = described_class.validated_license_data!
          expect(data).to be_a(Hash)
        end
      end
    end

    describe ".should_check_for_refresh?" do
      before do
        ReactOnRailsPro.configure do |config|
          config.auto_refresh_license = true
          config.license_key = "lic_test_key"
        end
      end

      context "when expires_at is nil (no cache)" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive(:expires_at).and_return(nil)
        end

        it "returns false" do
          result = described_class.send(:should_check_for_refresh?)
          expect(result).to be false
        end
      end

      context "when more than 30 days until expiry" do
        before do
          # Use 60 days to avoid timing race between test setup and execution.
          # With 31 days, the time elapsed between Time.now in stub creation and
          # Time.now in should_check_for_refresh? causes .to_i truncation from 31 to 30,
          # incorrectly triggering the weekly check branch.
          allow(ReactOnRailsPro::LicenseCache).to receive(:expires_at)
            .and_return(Time.now + (60 * 24 * 60 * 60))
        end

        it "returns false" do
          result = described_class.send(:should_check_for_refresh?)
          expect(result).to be false
        end
      end

      context "when exactly 30 days until expiry (boundary - weekly check)" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive(:expires_at)
            .and_return(Time.now + (30 * 24 * 60 * 60))
        end

        context "when last fetch was more than 7 days ago" do
          before do
            allow(ReactOnRailsPro::LicenseCache).to receive(:fetched_at)
              .and_return(Time.now - (8 * 24 * 60 * 60))
          end

          it "returns true" do
            result = described_class.send(:should_check_for_refresh?)
            expect(result).to be true
          end
        end

        context "when last fetch was less than 7 days ago" do
          before do
            allow(ReactOnRailsPro::LicenseCache).to receive(:fetched_at)
              .and_return(Time.now - (6 * 24 * 60 * 60))
          end

          it "returns false" do
            result = described_class.send(:should_check_for_refresh?)
            expect(result).to be false
          end
        end
      end

      context "when exactly 8 days until expiry (boundary - still weekly check)" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive(:expires_at)
            .and_return(Time.now + (8 * 24 * 60 * 60))
        end

        context "when last fetch was more than 7 days ago" do
          before do
            allow(ReactOnRailsPro::LicenseCache).to receive(:fetched_at)
              .and_return(Time.now - (8 * 24 * 60 * 60))
          end

          it "returns true" do
            result = described_class.send(:should_check_for_refresh?)
            expect(result).to be true
          end
        end
      end

      context "when exactly 7 days until expiry (boundary - daily check)" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive(:expires_at)
            .and_return(Time.now + (7 * 24 * 60 * 60))
        end

        context "when last fetch was more than 1 day ago" do
          before do
            allow(ReactOnRailsPro::LicenseCache).to receive(:fetched_at)
              .and_return(Time.now - (2 * 24 * 60 * 60))
          end

          it "returns true" do
            result = described_class.send(:should_check_for_refresh?)
            expect(result).to be true
          end
        end

        context "when last fetch was less than 1 day ago" do
          before do
            allow(ReactOnRailsPro::LicenseCache).to receive(:fetched_at)
              .and_return(Time.now - (12 * 60 * 60)) # 12 hours ago
          end

          it "returns false" do
            result = described_class.send(:should_check_for_refresh?)
            expect(result).to be false
          end
        end
      end

      context "when 3 days until expiry (daily check)" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive(:expires_at)
            .and_return(Time.now + (3 * 24 * 60 * 60))
        end

        context "when last fetch was more than 1 day ago" do
          before do
            allow(ReactOnRailsPro::LicenseCache).to receive(:fetched_at)
              .and_return(Time.now - (2 * 24 * 60 * 60))
          end

          it "returns true" do
            result = described_class.send(:should_check_for_refresh?)
            expect(result).to be true
          end
        end
      end

      context "when fetched_at is nil (never fetched)" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive_messages(expires_at: Time.now + (5 * 24 * 60 * 60),
                                                                   fetched_at: nil)
        end

        it "returns true (triggers fetch)" do
          result = described_class.send(:should_check_for_refresh?)
          expect(result).to be true
        end
      end
    end

    describe ".maybe_refresh_license" do
      before do
        ReactOnRailsPro.configure do |config|
          config.auto_refresh_license = true
          config.license_key = "lic_test_key"
        end
      end

      context "when auto_refresh is disabled" do
        before do
          ReactOnRailsPro.configure do |config|
            config.auto_refresh_license = false
          end
        end

        it "does not call fetcher" do
          expect(ReactOnRailsPro::LicenseFetcher).not_to receive(:fetch)
          described_class.send(:maybe_refresh_license)
        end
      end

      context "when should_check_for_refresh? returns false" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive(:expires_at).and_return(nil)
        end

        it "does not call fetcher" do
          expect(ReactOnRailsPro::LicenseFetcher).not_to receive(:fetch)
          described_class.send(:maybe_refresh_license)
        end
      end

      context "when should_check_for_refresh? returns true" do
        before do
          allow(ReactOnRailsPro::LicenseCache).to receive_messages(expires_at: Time.now + (5 * 24 * 60 * 60),
                                                                   fetched_at: Time.now - (2 * 24 * 60 * 60))
        end

        context "when fetch succeeds" do
          let(:fetch_response) do
            { "token" => "new_token", "expires_at" => "2026-01-01T00:00:00Z" }
          end

          before do
            allow(ReactOnRailsPro::LicenseFetcher).to receive(:fetch).and_return(fetch_response)
            allow(ReactOnRailsPro::LicenseCache).to receive(:write)
          end

          it "writes response to cache" do
            described_class.send(:maybe_refresh_license)
            expect(ReactOnRailsPro::LicenseCache).to have_received(:write).with(fetch_response)
          end
        end

        context "when fetch returns nil (failure)" do
          before do
            allow(ReactOnRailsPro::LicenseFetcher).to receive(:fetch).and_return(nil)
          end

          it "does not write to cache" do
            expect(ReactOnRailsPro::LicenseCache).not_to receive(:write)
            described_class.send(:maybe_refresh_license)
          end
        end
      end
    end
  end
end
