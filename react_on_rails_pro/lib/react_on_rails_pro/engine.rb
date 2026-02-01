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
          Rails.logger.warn "[React on Rails Pro] No license found. Get a license at #{LICENSE_URL}"
        when :expired
          Rails.logger.warn "[React on Rails Pro] License has expired. Renew your license at #{LICENSE_URL}"
        when :invalid
          Rails.logger.warn "[React on Rails Pro] Invalid license. Get a license at #{LICENSE_URL}"
        end
      end
    end
  end
end
