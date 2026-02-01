# frozen_string_literal: true

require "jwt"
require_relative "spec_helper"

RSpec.describe ReactOnRailsPro::Engine do
  let(:test_private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:test_public_key) { test_private_key.public_key }
  let(:mock_logger) { instance_double(Logger, warn: nil, info: nil) }
  let(:mock_root) { instance_double(Pathname, join: config_file_path) }
  let(:config_file_path) { instance_double(Pathname, exist?: false) }

  let(:valid_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i,
      exp: Time.now.to_i + 3600,
      plan: "paid"
    }
  end

  before do
    ReactOnRailsPro::LicenseValidator.reset!
    stub_const("ReactOnRailsPro::LicensePublicKey::KEY", test_public_key)
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
    allow(Rails).to receive_messages(logger: mock_logger, root: mock_root)
  end

  after do
    ReactOnRailsPro::LicenseValidator.reset!
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
  end

  describe ".log_license_status" do
    context "with missing license" do
      it "logs a warning" do
        expect(mock_logger).to receive(:warn).with(/No license found/)
        described_class.log_license_status
      end

      it "includes the license URL" do
        expect(mock_logger).to receive(:warn).with(%r{shakacode\.com/react-on-rails-pro})
        described_class.log_license_status
      end
    end

    context "with expired license" do
      before do
        expired_payload = valid_payload.merge(exp: Time.now.to_i - 3600)
        token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "logs a warning" do
        expect(mock_logger).to receive(:warn).with(/License has expired/)
        described_class.log_license_status
      end
    end

    context "with invalid license" do
      before do
        wrong_key = OpenSSL::PKey::RSA.new(2048)
        token = JWT.encode(valid_payload, wrong_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "logs a warning" do
        expect(mock_logger).to receive(:warn).with(/Invalid license/)
        described_class.log_license_status
      end
    end

    context "with valid license" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "logs success info" do
        expect(mock_logger).to receive(:info).with(/License validated successfully/)
        described_class.log_license_status
      end

      it "does not log a warning" do
        expect(mock_logger).not_to receive(:warn)
        described_class.log_license_status
      end
    end
  end
end
