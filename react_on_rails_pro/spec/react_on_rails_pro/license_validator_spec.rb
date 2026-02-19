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
      plan: "paid",
      org: "Acme Corp"
    }
  end

  let(:expired_payload) do
    {
      sub: "test@example.com",
      iat: Time.now.to_i - 7200,
      exp: Time.now.to_i - 3600, # Expired 1 hour ago
      org: "Acme Corp"
    }
  end

  # NOTE: REACT_ON_RAILS_PRO_LICENSE does not exist in test environments,
  # so there's no pre-existing value to preserve/restore.
  before do
    described_class.reset!
    stub_const("ReactOnRailsPro::LicensePublicKey::KEY", test_public_key)
    ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
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
    end

    context "with license missing exp field" do
      let(:payload_without_exp) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          org: "Acme Corp"
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

    # NOTE: Test for non-numeric exp field is not included because the JWT gem
    # validates that exp must be numeric at encode time. Any hand-crafted token
    # with non-numeric exp would fail signature verification in decode_license
    # before check_expiration is reached. The defensive code in check_expiration
    # is kept as defense-in-depth but is unreachable with valid signed JWTs.

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
  end

  describe ".license_status with plan field" do
    # Dynamically generate tests for all valid plan types from VALID_PLANS constant.
    # This ensures tests stay in sync when new plan types are added.
    described_class::VALID_PLANS.each do |plan_type|
      context "when plan is '#{plan_type}'" do
        let(:plan_payload) do
          {
            sub: "test@example.com",
            iat: Time.now.to_i,
            exp: Time.now.to_i + 3600,
            plan: plan_type,
            org: "Acme Corp"
          }
        end

        before do
          token = JWT.encode(plan_payload, test_private_key, "RS256")
          ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
        end

        it "returns :valid" do
          expect(described_class.license_status).to eq(:valid)
        end
      end
    end

    context "when plan is 'free'" do
      let(:free_payload) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "free",
          org: "Acme Corp"
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
          plan: "unknown",
          org: "Acme Corp"
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
          exp: Time.now.to_i + 3600,
          org: "Acme Corp"
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

  describe ".license_status with org field" do
    context "when org is present" do
      let(:payload_with_org) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "paid",
          org: "Acme Corp"
        }
      end

      before do
        token = JWT.encode(payload_with_org, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :valid" do
        expect(described_class.license_status).to eq(:valid)
      end
    end

    context "when org field is absent" do
      let(:payload_without_org) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "paid"
        }
      end

      before do
        token = JWT.encode(payload_without_org, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
      end
    end

    context "when org is empty string" do
      let(:payload_empty_org) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "paid",
          org: ""
        }
      end

      before do
        token = JWT.encode(payload_empty_org, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
      end
    end

    context "when org is whitespace only" do
      let(:payload_whitespace_org) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "paid",
          org: "   "
        }
      end

      before do
        token = JWT.encode(payload_whitespace_org, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns :invalid" do
        expect(described_class.license_status).to eq(:invalid)
      end
    end
  end

  describe ".license_expiration" do
    context "with valid license" do
      let(:exp_time) { Time.now.to_i + 3600 }

      before do
        payload = valid_payload.merge(exp: exp_time)
        token = JWT.encode(payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns the expiration time" do
        result = described_class.license_expiration
        expect(result).to be_a(Time)
        expect(result.to_i).to eq(exp_time)
      end

      it "caches the result" do
        described_class.license_expiration
        expect(described_class).not_to receive(:determine_license_expiration)
        described_class.license_expiration
      end
    end

    context "with expired license" do
      let(:exp_time) { Time.now.to_i - 3600 }

      before do
        payload = expired_payload.merge(exp: exp_time)
        token = JWT.encode(payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns the expiration time even when expired" do
        result = described_class.license_expiration
        expect(result).to be_a(Time)
        expect(result.to_i).to eq(exp_time)
      end
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
      end

      it "returns nil" do
        expect(described_class.license_expiration).to be_nil
      end
    end

    context "with invalid license signature" do
      before do
        wrong_key = OpenSSL::PKey::RSA.new(2048)
        token = JWT.encode(valid_payload, wrong_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns nil" do
        expect(described_class.license_expiration).to be_nil
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
        token = JWT.encode(payload_without_exp, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns nil" do
        expect(described_class.license_expiration).to be_nil
      end
    end
  end

  describe ".license_organization" do
    context "with valid license" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns the organization name" do
        expect(described_class.license_organization).to eq("Acme Corp")
      end

      it "caches the result" do
        described_class.license_organization
        expect(described_class).not_to receive(:determine_license_organization)
        described_class.license_organization
      end
    end

    context "with organization containing leading/trailing whitespace" do
      let(:payload_with_whitespace_org) do
        valid_payload.merge(org: "  Acme Corp  ")
      end

      before do
        token = JWT.encode(payload_with_whitespace_org, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns trimmed organization name" do
        expect(described_class.license_organization).to eq("Acme Corp")
      end
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
      end

      it "returns nil" do
        expect(described_class.license_organization).to be_nil
      end
    end

    context "with invalid license signature" do
      before do
        wrong_key = OpenSSL::PKey::RSA.new(2048)
        token = JWT.encode(valid_payload, wrong_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns nil" do
        expect(described_class.license_organization).to be_nil
      end
    end

    context "with license missing org field" do
      let(:payload_without_org) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "paid"
        }
      end

      before do
        token = JWT.encode(payload_without_org, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns nil" do
        expect(described_class.license_organization).to be_nil
      end
    end
  end

  describe ".license_plan" do
    context "with valid license and 'paid' plan" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns 'paid'" do
        expect(described_class.license_plan).to eq("paid")
      end

      it "caches the result" do
        described_class.license_plan
        expect(described_class).not_to receive(:determine_license_plan)
        described_class.license_plan
      end
    end

    context "with valid license and 'startup' plan" do
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

      it "returns 'startup'" do
        expect(described_class.license_plan).to eq("startup")
      end
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
      end

      it "returns nil" do
        expect(described_class.license_plan).to be_nil
      end
    end

    context "with invalid license signature" do
      before do
        wrong_key = OpenSSL::PKey::RSA.new(2048)
        token = JWT.encode(valid_payload, wrong_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns nil" do
        expect(described_class.license_plan).to be_nil
      end
    end

    context "with license missing plan field" do
      let(:payload_without_plan) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          org: "Acme Corp"
        }
      end

      before do
        token = JWT.encode(payload_without_plan, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns nil" do
        expect(described_class.license_plan).to be_nil
      end
    end

    context "with invalid plan type" do
      let(:invalid_plan_payload) do
        {
          sub: "test@example.com",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 3600,
          plan: "free",
          org: "Acme Corp"
        }
      end

      before do
        token = JWT.encode(invalid_plan_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns nil" do
        expect(described_class.license_plan).to be_nil
      end
    end
  end

  describe ".attribution_required?" do
    context "with paid plan (no attribution required)" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns false" do
        expect(described_class.attribution_required?).to be false
      end

      it "caches the result" do
        described_class.attribution_required?
        expect(described_class).not_to receive(:determine_attribution_required)
        described_class.attribution_required?
      end
    end

    context "with partner plan (no attribution required)" do
      let(:partner_payload) do
        valid_payload.merge(plan: "partner")
      end

      before do
        token = JWT.encode(partner_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns false" do
        expect(described_class.attribution_required?).to be false
      end
    end

    context "with startup plan (attribution required)" do
      let(:startup_payload) do
        valid_payload.merge(plan: "startup")
      end

      before do
        token = JWT.encode(startup_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns true" do
        expect(described_class.attribution_required?).to be true
      end
    end

    context "with oss plan (attribution required)" do
      let(:oss_payload) do
        valid_payload.merge(plan: "oss")
      end

      before do
        token = JWT.encode(oss_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns true" do
        expect(described_class.attribution_required?).to be true
      end
    end

    context "with nonprofit plan (attribution optional, default no)" do
      let(:nonprofit_payload) do
        valid_payload.merge(plan: "nonprofit")
      end

      before do
        token = JWT.encode(nonprofit_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns false by default" do
        expect(described_class.attribution_required?).to be false
      end
    end

    context "with education plan (attribution optional, default no)" do
      let(:education_payload) do
        valid_payload.merge(plan: "education")
      end

      before do
        token = JWT.encode(education_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns false by default" do
        expect(described_class.attribution_required?).to be false
      end
    end

    context "with explicit attribution=true override" do
      let(:nonprofit_with_attribution) do
        valid_payload.merge(plan: "nonprofit", attribution: true)
      end

      before do
        token = JWT.encode(nonprofit_with_attribution, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns true when explicitly set" do
        expect(described_class.attribution_required?).to be true
      end
    end

    context "with explicit attribution=false override" do
      let(:startup_without_attribution) do
        valid_payload.merge(plan: "startup", attribution: false)
      end

      before do
        token = JWT.encode(startup_without_attribution, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns false when explicitly disabled" do
        expect(described_class.attribution_required?).to be false
      end
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
      end

      it "returns false" do
        expect(described_class.attribution_required?).to be false
      end
    end
  end

  describe ".license_info" do
    context "with valid paid license" do
      before do
        token = JWT.encode(valid_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns a hash with all license information" do
        info = described_class.license_info

        expect(info[:org]).to eq("Acme Corp")
        expect(info[:plan]).to eq("paid")
        expect(info[:status]).to eq(:valid)
        expect(info[:attribution_required]).to be false
        expect(info[:expiration]).to be_a(Time)
      end
    end

    context "with startup license" do
      let(:startup_payload) do
        valid_payload.merge(plan: "startup")
      end

      before do
        token = JWT.encode(startup_payload, test_private_key, "RS256")
        ENV["REACT_ON_RAILS_PRO_LICENSE"] = token
      end

      it "returns attribution_required as true" do
        info = described_class.license_info

        expect(info[:plan]).to eq("startup")
        expect(info[:attribution_required]).to be true
      end
    end

    context "with missing license" do
      before do
        ENV.delete("REACT_ON_RAILS_PRO_LICENSE")
      end

      it "returns appropriate defaults" do
        info = described_class.license_info

        expect(info[:org]).to be_nil
        expect(info[:plan]).to be_nil
        expect(info[:status]).to eq(:missing)
        expect(info[:attribution_required]).to be false
        expect(info[:expiration]).to be_nil
      end
    end
  end

  describe ".reset!" do
    before do
      valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token
      described_class.license_status # Cache the result
      described_class.license_expiration # Cache the expiration
      described_class.license_organization # Cache the organization
      described_class.license_plan # Cache the plan
      described_class.attribution_required? # Cache attribution_required
    end

    it "clears the cached license status" do
      expect(described_class.instance_variable_defined?(:@license_status)).to be true
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@license_status)).to be false
    end

    it "clears the cached license expiration" do
      expect(described_class.instance_variable_defined?(:@license_expiration)).to be true
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@license_expiration)).to be false
    end

    it "clears the cached license organization" do
      expect(described_class.instance_variable_defined?(:@license_organization)).to be true
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@license_organization)).to be false
    end

    it "clears the cached license plan" do
      expect(described_class.instance_variable_defined?(:@license_plan)).to be true
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@license_plan)).to be false
    end

    it "clears the cached attribution_required" do
      expect(described_class.instance_variable_defined?(:@attribution_required)).to be true
      described_class.reset!
      expect(described_class.instance_variable_defined?(:@attribution_required)).to be false
    end
  end

  describe "thread safety" do
    it "handles concurrent first-time access without errors" do
      valid_token = JWT.encode(valid_payload, test_private_key, "RS256")
      ENV["REACT_ON_RAILS_PRO_LICENSE"] = valid_token

      # Reset ONCE before spawning threads to test concurrent initialization
      described_class.reset!

      # Use more threads for better race condition detection
      threads = Array.new(100) do
        Thread.new do
          described_class.license_status
        end
      end

      results = threads.map(&:value)
      expect(results).to all(eq(:valid))
    end
  end
end
