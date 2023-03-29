# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:each, :js) do |_example|
    next unless %i[selenium_chrome selenium_chrome_headless].include?(Capybara.current_driver)

    errors = []

    non_error_levels = %w[DEBUG INFO WARNING]

    page.driver.browser.logs.get(:browser).each do |entry|
      pretty_message = if entry.message.match?(%r{http://(127.0.0.1|app.lvh.me)[^ ]+ [\d:]+ })
                         entry.message[/[^ ]+ [^ ]+ (.*)$/, 1]&.gsub(/\A"|"\Z/, "")&.gsub(/\\n/, "\n")
                       else
                         entry.message
                       end

      non_error_levels.include?(entry.level) ? puts(pretty_message) : errors << pretty_message
    end

    page.driver.browser.logs.get(:driver).each do |entry|
      non_error_levels.include?(entry.level) ? puts(entry.message) : errors << entry.message
    end

    clean_errors = errors.reject do |err_msg|
      err_msg.include?("Timed out receiving message from renderer: 0.100") ||
        err_msg.include?("SharedArrayBuffer will require cross-origin isolation") ||
        err_msg.include?("You are currently using minified code outside of NODE_ENV === \\\"production\\\"")
    end

    raise("Java Script Error(s) on the page:\n\n#{errors.join('\n')}") if clean_errors.present?
  end
end
