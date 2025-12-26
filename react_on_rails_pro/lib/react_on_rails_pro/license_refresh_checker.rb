# frozen_string_literal: true

module ReactOnRailsPro
  # Handles the timing logic for automatic license refresh.
  # Determines when to check for a refreshed license based on expiry proximity.
  #
  # Refresh schedule:
  # - <= 7 days until expiry: check daily
  # - <= 30 days until expiry: check weekly
  # - > 30 days: no refresh needed
  module LicenseRefreshChecker
    class << self
      def maybe_refresh_license
        return unless ReactOnRailsPro.configuration.auto_refresh_enabled?
        return unless should_check_for_refresh?

        response = LicenseFetcher.fetch
        return if response.nil?

        LicenseCache.write(response)
      end

      # Seeds the cache on first boot so that refresh logic works on subsequent boots.
      # The cache stores the token's expiry, which should_check_for_refresh? needs to determine
      # when to trigger a refresh.
      def seed_cache_if_needed(license_data)
        return unless ReactOnRailsPro.configuration.auto_refresh_enabled?
        return if LicenseCache.token.present? # Cache already exists

        token = load_token_from_env_or_file
        return unless token

        expires_at = Time.at(license_data["exp"])

        LicenseCache.write(
          "token" => token,
          "expires_at" => expires_at.iso8601
        )
      end

      def should_check_for_refresh?
        expires_at = LicenseCache.expires_at
        return false if expires_at.nil?

        days_until_expiry = ((expires_at - Time.now) / 1.day).to_i

        if days_until_expiry <= 7
          last_fetch_older_than?(1.day)
        elsif days_until_expiry <= 30
          last_fetch_older_than?(7.days)
        else
          false
        end
      end

      def last_fetch_older_than?(duration)
        fetched_at = LicenseCache.fetched_at
        return true if fetched_at.nil?

        Time.now - fetched_at > duration
      end

      # Loads token from ENV or file, skipping cache (used for seeding)
      def load_token_from_env_or_file
        license = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", nil)
        return license if license.present?

        config_path = Rails.root.join("config", "react_on_rails_pro_license.key")
        return File.read(config_path).strip if config_path.exist?

        nil
      end
    end
  end
end
