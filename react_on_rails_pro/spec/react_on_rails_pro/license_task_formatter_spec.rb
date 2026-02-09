# frozen_string_literal: true

require "jwt"
require_relative "spec_helper"
require "react_on_rails_pro/license_task_formatter"

RSpec.describe ReactOnRailsPro::LicenseTaskFormatter do
  let(:test_private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:test_public_key) { test_private_key.public_key }
  let(:mock_root) { instance_double(Pathname, join: config_file_path) }
  let(:config_file_path) { instance_double(Pathname, exist?: false) }

  let(:valid_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i,
      exp: Time.now.to_i + (90 * 86_400), # 90 days from now
      plan: "paid",
      org: "Acme Corp"
    }
  end

  let(:expiring_soon_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i,
      exp: Time.now.to_i + (15 * 86_400), # 15 days from now
      plan: "paid",
      org: "Acme Corp"
    }
  end

  let(:expired_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i - (180 * 86_400),
      exp: Time.now.to_i - (10 * 86_400), # Expired 10 days ago
      plan: "paid",
      org: "Acme Corp"
    }
  end

  before do
    ReactOnRailsPro::LicenseValidator.reset!
    stub_const("ReactOnRailsPro::LicensePublicKey::KEY", test_public_key)
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
    allow(Rails).to receive(:root).and_return(mock_root)
  end

  after do
    ReactOnRailsPro::LicenseValidator.reset!
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
  end

  describe ".build_result" do
    context "with a valid license" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns valid status with license details" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        expect(result[:status]).to eq("valid")
        expect(result[:organization]).to eq("Acme Corp")
        expect(result[:plan]).to eq("paid")
        expect(result[:expiration]).to be_a(String)
        expect(result[:days_remaining]).to be_positive
        expect(result[:renewal_required]).to be false
        expect(result[:attribution_required]).to be false
      end
    end

    context "with an expired license" do
      before do
        token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns expired status with renewal_required true" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        expect(result[:status]).to eq("expired")
        expect(result[:renewal_required]).to be true
        expect(result[:days_remaining]).to be_negative
      end
    end

    context "with a missing license" do
      it "returns missing status" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        expect(result[:status]).to eq("missing")
        expect(result[:days_remaining]).to be_nil
        expect(result[:renewal_required]).to be false
      end
    end

    context "with a license expiring within 30 days" do
      before do
        token = JWT.encode(expiring_soon_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "sets renewal_required to true" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        expect(result[:status]).to eq("valid")
        expect(result[:renewal_required]).to be true
        expect(result[:days_remaining]).to be <= 30
      end
    end
  end

  describe ".print_text" do
    context "with a valid license" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "prints license details" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        output = capture_stdout { described_class.print_text(result, info) }
        expect(output).to include("VALID")
        expect(output).to include("Acme Corp")
        expect(output).to include("paid")
        expect(output).to include("not required")
      end
    end

    context "with a missing license" do
      it "prints missing status with setup instructions" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        output = capture_stdout { described_class.print_text(result, info) }
        expect(output).to include("MISSING")
        expect(output).to include("REACT_ON_RAILS_PRO_LICENSE")
      end
    end

    context "with an expiring license" do
      before do
        token = JWT.encode(expiring_soon_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "shows renewal warning" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        output = capture_stdout { described_class.print_text(result, info) }
        expect(output).to include("WARNING")
        expect(output).to include("expires within 30 days")
      end
    end

    context "with an expired license" do
      before do
        token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "shows expiration warning" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)

        output = capture_stdout { described_class.print_text(result, info) }
        expect(output).to include("EXPIRED")
        expect(output).to include("WARNING")
        expect(output).to include("has expired")
      end
    end
  end

  describe "JSON output" do
    context "with a valid license" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "produces parseable JSON with all expected fields" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)
        json = JSON.pretty_generate(result)
        parsed = JSON.parse(json)

        expect(parsed["status"]).to eq("valid")
        expect(parsed["organization"]).to eq("Acme Corp")
        expect(parsed["plan"]).to eq("paid")
        expect(parsed["expiration"]).to be_a(String)
        expect(parsed["days_remaining"]).to be_positive
        expect(parsed["renewal_required"]).to be false
        expect(parsed["attribution_required"]).to be false
      end
    end

    context "with an expired license" do
      before do
        token = JWT.encode(expired_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "produces JSON with expired status" do
        info = ReactOnRailsPro::LicenseValidator.license_info
        result = described_class.build_result(info)
        parsed = JSON.parse(JSON.pretty_generate(result))

        expect(parsed["status"]).to eq("expired")
        expect(parsed["renewal_required"]).to be true
        expect(parsed["days_remaining"]).to be_negative
      end
    end
  end

  private

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
