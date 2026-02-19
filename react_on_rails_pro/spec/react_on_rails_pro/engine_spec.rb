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
      plan: "paid",
      org: "Acme Corp"
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
    context "when in production environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end

      context "with missing license" do
        it "logs a warning" do
          expect(mock_logger).to receive(:warn).with(/No license found/)
          described_class.log_license_status
        end

        it "includes the license URL" do
          expect(mock_logger).to receive(:warn).with(%r{shakacode\.com/react-on-rails-pro})
          described_class.log_license_status
        end

        it "includes the production license violation warning" do
          expect(mock_logger).to receive(:warn).with(/violates the license terms/)
          described_class.log_license_status
        end

        context "when legacy license file exists" do
          before do
            allow(config_file_path).to receive(:exist?).and_return(true)
          end

          it "logs migration warning for env-var setup" do
            allow(mock_logger).to receive(:warn)
            described_class.log_license_status
            expect(mock_logger).to have_received(:warn).with(/legacy license file/)
            expect(mock_logger).to have_received(:warn).with(/REACT_ON_RAILS_PRO_LICENSE/)
          end
        end
      end

      context "with expired license" do
        let(:expired_time) { Time.now.to_i - 3600 }

        before do
          expired_payload = valid_payload.merge(exp: expired_time)
          token = JWT.encode(expired_payload, test_private_key, "RS256")
          ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
        end

        it "logs a warning" do
          expect(mock_logger).to receive(:warn).with(/License has expired/)
          described_class.log_license_status
        end

        it "includes the expiration date" do
          expected_date = Time.at(expired_time).strftime("%Y-%m-%d")
          expect(mock_logger).to receive(:warn).with(/expired on #{expected_date}/)
          described_class.log_license_status
        end

        it "includes the production license violation warning" do
          expect(mock_logger).to receive(:warn).with(/violates the license terms/)
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

        it "includes the production license violation warning" do
          expect(mock_logger).to receive(:warn).with(/violates the license terms/)
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

        it "does not include plan type for paid licenses" do
          expect(mock_logger).to receive(:info).with("[React on Rails Pro] License validated successfully (Acme Corp).")
          described_class.log_license_status
        end

        it "does not log a warning" do
          expect(mock_logger).not_to receive(:warn)
          described_class.log_license_status
        end
      end

      # Dynamically generate tests for plan types that display their name in log messages.
      # Each plan has a display name that differs from the raw plan value.
      {
        "startup" => { org: "Startup Inc", display: "startup license" },
        "nonprofit" => { org: "Charity Org", display: "nonprofit license" },
        "oss" => { org: "Open Source Project", display: "open source license" },
        "education" => { org: "University", display: "education license" },
        "partner" => { org: "Partner Corp", display: "partner license" }
      }.each do |plan_type, config|
        context "with valid #{plan_type} license" do
          let(:plan_payload) do
            {
              sub: "test@example.com",
              iat: Time.now.to_i,
              exp: Time.now.to_i + 3600,
              plan: plan_type,
              org: config[:org]
            }
          end

          before do
            token = JWT.encode(plan_payload, test_private_key, "RS256")
            ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
          end

          it "logs success with plan type" do
            pattern = /License validated successfully \(#{Regexp.escape(config[:org])} - #{config[:display]}\)/
            expect(mock_logger).to receive(:info).with(pattern)
            described_class.log_license_status
          end
        end
      end
    end

    context "when in non-production environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      context "with missing license" do
        it "logs info instead of warning" do
          expect(mock_logger).to receive(:info).with(/No license found/)
          expect(mock_logger).not_to receive(:warn)
          described_class.log_license_status
        end

        it "includes the development/test message" do
          expect(mock_logger).to receive(:info).with(%r{No license required for development/test environments})
          described_class.log_license_status
        end

        context "when legacy license file exists" do
          before do
            allow(config_file_path).to receive(:exist?).and_return(true)
          end

          it "logs migration info for env-var setup" do
            allow(mock_logger).to receive(:info)
            described_class.log_license_status
            expect(mock_logger).to have_received(:info).with(/legacy license file/)
            expect(mock_logger).to have_received(:info).with(/REACT_ON_RAILS_PRO_LICENSE/)
          end
        end
      end

      context "with expired license" do
        let(:expired_time) { Time.now.to_i - 3600 }

        before do
          expired_payload = valid_payload.merge(exp: expired_time)
          token = JWT.encode(expired_payload, test_private_key, "RS256")
          ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
        end

        it "logs info instead of warning" do
          expect(mock_logger).to receive(:info).with(/License has expired/)
          expect(mock_logger).not_to receive(:warn)
          described_class.log_license_status
        end

        it "includes the expiration date" do
          expected_date = Time.at(expired_time).strftime("%Y-%m-%d")
          expect(mock_logger).to receive(:info).with(/expired on #{expected_date}/)
          described_class.log_license_status
        end

        it "includes the development/test message" do
          expect(mock_logger).to receive(:info).with(%r{No license required for development/test environments})
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
      end

      # Test one representative plan type in non-production to verify behavior is consistent
      context "with valid startup license" do
        let(:startup_payload) do
          {
            sub: "test@example.com",
            iat: Time.now.to_i,
            exp: Time.now.to_i + 3600,
            plan: "startup",
            org: "Startup Inc"
          }
        end

        before do
          token = JWT.encode(startup_payload, test_private_key, "RS256")
          ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
        end

        it "logs success with plan type" do
          expect(mock_logger).to receive(:info)
            .with(/License validated successfully \(Startup Inc - startup license\)/)
          described_class.log_license_status
        end
      end
    end
  end
end
