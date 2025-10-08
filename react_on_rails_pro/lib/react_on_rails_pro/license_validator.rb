# frozen_string_literal: true

require "jwt"
require "pathname"

module ReactOnRailsPro
  class LicenseValidator
    class << self
      def valid?
        return @valid if defined?(@valid)

        @valid = validate_license
      end

      def reset!
        remove_instance_variable(:@valid) if defined?(@valid)
        remove_instance_variable(:@license_data) if defined?(@license_data)
        remove_instance_variable(:@validation_error) if defined?(@validation_error)
      end

      def license_data
        @license_data ||= load_and_decode_license
      end

      def validation_error
        @validation_error
      end

      private

      def validate_license
        # In development, show warnings but allow usage
        development_mode = Rails.env.development? || Rails.env.test?

        begin
          license = load_and_decode_license
          return false unless license

          # Check expiry if present
          if license["exp"] && Time.now.to_i > license["exp"]
            @validation_error = "License has expired"
            handle_invalid_license(development_mode, @validation_error)
            return development_mode
          end

          true
        rescue JWT::DecodeError => e
          @validation_error = "Invalid license signature: #{e.message}"
          handle_invalid_license(development_mode, @validation_error)
          development_mode
        rescue StandardError => e
          @validation_error = "License validation error: #{e.message}"
          handle_invalid_license(development_mode, @validation_error)
          development_mode
        end
      end

      def load_and_decode_license
        license_string = load_license_string
        return nil unless license_string

        JWT.decode(
          license_string,
          public_key,
          true,
          algorithm: "RS256"
        ).first
      end

      def load_license_string
        # First try environment variable
        license = ENV["REACT_ON_RAILS_PRO_LICENSE"]
        return license if license.present?

        # Then try config file
        config_path = Rails.root.join("config", "react_on_rails_pro_license.key")
        return File.read(config_path).strip if config_path.exist?

        @validation_error = "No license found. Please set REACT_ON_RAILS_PRO_LICENSE environment variable " \
                           "or create config/react_on_rails_pro_license.key file. " \
                           "Visit https://shakacode.com/react-on-rails-pro to obtain a license."
        handle_invalid_license(Rails.env.development? || Rails.env.test?, @validation_error)
        nil
      end

      def public_key
        ReactOnRailsPro::LicensePublicKey::KEY
      end

      def handle_invalid_license(development_mode, message)
        full_message = "[React on Rails Pro] #{message}"

        if development_mode
          Rails.logger.warn(full_message)
          puts "\e[33m#{full_message}\e[0m" # Yellow warning in console
        else
          Rails.logger.error(full_message)
          raise ReactOnRailsPro::Error, full_message
        end
      end
    end
  end
end
