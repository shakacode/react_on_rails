# frozen_string_literal: true

module DriverRegistration
  def self.register_selenium_chrome
    return if @selenium_chrome_registered

    Capybara.register_driver :selenium_chrome do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome)
    end
    Capybara::Screenshot.register_driver(:selenium_chrome) do |js_driver, path|
      js_driver.browser.save_screenshot(path)
    end
    @selenium_chrome_registered = true
  end

  def self.register_selenium_firefox
    return if @selenium_firefox_registered

    Capybara.register_driver :selenium_firefox do |app|
      Capybara::Selenium::Driver.new(app, browser: :firefox)
    end
    Capybara::Screenshot.register_driver(:selenium_firefox) do |js_driver, path|
      js_driver.browser.save_screenshot(path)
    end
    @selenium_firefox_registered = true
  end

  def self.register_selenium_headless
    return if @selenium_headless_registered

    Capybara.register_driver :selenium_chrome_headless do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless")
      options.add_argument("--disable-gpu")
      Capybara::Selenium::Driver.new app, browser: :chrome, options: options
    end
    Capybara::Screenshot.register_driver(:selenium_chrome_headless) do |js_driver, path|
      js_driver.browser.save_screenshot(path)
    end
    @selenium_headless_registered = true
  end
end
