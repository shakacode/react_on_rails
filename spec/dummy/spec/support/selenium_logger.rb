# frozen_string_literal: true

RSpec.configure do |config|
  # TODO: remove next line and fix JS errors
  ENV["SKIP_JS_ERRORS"] = "YES"
  config.after(:each, :js) do |example|
    next unless %i[selenium_chrome selenium_chrome_headless].include?(Capybara.current_driver) &&
                ENV["SKIP_JS_ERRORS"].blank?

    # As of 2018-10-21, traping errors does not work for firefox

    log_only_list = %w[DEBUG INFO]
    log_only_list += %w[WARNING SEVERE ERROR] if example.metadata[:ignore_js_errors]

    errors = []

    page.driver.browser.manage.logs.get(:browser).each do |entry|
      next if entry.message.inlcude?(/Download the React DevTools for a better development experience/)

      log_only_list.include?(entry.level) ? puts(entry.message) : errors << entry.message
    end

    page.driver.browser.manage.logs.get(:driver).each do |entry|
      log_only_list.include?(entry.level) ? puts(entry.message) : errors << entry.message
    end

    # https://stackoverflow.com/questions/60114639/timed-out-receiving-message-from-renderer-0-100-log-messages-using-chromedriver
    cleaned_errors = errors.reject { |err_msg| err_msg.include?("Timed out receiving message from renderer: 0.100") }

    raise("Java Script Error(s) on the page:\n\n#{errors.join("\n")}") if cleaned_errors.present?
  end
end
