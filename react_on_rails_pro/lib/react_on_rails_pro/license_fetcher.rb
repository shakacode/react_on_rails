# frozen_string_literal: true

require "httpx"
require "json"

module ReactOnRailsPro
  # Fetches license tokens from the licensing API.
  # Used for automatic license renewal when configured with a license_key.
  # Retries up to 2 times on transient failures before falling back to cached token.
  class LicenseFetcher
    REQUEST_TIMEOUT_SECONDS = 5
    MAX_RETRIES = 2
    RETRY_DELAY_SECONDS = 1

    class << self
      def fetch
        return nil unless ReactOnRailsPro.configuration.auto_refresh_enabled?

        response = HTTPX
                   .plugin(:retries, max_retries: MAX_RETRIES, retry_after: RETRY_DELAY_SECONDS)
                   .with(timeout: { request_timeout: REQUEST_TIMEOUT_SECONDS })
                   .with(headers: { "Authorization" => "Bearer #{license_key}" })
                   .get("#{api_url}/api/license")

        return nil if response.is_a?(HTTPX::ErrorResponse)
        return nil unless response.status == 200

        Rails.logger.debug { "[ReactOnRailsPro] License fetched successfully" }
        JSON.parse(response.body.to_s)
      rescue StandardError => e
        Rails.logger.warn { "[ReactOnRailsPro] License fetch failed: #{e.message}" }
        nil
      end

      private

      def license_key
        ReactOnRailsPro.configuration.license_key
      end

      def api_url
        ReactOnRailsPro.configuration.license_api_url
      end
    end
  end
end
