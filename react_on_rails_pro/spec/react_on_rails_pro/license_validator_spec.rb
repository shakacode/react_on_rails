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

  let(:mock_root) { instance_double(Pathname, join: config_file_path) }
  let(:config_file_path) { instance_double(Pathname, exist?: false) }

  before do
    @original_license = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", nil)
    described_class.reset!
    stub_const("ReactOnRailsPro::LicensePublicKey::KEY", test_public_key)
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
    allow(Rails).to receive(:root).and_return(mock_root)
  end

  after do
    described_class.reset!
    if @original_license
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = @original_license
    else
      ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
    end
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
    end

    context "with non-numeric exp field" do
      let(:payload_with_string_exp) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: "not-a-number",
          plan: "paid"
        }
      end

      before do
        token = JWT.encode(payload_with_string_exp, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
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
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
      end

      it "returns :missing" do
        expect(described_class.license_status).to eq(:missing)
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
    end
  end

  describe ".license_status with plan field" do
    context "when plan is 'paid'" do
      let(:paid_payload) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "paid"
        }
      end

      before do
        token = JWT.encode(paid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :valid" do
        expect(described_class.license_status).to eq(:valid)
      end
    end

    context "when plan is 'free'" do
      let(:free_payload) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "free"
        }
      end

      before do
        token = JWT.encode(free_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
      end
    end

    context "when plan is 'unknown'" do
      let(:unknown_plan_payload) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "unknown"
        }
      end

      before do
        token = JWT.encode(unknown_plan_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
      end
    end

    context "when plan field is absent" do
      let(:no_plan_payload) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600
        }
      end

      before do
        token = JWT.encode(no_plan_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :valid (backwards compatibility)" do
        expect(described_class.license_status).to eq(:valid)
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

  describe "thread safety" do
    it "handles concurrent access without errors" do
      valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token

      threads = Array.new(10) do
        Thread.new do
          described_class.reset!
          described_class.license_status
        end
      end

      results = threads.map(&:value)
      expect(results).to all(eq(:valid))
    end
  end
end
