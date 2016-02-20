require 'capybara-screenshot/rspec/base_reporter'
require 'cgi'
require 'uri'

module Capybara
  module Screenshot
    module RSpec
      module HtmlLinkReporter
        extend BaseReporter
        enhance_with_screenshot :extra_failure_content

        def extra_failure_content_with_screenshot(exception)
          result  = extra_failure_content_without_screenshot(exception)
          example = @failed_examples.last
          if (screenshot = example.metadata[:screenshot])
            result << "<p>Saved files: "
            result << link_to_screenshot("HTML page",  screenshot[:html]) if screenshot[:html]
            result << link_to_screenshot("Screenshot", screenshot[:image]) if screenshot[:image]
            result << "</p>"
          end
          result
        end

        def link_to_screenshot(title, path)
          url = URI.escape("file://#{path}")
          title = CGI.escape_html(title)
          attributes = attributes_for_screenshot_link(url).map { |name, val| %{#{name}="#{CGI.escape_html(val)}"} }.join(" ")
          "<a #{attributes}>#{title}</a>"
        end

        def attributes_for_screenshot_link(url)
          {"href" => url, "style" => "margin-right: 10px; font-weight: bold"}
        end
      end
    end
  end
end
