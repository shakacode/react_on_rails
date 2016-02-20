require "capybara-screenshot"

require "capybara-screenshot/rspec/text_reporter"
require "capybara-screenshot/rspec/html_link_reporter"
require "capybara-screenshot/rspec/html_embed_reporter"
require "capybara-screenshot/rspec/textmate_link_reporter"

module Capybara
  module Screenshot
    module RSpec

      # Reporters extend RSpec formatters to display information about screenshots for failed
      # examples.
      #
      # Technically, a reporter is a module that gets injected into a RSpec formatter class.
      # It uses method aliasing to extend some (usually just one) of the formatter's methods.
      #
      # Implementing a custom reporter is as simple as creating a module and setting up the
      # appropriate aliases. Use `BaseReporter.enhance_with_screenshot` if you don't want
      # to set up the aliases manually:
      #
      #   module MyReporter
      #     extend Capybara::Screenshot::RSpec::BaseReporter
      #
      #     # Will replace the formatter's original `dump_failure_info` method with
      #     # `dump_failure_info_with_screenshot` from this module:
      #     enhance_with_screenshot :dump_failure_info
      #
      #     def dump_failure_info_with_screenshot(example)
      #       dump_failure_info_without_screenshot(example) # call original implementation
      #       ... # your additions here
      #     end
      #   end
      #
      # Finally customize `Capybara::Screenshot::RSpec::FORMATTERS` to make sure your reporter
      # gets injected into the appropriate formatter.

      REPORTERS = {
        "RSpec::Core::Formatters::ProgressFormatter"      => Capybara::Screenshot::RSpec::TextReporter,
        "RSpec::Core::Formatters::DocumentationFormatter" => Capybara::Screenshot::RSpec::TextReporter,
        "RSpec::Core::Formatters::HtmlFormatter"          => Capybara::Screenshot::RSpec::HtmlLinkReporter,
        "RSpec::Core::Formatters::TextMateFormatter"      => Capybara::Screenshot::RSpec::TextMateLinkReporter, # RSpec 2
        "RSpec::Mate::Formatters::TextMateFormatter"      => Capybara::Screenshot::RSpec::TextMateLinkReporter,  # RSpec 3
        "Fuubar"                                          => Capybara::Screenshot::RSpec::TextReporter
      }

      class << self
        attr_accessor :add_link_to_screenshot_for_failed_examples

        def after_failed_example(example)
          if example.example_group.include?(Capybara::DSL) # Capybara DSL method has been included for a feature we can snapshot
            Capybara.using_session(Capybara::Screenshot.final_session_name) do
              if Capybara.page.current_url != '' && Capybara::Screenshot.autosave_on_failure && example.exception
                filename_prefix = Capybara::Screenshot.filename_prefix_for(:rspec, example)

                saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, true, filename_prefix)
                saver.save

                example.metadata[:screenshot] = {}
                example.metadata[:screenshot][:html]  = saver.html_path if saver.html_saved?
                example.metadata[:screenshot][:image] = saver.screenshot_path if saver.screenshot_saved?
              end
            end
          end
        end
      end

      self.add_link_to_screenshot_for_failed_examples = true
    end
  end
end

RSpec.configure do |config|
  config.before do
    Capybara::Screenshot.final_session_name = nil
  end

  config.after do |example_from_block_arg|
    # RSpec 3 no longer defines `example`, but passes the example as block argument instead
    example = config.respond_to?(:expose_current_running_example_as) ? example_from_block_arg : self.example

    Capybara::Screenshot::RSpec.after_failed_example(example)
  end

  config.before(:suite) do
    if Capybara::Screenshot::RSpec.add_link_to_screenshot_for_failed_examples
      RSpec.configuration.formatters.each do |formatter|
        next unless (reporter_module = Capybara::Screenshot::RSpec::REPORTERS[formatter.class.to_s])
        formatter.singleton_class.send :include, reporter_module
      end
    end
  end
end
