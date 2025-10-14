# frozen_string_literal: true

require "jwt"

module ReactOnRailsPro
  class LicenseValidator
    class << self
      # Validates the license and raises an exception if invalid.
      # Caches the result after first validation.
      #
      # @return [Boolean] true if license is valid
      # @raise [ReactOnRailsPro::Error] if license is invalid
      def validate!
        return @validate if defined?(@validate)

        @validate = validate_license
      end

      def reset!
        remove_instance_variable(:@validate) if defined?(@validate)
        remove_instance_variable(:@license_data) if defined?(@license_data)
        remove_instance_variable(:@validation_error) if defined?(@validation_error)
      end

      def license_data
        @license_data ||= load_and_decode_license
      end

      attr_reader :validation_error

      private

      # Grace period: 1 month (in seconds)
      GRACE_PERIOD_SECONDS = 30 * 24 * 60 * 60

      def validate_license
        license = load_and_decode_license

        # Check that exp field exists
        unless license["exp"]
          @validation_error = "License is missing required expiration field. " \
                              "Your license may be from an older version. " \
                              "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
          handle_invalid_license(@validation_error)
        end

        # Check expiry with grace period for production
        current_time = Time.now.to_i
        exp_time = license["exp"]

        if current_time > exp_time
          days_expired = ((current_time - exp_time) / (24 * 60 * 60)).to_i

          @validation_error = "License has expired #{days_expired} day(s) ago. " \
                              "Get a FREE evaluation license (3 months) at https://shakacode.com/react-on-rails-pro " \
                              "or upgrade to a paid license for production use."

          # In production, allow a grace period of 1 month with error logging
          if production? && within_grace_period?(exp_time)
            grace_days_remaining = grace_days_remaining(exp_time)
            Rails.logger.error(
              "[React on Rails Pro] WARNING: #{@validation_error} " \
              "Grace period: #{grace_days_remaining} day(s) remaining. " \
              "Application will fail to start after grace period expires."
            )
          else
            handle_invalid_license(@validation_error)
          end
        end

        # Log license type if present (for analytics)
        log_license_info(license)

        true
      rescue JWT::DecodeError => e
        @validation_error = "Invalid license signature: #{e.message}. " \
                            "Your license file may be corrupted. " \
                            "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
        handle_invalid_license(@validation_error)
      rescue StandardError => e
        @validation_error = "License validation error: #{e.message}. " \
                            "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
        handle_invalid_license(@validation_error)
      end

      def production?
        Rails.env.production?
      end

      def within_grace_period?(exp_time)
        Time.now.to_i <= exp_time + GRACE_PERIOD_SECONDS
      end

      def grace_days_remaining(exp_time)
        grace_end = exp_time + GRACE_PERIOD_SECONDS
        seconds_remaining = grace_end - Time.now.to_i
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

        @validation_error = "No license found. Please set REACT_ON_RAILS_PRO_LICENSE environment variable " \
                            "or create #{config_path} file. " \
                            "Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro"
        handle_invalid_license(@validation_error)
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
