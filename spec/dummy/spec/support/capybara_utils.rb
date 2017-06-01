# frozen_string_literal: true

module CapybaraUtils
  # Sets the driver header for poltergeist and webkit.
  # Selenium is not feasible.
  def set_driver_header(key, value)
    case Capybara.javascript_driver
    when :poltergeist, :poltergeist_errors_ok
      page.driver.headers = { key => value }
      # Skip webkit for now due to install trouble on Sierra
      # when :webkit
      #   page.driver.header(key, value)
      #   # else no possibe action for selenium
    end
  end
end
