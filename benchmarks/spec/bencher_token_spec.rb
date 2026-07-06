# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/bencher_token"

RSpec.describe BencherToken do
  describe ".validate_api_key!" do
    it "rejects a missing key" do
      expect { described_class.validate_api_key!(nil) }
        .to raise_error(BencherToken::InvalidToken, /BENCHER_API_KEY is not set/)
    end

    it "accepts a project-scoped API key" do
      expect { described_class.validate_api_key!("bencher_run_123") }.not_to raise_error
    end

    it "accepts a user-scoped API key" do
      expect { described_class.validate_api_key!("bencher_user_123") }.not_to raise_error
    end

    it "rejects values that are not Bencher API keys" do
      expect { described_class.validate_api_key!("jwt-or-api-token") }
        .to raise_error(BencherToken::InvalidToken, /must be a Bencher API key/)
    end
  end

  describe ".validate_upload_auth!" do
    it "accepts a valid API key" do
      expect { described_class.validate_upload_auth!(api_key: "bencher_run_123", api_token: nil) }.not_to raise_error
    end

    it "accepts a legacy API token when no API key is present" do
      expect { described_class.validate_upload_auth!(api_key: nil, api_token: "legacy-token") }.not_to raise_error
    end

    it "rejects a missing key and token" do
      expect { described_class.validate_upload_auth!(api_key: nil, api_token: nil) }
        .to raise_error(BencherToken::InvalidToken, /BENCHER_API_KEY or BENCHER_API_TOKEN/)
    end

    it "does not let an invalid API key hide behind a legacy token" do
      expect { described_class.validate_upload_auth!(api_key: "legacy-token", api_token: "other-token") }
        .to raise_error(BencherToken::InvalidToken, /must be a Bencher API key/)
    end
  end
end
