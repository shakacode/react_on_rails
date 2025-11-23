# frozen_string_literal: true

require "jwt"

module ReactOnRailsPro
  class LicenseValidator
    # Grace period: 1 month (in seconds)
    GRACE_PERIOD_SECONDS = 30 * 24 * 60 * 60

    class << self
      # Validates the license and returns the license data
      # Caches the result after first validation
      # @return [Hash] The license data
      # @raise [ReactOnRailsPro::Error] if license is invalid
      def validated_license_data!
        return @license_data if defined?(@license_data)

        begin
          # Load and decode license (but don't cache yet)
          license_data = load_and_decode_license

          # Validate the license (raises if invalid, returns grace_days)
          grace_days = validate_license_data(license_data)

          # Validation passed - now cache both data and grace days
          @license_data = license_data
          @grace_days_remaining = grace_days

          @license_data
        rescue JWT::DecodeError => e
          error = "Invalid license signature: #{e.message}. " \
                  "Your license file may be corrupted. " \
                  "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
          handle_invalid_license(error)
        rescue StandardError => e
          error = "License validation error: #{e.message}. " \
                  "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
          handle_invalid_license(error)
        end
      end

      def reset!
        remove_instance_variable(:@license_data) if defined?(@license_data)
        remove_instance_variable(:@grace_days_remaining) if defined?(@grace_days_remaining)
      end

      # Checks if the current license is an evaluation/free license
      # @return [Boolean] true if plan is not "paid"
      def evaluation?
        data = validated_license_data!
        plan = data["plan"].to_s
        plan != "paid" && !plan.start_with?("paid_")
      end

      # Returns remaining grace period days if license is expired but in grace period
      # @return [Integer, nil] Number of days remaining, or nil if not in grace period
      def grace_days_remaining
        # Ensure license is validated and cached
        validated_license_data!

        # Return cached grace days (nil if not in grace period)
        @grace_days_remaining
      end

      private

      # Validates the license data and raises if invalid
      # Logs info/errors and handles grace period logic
      # @param license [Hash] The decoded license data
      # @return [Integer, nil] Grace days remaining if in grace period, nil otherwise
      # @raise [ReactOnRailsPro::Error] if license is invalid
      def validate_license_data(license)
        # Check that exp field exists
        unless license["exp"]
          error = "License is missing required expiration field. " \
                  "Your license may be from an older version. " \
                  "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
          handle_invalid_license(error)
        end

        # Check expiry with grace period for production
        current_time = Time.now.to_i
        exp_time = license["exp"]
        grace_days = nil

        if current_time > exp_time
          days_expired = ((current_time - exp_time) / (24 * 60 * 60)).to_i

          error = "License has expired #{days_expired} day(s) ago. " \
                  "Get a FREE evaluation license (3 months) at https://shakacode.com/react-on-rails-pro " \
                  "or upgrade to a paid license for production use."

          # In production, allow a grace period of 1 month with error logging
          if production? && within_grace_period?(exp_time)
            # Calculate grace days once here
            grace_days = calculate_grace_days_remaining(exp_time)
            Rails.logger.error(
              "[React on Rails Pro] WARNING: #{error} " \
              "Grace period: #{grace_days} day(s) remaining. " \
              "Application will fail to start after grace period expires."
            )
          else
            handle_invalid_license(error)
          end
        end

        # Log license type if present (for analytics)
        log_license_info(license)

        # Return grace days (nil if not in grace period)
        grace_days
      end

      def production?
        Rails.env.production?
      end

      def within_grace_period?(exp_time)
        Time.now.to_i <= exp_time + GRACE_PERIOD_SECONDS
      end

      # Calculates remaining grace period days
      # @param exp_time [Integer] Expiration timestamp
      # @return [Integer] Days remaining (0 or more)
      def calculate_grace_days_remaining(exp_time)
        grace_end = exp_time + GRACE_PERIOD_SECONDS
        seconds_remaining = grace_end - Time.now.to_i
        return 0 if seconds_remaining <= 0

        (seconds_remaining / (24 * 60 * 60)).to_i
      end

      def load_and_decode_license
        license_string = load_license_string

        JWT.decode(
          # The JWT token containing the license data
          license_string,
          # RSA public key used to verify the JWT signature
          public_key,
          # verify_signature: NEVER set to false! When false, signature verification is skipped,
          # allowing anyone to forge licenses. Must always be true for security.
          true,
          # NOTE: Never remove the 'algorithm' parameter from JWT.decode to prevent algorithm bypassing vulnerabilities.
          # Ensure to hardcode the expected algorithm.
          # See: https://auth0.com/blog/critical-vulnerabilities-in-json-web-token-libraries/
          algorithm: "RS256",
          # Disable automatic expiration verification so we can handle it manually with custom logic
          verify_expiration: false
          # JWT.decode returns an array [data, header]; we use `.first` to get the data (payload).
        ).first
      end

      def load_license_string
        # First try environment variable
        license = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", nil)
        return license if license.present?

        # Then try config file
        config_path = Rails.root.join("config", "react_on_rails_pro_license.key")
        return File.read(config_path).strip if config_path.exist?

        error_msg = "No license found. Please set REACT_ON_RAILS_PRO_LICENSE environment variable " \
                    "or create #{config_path} file. " \
                    "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
        handle_invalid_license(error_msg)
      end

      def public_key
        ReactOnRailsPro::LicensePublicKey::KEY
      end

      def handle_invalid_license(message)
        full_message = "[React on Rails Pro] #{message}"
        Rails.logger.error(full_message)
        raise ReactOnRailsPro::Error, full_message
      end

      def log_license_info(license)
        plan = license["plan"]
        iss = license["iss"]

        Rails.logger.info("[React on Rails Pro] License plan: #{plan}") if plan
        Rails.logger.info("[React on Rails Pro] Issued by: #{iss}") if iss
      end
    end
  end
end
