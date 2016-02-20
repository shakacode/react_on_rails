require 'capybara-screenshot/rspec/base_reporter'
require 'base64'

module Capybara
  module Screenshot
    module RSpec
      module HtmlEmbedReporter
        extend BaseReporter
        enhance_with_screenshot :extra_failure_content

        def extra_failure_content_with_screenshot(exception)
          result  = extra_failure_content_without_screenshot(exception)
          example = @failed_examples.last
          # Ignores saved html file, only saved image will be embedded (if present)
          if (screenshot = example.metadata[:screenshot]) && screenshot[:image]
            image = File.binread(screenshot[:image])
            encoded_img = Base64.encode64(image)
            result += "<img src='data:image/png;base64,#{encoded_img}' style='display: block'>"
          end
          result
        end
      end
    end
  end
end
