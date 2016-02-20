require 'capybara-screenshot/rspec/base_reporter'
require 'capybara-screenshot/helpers'

module Capybara
  module Screenshot
    module RSpec
      module TextReporter
        extend BaseReporter

        if ::RSpec::Core::Version::STRING.to_i <= 2
          enhance_with_screenshot :dump_failure_info
        else
          enhance_with_screenshot :example_failed
        end

        def dump_failure_info_with_screenshot(example)
          dump_failure_info_without_screenshot example
          output_screenshot_info(example)
        end

        def example_failed_with_screenshot(notification)
          example_failed_without_screenshot notification
          output_screenshot_info(notification.example)
        end

        private
        def output_screenshot_info(example)
          return unless (screenshot = example.metadata[:screenshot])
          output.puts(long_padding + CapybaraScreenshot::Helpers.yellow("HTML screenshot: file://#{screenshot[:html]}")) if screenshot[:html]
          output.puts(long_padding + CapybaraScreenshot::Helpers.yellow("Image screenshot: file://#{screenshot[:image]}")) if screenshot[:image]
        end

        def long_padding
          "  "
        end
      end
    end
  end
end
