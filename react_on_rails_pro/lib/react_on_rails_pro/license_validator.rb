# frozen_string_literal: true

require "jwt"

module ReactOnRailsPro
  class LicenseValidator
    class << self
      # Returns the current license status (never raises)
      # @return [Symbol] One of :valid, :expired, :invalid, :missing
      def license_status
        return @license_status if defined?(@license_status)

        @license_status = determine_license_status
      end

      # Resets all cached state (primarily for testing)
      def reset!
        remove_instance_variable(:@license_status) if defined?(@license_status)
      end

      private

      # Determines the license status by loading, decoding, and validating
      # @return [Symbol] The license status
      def determine_license_status
        # Step 1: Load license string
        license_string = load_license_string
        unless license_string
          log_license_warning("No license found. Running in unlicensed mode.")
          return :missing
        end

        # Step 2: Decode and verify JWT
        decoded_data = decode_license(license_string)
        return :invalid unless decoded_data

        # Step 3: Check expiration
        check_expiration(decoded_data)
      end

      # Loads license string from env var or file
      # @return [String, nil] License string or nil if not found
      def load_license_string
        # First try environment variable
        license = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", nil)
        return license if license.present?

        # Then try config file
        config_path = Rails.root.join("config", "react_on_rails_pro_license.key")
        if config_path.exist?
          begin
            return File.read(config_path).strip
          rescue StandardError => e
            log_license_warning("Failed to read license file: #{e.message}. Running in unlicensed mode.")
          end
        end

        nil
      end

      # Decodes and verifies the JWT license
      # @return [Hash, nil] Decoded license data or nil if invalid
      def decode_license(license_string)
        JWT.decode(
          license_string,
          public_key,
          true, # verify signature - NEVER set to false!
          algorithm: "RS256",
          verify_expiration: false # we handle expiration manually
        ).first
      rescue JWT::DecodeError => e
        log_license_warning("Invalid license signature: #{e.message}. Running in unlicensed mode.")
        nil
      rescue StandardError => e
        log_license_warning("License validation error: #{e.message}. Running in unlicensed mode.")
        nil
      end

      # Checks if the license is expired
      # @return [Symbol] :valid, :expired, or :invalid (if exp field missing)
      def check_expiration(license)
        unless license["exp"]
          log_license_warning("License is missing expiration field. Running in unlicensed mode.")
          return :invalid
        end

        current_time = Time.now.to_i
        exp_time = license["exp"]

        if current_time > exp_time
          days_expired = ((current_time - exp_time) / (24 * 60 * 60)).to_i
          log_license_warning("License expired #{days_expired} day(s) ago. Running in unlicensed mode.")
          return :expired
        end

        :valid
      end

      def public_key
        ReactOnRailsPro::LicensePublicKey::KEY
      end

      def log_license_warning(message)
        Rails.logger.warn("[React on Rails Pro] #{message}")
      end
    end
  end
end
