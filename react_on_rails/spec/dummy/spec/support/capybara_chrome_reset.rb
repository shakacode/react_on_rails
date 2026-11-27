# frozen_string_literal: true

# Capybara 3.40.0 ends Selenium ChromeDriver#reset! with
#   execute_cdp("Storage.clearDataForOrigin", origin: "*", storageTypes: "cookies,local_storage")
# Chrome 158 rejects that origin with "invalid argument: * is not a valid URL", so every
# example that resets the session errors after it runs and leaves its cookies behind.
# Upstream: https://github.com/teamcapybara/capybara/issues/2865
#
# When Chrome rejects the wildcard, clear every cookie and the localStorage of each origin
# in the tab's history instead. Older Chrome still takes the original call.
# Delete this file once the dummy app uses a Capybara release that fixes reset! on Chrome 158.
# The OSS and Pro dummy apps each keep an identical copy of this patch; change both together.
require "capybara/selenium/driver"

if Gem::Version.new(Capybara::VERSION) <= Gem::Version.new("3.40.0")
  module CapybaraChromeResetWithoutWildcardOrigin
    private

    def execute_cdp(cmd, params = {})
      super
    rescue Selenium::WebDriver::Error::InvalidArgumentError => e
      raise unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*" &&
                   e.message.include?("is not a valid URL")

      storage_types = params[:storageTypes].to_s.split(",")
      super("Network.clearBrowserCookies") if storage_types.include?("cookies")
      return unless storage_types.include?("local_storage")

      visited_origins.each do |origin|
        super("Storage.clearDataForOrigin", { origin:, storageTypes: "local_storage" })
      end
    end

    def visited_origins
      execute_cdp("Page.getNavigationHistory").fetch("entries", []).filter_map { |entry| origin_of(entry["url"]) }.uniq
    end

    def origin_of(url)
      uri = URI.parse(url.to_s)
      return unless %w[http https].include?(uri.scheme) && uri.host

      port = ":#{uri.port}" unless uri.port == uri.default_port
      "#{uri.scheme}://#{uri.host}#{port}"
    rescue URI::InvalidURIError
      nil
    end
  end

  Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeResetWithoutWildcardOrigin)
end
