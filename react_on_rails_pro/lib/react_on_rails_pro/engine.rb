# frozen_string_literal: true

require "rails/railtie"

module ReactOnRailsPro
  class Engine < Rails::Engine
    initializer "react_on_rails_pro.routes" do
      ActionDispatch::Routing::Mapper.include ReactOnRailsPro::Routes
    end

    # Validate license on Rails startup
    # This ensures the application fails fast if the license is invalid or missing
    initializer "react_on_rails_pro.validate_license" do
      # Use after_initialize to ensure Rails.logger is available
      config.after_initialize do
        Rails.logger.info "[React on Rails Pro] Validating license..."

        if ReactOnRailsPro::LicenseValidator.validate!
          Rails.logger.info "[React on Rails Pro] License validation successful"
        else
          # License validation will raise an error, so this line won't be reached
          # But we include it for clarity
          Rails.logger.error "[React on Rails Pro] License validation failed"
        end
      end
    end
  end
end
