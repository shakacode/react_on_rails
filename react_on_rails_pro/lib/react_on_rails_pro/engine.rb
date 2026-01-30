# frozen_string_literal: true

require "rails/railtie"

module ReactOnRailsPro
  class Engine < Rails::Engine
    LICENSE_URL = "https://www.shakacode.com/react-on-rails-pro/"
    private_constant :LICENSE_URL

    initializer "react_on_rails_pro.routes" do
      ActionDispatch::Routing::Mapper.include ReactOnRailsPro::Routes
    end

    # Check license status on Rails startup and log appropriately
    # App continues running regardless of license status
    initializer "react_on_rails_pro.check_license" do
      config.after_initialize { ReactOnRailsPro::Engine.log_license_status }
    end

    class << self
      def log_license_status
        status = ReactOnRailsPro::LicenseValidator.license_status

        case status
        when :valid
          Rails.logger.info "[React on Rails Pro] License validated successfully."
        when :missing
          log_license_issue("No license found", "Get a license at #{LICENSE_URL}")
        when :expired
          log_license_issue("License has expired", "Renew your license at #{LICENSE_URL}")
        when :invalid
          log_license_issue("Invalid license", "Get a license at #{LICENSE_URL}")
        end
      end

      private

      def log_license_issue(issue, action)
        prefix = "[React on Rails Pro] #{issue}."

        if Rails.env.production?
          warning = "Using React on Rails Pro in production without a valid license " \
                    "violates the license terms."
          Rails.logger.warn "#{prefix} #{warning} #{action}"
        else
          Rails.logger.info "#{prefix} No license required for development/test environments."
        end
      end
    end
  end
end
