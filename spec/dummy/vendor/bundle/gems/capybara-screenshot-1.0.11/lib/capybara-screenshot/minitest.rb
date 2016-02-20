require "capybara-screenshot"

module Capybara::Screenshot::MiniTestPlugin
  def before_setup
    super
    Capybara::Screenshot.final_session_name = nil
  end

  def after_teardown
    super
    if self.class.ancestors.map(&:to_s).include?('ActionDispatch::IntegrationTest')
      if Capybara::Screenshot.autosave_on_failure && !passed?
        Capybara.using_session(Capybara::Screenshot.final_session_name) do
          filename_prefix = Capybara::Screenshot.filename_prefix_for(:minitest, self)

          saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, true, filename_prefix)
          saver.save
          saver.output_screenshot_path
        end
      end
    end
  end
end

class MiniTest::Unit::TestCase
  include Capybara::Screenshot::MiniTestPlugin
end
