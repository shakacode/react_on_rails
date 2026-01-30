# frozen_string_literal: true

require "jwt"

module ReactOnRailsPro
  # Validates React on Rails Pro licenses.
  # This class only determines license status - it does NOT log.
  # All logging is handled by Engine.log_license_status for environment-aware messaging.
  class LicenseValidator
    class << self
      # Returns the current license status (never raises, never logs)
      # Thread-safe: uses Mutex to prevent race conditions during initialization
      # @return [Symbol] One of :valid, :expired, :invalid, :missing
      def license_status
        return @license_status if defined?(@license_status)

        @mutex ||= Mutex.new
        @mutex.synchronize do
          # Double-check pattern: another thread may have set it while we waited
          return @license_status if defined?(@license_status)

          @license_status = determine_license_status
        end
      end

      # Resets all cached state (primarily for testing)
      def reset!
        if defined?(@mutex) && @mutex
          @mutex.synchronize do
            remove_instance_variable(:@license_status) if defined?(@license_status)
          end
        end
        remove_instance_variable(:@mutex) if defined?(@mutex)
      end

      private

      # Determines the license status by loading, decoding, and validating
      # @return [Symbol] The license status
      def determine_license_status
        # Step 1: Load license string
        license_string = load_license_string
        return :missing unless license_string

        # Step 2: Decode and verify JWT
        decoded_data = decode_license(license_string)
        return :invalid unless decoded_data

        # Step 3: Check plan validity
        plan_status = check_plan(decoded_data)
        return plan_status unless plan_status == :valid

        # Step 4: Check expiration
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
        return unless config_path.exist?

        begin
          File.read(config_path).strip
        rescue StandardError
          nil
        end
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
      rescue JWT::DecodeError, StandardError
        nil
      end

      # Checks if the license plan is valid for production use
      # Licenses without a plan field are considered valid (backwards compatibility with old paid licenses)
      # Only "paid" plan is valid; all other plans (e.g., "free") are invalid
      # @return [Symbol] :valid or :invalid
      def check_plan(decoded_data)
        plan = decoded_data["plan"]
        return :valid unless plan # No plan field = valid (backwards compat with old paid licenses)
        return :valid if plan == "paid"

        :invalid
      end

      # Checks if the license is expired
      # @return [Symbol] :valid, :expired, or :invalid (if exp field missing)
      def check_expiration(license)
        return :invalid unless license["exp"]

        current_time = Time.now.to_i
        exp_time = license["exp"]

        return :expired if current_time > exp_time

        :valid
      end

      def public_key
        ReactOnRailsPro::LicensePublicKey::KEY
      end
    end
  end
end
