# frozen_string_literal: true

require "rails/railtie"

module ReactOnRailsPro
  class Engine < Rails::Engine
    LICENSE_URL = "https://www.shakacode.com/react-on-rails-pro/"
    LEGACY_LICENSE_FILE = "config/react_on_rails_pro_license.key"
    private_constant :LICENSE_URL
    private_constant :LEGACY_LICENSE_FILE

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
          log_valid_license
        when :missing
          log_legacy_license_migration_notice if legacy_license_file_present?
          log_license_issue("No license found", "Get a license at #{LICENSE_URL}")
        when :expired
          expiration = ReactOnRailsPro::LicenseValidator.license_expiration
          expired_on = expiration ? " (expired on #{expiration.strftime('%Y-%m-%d')})" : ""
          log_license_issue("License has expired#{expired_on}", "Renew your license at #{LICENSE_URL}")
        when :invalid
          log_license_issue("Invalid license", "Get a license at #{LICENSE_URL}")
        end
      end

      private

      def log_valid_license
        org = ReactOnRailsPro::LicenseValidator.license_organization
        plan = ReactOnRailsPro::LicenseValidator.license_plan
        attribution_required = ReactOnRailsPro::LicenseValidator.attribution_required?

        # Build license details string
        details = [org, plan_display_name(plan)].compact.join(" - ")

        message = "[React on Rails Pro] License validated successfully"
        message += " (#{details})" if details.present?
        message += "."

        message += " Attribution required for this license type." if attribution_required

        Rails.logger.info message
      end

      def plan_display_name(plan)
        return nil unless plan

        case plan
        when "paid" then nil # Don't show "paid" - it's the default
        when "partner" then "partner license"
        when "startup" then "startup license"
        when "oss" then "open source license"
        when "nonprofit" then "nonprofit license"
        when "education" then "education license"
        else plan
        end
      end

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

      def legacy_license_file_present?
        Rails.root.join(LEGACY_LICENSE_FILE).exist?
      end

      def log_legacy_license_migration_notice
        message = "[React on Rails Pro] Detected legacy license file at #{LEGACY_LICENSE_FILE}, " \
                  "but this file is no longer read. " \
                  "Move your token to REACT_ON_RAILS_PRO_LICENSE."

        if Rails.env.production?
          Rails.logger.warn message
        else
          Rails.logger.info message
        end
      end
    end
  end
end
