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

        case status
        when :valid
          Rails.logger.info "[React on Rails Pro] License validated successfully."
        when :missing
          Rails.logger.warn "[React on Rails Pro] No license found. " \
                            "Using React on Rails Pro in production without a valid license violates the license terms. " \
                            "Get a license at https://www.shakacode.com/react-on-rails-pro/"
        when :expired
          Rails.logger.warn "[React on Rails Pro] License has expired. " \
                            "Using React on Rails Pro in production without a valid license violates the license terms. " \
                            "Renew your license at https://www.shakacode.com/react-on-rails-pro/"
        when :invalid
          Rails.logger.warn "[React on Rails Pro] Invalid license. " \
                            "Using React on Rails Pro in production without a valid license violates the license terms. " \
                            "Get a license at https://www.shakacode.com/react-on-rails-pro/"
        end
      end
    end
  end
end
