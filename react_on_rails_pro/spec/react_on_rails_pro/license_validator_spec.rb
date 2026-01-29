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
      exp: Time.now.to_i + 3600, # Valid for 1 hour
      plan: "paid"
    }
  end

  let(:expired_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i - 7200,
      exp: Time.now.to_i - 3600 # Expired 1 hour ago
    }
  end

  let(:mock_logger) { instance_double(Logger, warn: nil, info: nil) }
  let(:mock_root) { instance_double(Pathname, join: config_file_path) }
  let(:config_file_path) { instance_double(Pathname, exist?: false) }

  before do
    described_class.reset!
    stub_const("ReactOnRailsPro::LicensePublicKey::KEY", test_public_key)
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
    allow(Rails).to receive_messages(logger: mock_logger, root: mock_root)
  end

  after do
    described_class.reset!
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
  end

  describe ".license_status" do
    context "with valid license in ENV" do
      before do
        valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
      end

      it "returns :valid" do
        expect(described_class.license_status).to eq(:valid)
      end

      it "caches the result" do
        described_class.license_status
        expect(described_class).not_to receive(:determine_license_status)
        described_class.license_status
      end
    end

    context "with expired license" do
      before do
        expired_token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = expired_token
      end

      it "returns :expired" do
        expect(described_class.license_status).to eq(:expired)
      end

      it "logs a warning" do
        expect(mock_logger).to receive(:warn).with(/License expired.*day\(s\) ago/)
        described_class.license_status
      end
    end

    context "with license missing exp field" do
      let(:payload_without_exp) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i
        }
      end

      before do
        token_without_exp = JWT.encode(payload_without_exp, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token_without_exp
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
      end

      it "logs a warning about missing expiration" do
        expect(mock_logger).to receive(:warn).with(/missing expiration field/)
        described_class.license_status
      end
    end

    context "with invalid signature" do
      before do
        wrong_key = OpenSSL::PKey::RSA.new(2048)
        invalid_token = JWT.encode(valid_payload, wrong_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = invalid_token
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
      end

      it "logs a warning about invalid signature" do
        expect(mock_logger).to receive(:warn).with(/Invalid license signature/)
        described_class.license_status
      end
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
      end

      it "returns :missing" do
        expect(described_class.license_status).to eq(:missing)
      end

      it "logs a warning about missing license" do
        expect(mock_logger).to receive(:warn).with(/No license found/)
        described_class.license_status
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

      it "returns :valid" do
        expect(described_class.license_status).to eq(:valid)
      end
    end

    context "when license file exists but cannot be read" do
      let(:file_config_path) { instance_double(Pathname, exist?: true) }

      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
        allow(mock_root).to receive(:join)
          .with("config", "react_on_rails_pro_license.key")
          .and_return(file_config_path)
        allow(File).to receive(:read).with(file_config_path).and_raise(Errno::EACCES, "Permission denied")
      end

      it "returns :missing" do
        expect(described_class.license_status).to eq(:missing)
      end

      it "logs a warning about the file read error" do
        expect(mock_logger).to receive(:warn).with(/Failed to read license file/)
        described_class.license_status
      end
    end
  end

  describe ".reset!" do
    before do
      valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
      described_class.license_status # Cache the result
    end

    it "clears the cached license status" do
      expect(described_class.instance_variable_defined?(:@license_status)).to be true
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@license_status)).to be false
    end
  end
end
