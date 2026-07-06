# frozen_string_literal: true

module BencherToken
  class InvalidToken < StandardError; end

  module_function

  def validate_api_key!(key)
    normalized_key = key.to_s.strip
    raise InvalidToken, "BENCHER_API_KEY is not set; export it or pass --no-upload." if normalized_key.empty?

    return if normalized_key.start_with?("bencher_run_", "bencher_user_")

    raise InvalidToken,
          "BENCHER_API_KEY must be a Bencher API key (bencher_run_* or bencher_user_*); " \
          "create or copy an API key before uploading."
  end

  def validate_upload_auth!(api_key:, api_token:)
    normalized_key = api_key.to_s.strip
    normalized_token = api_token.to_s.strip

    return validate_api_key!(normalized_key) unless normalized_key.empty?
    return unless normalized_token.empty?

    raise InvalidToken, "BENCHER_API_KEY or BENCHER_API_TOKEN is required for Bencher uploads."
  end

  def upload_env(api_key:, api_token:)
    normalized_key = api_key.to_s.strip
    normalized_token = api_token.to_s.strip

    validate_upload_auth!(api_key: normalized_key, api_token: normalized_token)

    return { "BENCHER_API_KEY" => normalized_key, "BENCHER_API_TOKEN" => nil } unless normalized_key.empty?

    { "BENCHER_API_KEY" => nil, "BENCHER_API_TOKEN" => normalized_token }
  end

  def apply_upload_env!(env, api_key:, api_token:)
    upload_env(api_key:, api_token:).each do |key, value|
      value.nil? ? env.delete(key) : env[key] = value
    end
  end
end
