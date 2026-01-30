# frozen_string_literal: true

require "rails/railtie"

module ReactOnRailsPro
  class Engine < Rails::Engine
    initializer "react_on_rails_pro.routes" do
      ActionDispatch::Routing::Mapper.include ReactOnRailsPro::Routes
    end

    # Check license status on Rails startup and log appropriately
    # App continues running regardless of license status
    initializer "react_on_rails_pro.check_license" do
      config.after_initialize do
        status = ReactOnRailsPro::LicenseValidator.license_status

        license_violation_warning = "Using React on Rails Pro in production without a valid license " \
                                    "violates the license terms."
        license_url = "https://www.shakacode.com/react-on-rails-pro/"

        case status
        when :valid
          Rails.logger.info "[React on Rails Pro] License validated successfully."
        when :missing
          Rails.logger.warn "[React on Rails Pro] No license found. #{license_violation_warning} " \
                            "Get a license at #{license_url}"
        when :expired
          Rails.logger.warn "[React on Rails Pro] License has expired. #{license_violation_warning} " \
                            "Renew your license at #{license_url}"
        when :invalid
          Rails.logger.warn "[React on Rails Pro] Invalid license. #{license_violation_warning} " \
                            "Get a license at #{license_url}"
        end
      end
    end
  end
end
