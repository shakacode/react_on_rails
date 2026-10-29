# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/ssr_status_handler"
require "active_support/concern"
require "active_support/core_ext/object/blank"

# Minimal controller double that includes the concern so after_action runs.
# Tests call apply_ssr_http_response directly since after_action registration
# requires a full Rails controller lifecycle.
RSpec.describe ReactOnRails::SsrStatusHandler do
  # Build a minimal host object that has request/response methods (as a controller would)
  # and mix in the concern's instance methods.
  subject(:handler) do
    fr = fake_request
    fres = fake_response
    Object.new.tap do |obj|
      obj.define_singleton_method(:request) { fr }
      obj.define_singleton_method(:response) { fres }
      obj.extend(described_class)
    end
  end

  let(:env_key) { described_class::SSR_HTTP_RESPONSE_ENV_KEY }
  let(:request_env) { {} }
  let(:fake_request) { double("request", env: request_env) } # rubocop:disable RSpec/VerifiedDoubles
  let(:response_headers) { {} }
  let(:fake_response) do
    double("response", headers: response_headers, committed?: false).tap do |r| # rubocop:disable RSpec/VerifiedDoubles
      allow(r).to receive(:status=)
    end
  end

  def apply!
    handler.send(:apply_ssr_http_response)
  end

  # ── Valid metadata ──

  describe "valid httpResponse" do
    it "sets status 404 for notFound responses" do
      request_env[env_key] = { "status" => 404 }
      apply!
      expect(fake_response).to have_received(:status=).with(404)
    end

    it "sets status 307 and Location for redirect responses" do
      request_env[env_key] = { "status" => 307, "location" => "/target" }
      apply!
      expect(fake_response).to have_received(:status=).with(307)
      expect(response_headers["Location"]).to eq("/target")
    end

    it "sets status 301 and Location for permanent redirects" do
      request_env[env_key] = { "status" => 301, "location" => "/new-home" }
      apply!
      expect(fake_response).to have_received(:status=).with(301)
      expect(response_headers["Location"]).to eq("/new-home")
    end

    it "sets status 500 without Location for server errors" do
      request_env[env_key] = { "status" => 500 }
      apply!
      expect(fake_response).to have_received(:status=).with(500)
      expect(response_headers["Location"]).to be_nil
    end

    it "accepts Location with query params and fragments" do
      request_env[env_key] = { "status" => 307, "location" => "/search?q=test&page=2#results" }
      apply!
      expect(response_headers["Location"]).to eq("/search?q=test&page=2#results")
    end

    it "accepts Location with curly braces" do
      request_env[env_key] = { "status" => 307, "location" => "/api?filter={type}" }
      apply!
      expect(response_headers["Location"]).to eq("/api?filter={type}")
    end

    it "accepts absolute URL Location" do
      request_env[env_key] = { "status" => 307, "location" => "https://example.com/landing" }
      apply!
      expect(response_headers["Location"]).to eq("https://example.com/landing")
    end
  end

  # ── Invalid metadata: status ──

  describe "invalid status" do
    it "rejects non-Integer status" do
      request_env[env_key] = { "status" => "404" }
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "rejects Float status" do
      request_env[env_key] = { "status" => 404.0 }
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "rejects status below 200" do
      request_env[env_key] = { "status" => 101 }
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "rejects status above 599" do
      request_env[env_key] = { "status" => 600 }
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "rejects nil status" do
      request_env[env_key] = { "status" => nil }
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "rejects missing status key" do
      request_env[env_key] = { "location" => "/target" }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end
  end

  # ── Invalid metadata: Location header injection ──

  describe "Location header injection prevention" do
    it "rejects Location containing CR (\\r)" do
      request_env[env_key] = { "status" => 307, "location" => "/target\r\nX-Injected: evil" }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects Location containing LF (\\n)" do
      request_env[env_key] = { "status" => 307, "location" => "/target\nX-Injected: evil" }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects Location containing null byte (\\x00)" do
      request_env[env_key] = { "status" => 307, "location" => "/target\x00evil" }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects Location containing tab (\\t)" do
      request_env[env_key] = { "status" => 307, "location" => "/target\tevil" }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects Location containing bell character (\\x07)" do
      request_env[env_key] = { "status" => 307, "location" => "/target\x07evil" }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects Location containing DEL (\\x7F)" do
      request_env[env_key] = { "status" => 307, "location" => "/target\x7Fevil" }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects Location containing literal backslash-n (\\\\n)" do
      request_env[env_key] = { "status" => 307, "location" => '/target\\nevil' }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects Location containing literal backslash-r (\\\\r)" do
      request_env[env_key] = { "status" => 307, "location" => '/target\\revil' }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects empty Location string (atomic rejection — a 307 with empty Location is invalid)" do
      request_env[env_key] = { "status" => 307, "location" => "" }
      apply!
      # Empty Location with a redirect status is rejected entirely.
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects non-String Location" do
      request_env[env_key] = { "status" => 307, "location" => 12_345 }
      apply!
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "rejects binary Location without raising ArgumentError" do
      binary = "/target\xFF\xFE".dup.force_encoding("UTF-8")
      request_env[env_key] = { "status" => 307, "location" => binary }
      expect { apply! }.not_to raise_error
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end

    it "does not set status when Location is present but invalid (atomic rejection)" do
      request_env[env_key] = { "status" => 307, "location" => "/bad\nheader" }
      apply!
      # Both status and Location are rejected together.
      expect(fake_response).not_to have_received(:status=)
      expect(response_headers["Location"]).to be_nil
    end
  end

  # ── Response already committed (streaming) ──

  describe "committed response (streaming SSR)" do
    let(:fake_response) do
      double("response", headers: response_headers, committed?: true).tap do |r| # rubocop:disable RSpec/VerifiedDoubles
        allow(r).to receive(:status=)
      end
    end

    it "does not modify status when response is already committed" do
      request_env[env_key] = { "status" => 404 }
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "does not set Location when response is already committed" do
      request_env[env_key] = { "status" => 307, "location" => "/target" }
      apply!
      expect(response_headers["Location"]).to be_nil
    end
  end

  # ── Edge cases ──

  describe "edge cases" do
    it "does nothing when no httpResponse is in request.env" do
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "does nothing when httpResponse is not a Hash" do
      request_env[env_key] = "not a hash"
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "does nothing when httpResponse is nil" do
      request_env[env_key] = nil
      apply!
      expect(fake_response).not_to have_received(:status=)
    end

    it "accepts status-only metadata (no location key)" do
      request_env[env_key] = { "status" => 404 }
      apply!
      expect(fake_response).to have_received(:status=).with(404)
      expect(response_headers["Location"]).to be_nil
    end
  end
end
