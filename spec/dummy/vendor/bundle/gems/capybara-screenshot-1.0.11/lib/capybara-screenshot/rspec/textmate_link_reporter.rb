require 'capybara-screenshot/rspec/base_reporter'
require 'capybara-screenshot/rspec/html_link_reporter'
require 'shellwords'

module Capybara
  module Screenshot
    module RSpec
      module TextMateLinkReporter
        extend BaseReporter
        include HtmlLinkReporter
        enhance_with_screenshot :extra_failure_content

        def attributes_for_screenshot_link(url)
          super.merge("onclick" => "TextMate.system('open #{Shellwords.escape(url)}'); return false;")
        end
      end
    end
  end
end
