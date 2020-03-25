# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:each, :js) do |example|
    next unless %i[selenium_chrome selenium_chrome_headless].include?(Capybara.current_driver)

    # As of 2018-10-21, traping errors does not work for firefox

    log_only_list = %w[DEBUG INFO]
    log_only_list += %w[WARNING SEVERE ERROR] if example.metadata[:ignore_js_errors]

    errors = []

    page.driver.browser.manage.logs.get(:browser).each do |entry|
      # can't use match? on Ruby 2.2. Uncomment when Ruby 2.4 is used for all test platforms
      # next if entry.message.match?(/Download the React DevTools for a better development experience/)
      next if entry.message =~ /Download the React DevTools for a better development experience/

      log_only_list.include?(entry.level) ? puts(entry.message) : errors << entry.message
    end

    page.driver.browser.manage.logs.get(:driver).each do |entry|
      log_only_list.include?(entry.level) ? puts(entry.message) : errors << entry.message
    end

    # https://stackoverflow.com/questions/60114639/timed-out-receiving-message-from-renderer-0-100-log-messages-using-chromedriver
    clean_errors = errors.reject { |err_msg| err_msg.include?("Timed out receiving message from renderer: 0.100") }

    raise("Java Script Error(s) on the page:\n\n" + errors.join("\n")) if clean_errors.present?
  end
end
