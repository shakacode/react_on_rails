require "capybara-screenshot"

Spinach.hooks.before_scenario do |scenario|
  Capybara::Screenshot.final_session_name = nil
end

module Capybara::Screenshot::Spinach
  def self.fail_with_screenshot(step_data, exception, location, step_definitions)
    if Capybara::Screenshot.autosave_on_failure
      Capybara.using_session(Capybara::Screenshot.final_session_name) do
        filename_prefix = Capybara::Screenshot.filename_prefix_for(:spinach, step_data)
        saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, true, filename_prefix)
        saver.save
        saver.output_screenshot_path
      end
    end
  end
end

Spinach.hooks.on_failed_step do |*args|
  Capybara::Screenshot::Spinach.fail_with_screenshot(*args)
end

Spinach.hooks.on_error_step do |*args|
  Capybara::Screenshot::Spinach.fail_with_screenshot(*args)
end
