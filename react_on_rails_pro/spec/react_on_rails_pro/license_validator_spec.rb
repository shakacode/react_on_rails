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

  before do
    described_class.reset!
    # Stub the public key constant to use our test key
    stub_const("ReactOnRailsPro::LicensePublicKey::KEY", test_public_key)
    # Clear ENV variable
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
  end

  after do
    described_class.reset!
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
  end

  describe ".valid?" do
    context "with valid license in ENV" do
      before do
        valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
      end

      it "returns true" do
        expect(described_class.valid?).to be true
      end

      it "caches the result" do
        expect(described_class).to receive(:validate_license).once.and_call_original
        described_class.valid?
        described_class.valid? # Second call should use cache
      end
    end

    context "with expired license" do
      before do
        expired_token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = expired_token
      end

      it "raises error" do
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /License has expired/)
      end

      it "includes FREE license information in error message" do
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
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
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /License is missing required expiration field/)
      end

      it "includes FREE license information in error message" do
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
      end
    end

    context "with invalid signature" do
      before do
        wrong_key = OpenSSL::PKey::RSA.new(2048)
        invalid_token = JWT.encode(valid_payload, wrong_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = invalid_token
      end

      it "raises error" do
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /Invalid license signature/)
      end

      it "includes FREE license information in error message" do
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
      end
    end

    context "with missing license" do
      let(:config_path) { double("Pathname", exist?: false) }

      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
        allow(Rails.root).to receive(:join).with("config", "react_on_rails_pro_license.key").and_return(config_path)
      end

      it "raises error" do
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /No license found/)
      end

      it "includes FREE license information in error message" do
        expect { described_class.valid? }.to raise_error(ReactOnRailsPro::Error, /FREE evaluation license/)
      end
    end

    context "with license in config file" do
      let(:config_path) { Rails.root.join("config", "react_on_rails_pro_license.key") }
      let(:valid_token) { JWT.encode(valid_payload, test_private_key, "RS256") }

      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
        allow(config_path).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with(config_path).and_return(valid_token)
      end

      it "returns true" do
        expect(described_class.valid?).to be true
      end
    end
  end

  describe ".license_data" do
    before do
      valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
    end

    it "returns the decoded license data" do
      data = described_class.license_data
      expect(data["sub"]).to eq("test@example.com")
      expect(data["iat"]).to be_a(Integer)
      expect(data["exp"]).to be_a(Integer)
    end
  end

  describe ".validation_error" do
    context "with expired license" do
      before do
        expired_token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = expired_token
      end

      it "returns the error message" do
        begin
          described_class.valid?
        rescue ReactOnRailsPro::Error
          # Expected error
        end
        expect(described_class.validation_error).to include("License has expired")
      end
    end
  end

  describe ".reset!" do
    before do
      valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
      described_class.valid? # Cache the result
    end

    it "clears the cached validation result" do
      expect(described_class.instance_variable_get(:@valid)).to be true
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@valid)).to be false
    end
  end
end
