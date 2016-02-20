require 'spec_helper'

describe Capybara::Screenshot::RSpec::TextMateLinkReporter do
  include_context 'html reporter'

  context 'when a html file was saved' do
    before do
      set_example double("example", metadata: {screenshot: {html: "path/to/a html file"}})
    end

    it 'appends a link to the html to the original content' do
      content_without_styles = @reporter.extra_failure_content(nil).gsub(/ ?style=".*?"/, "")
      # Single quotes are handled differently by CGI.escape_html in Ruby 1.9 / Ruby 2, so to be
      # compatible with both versions we can't hard code the final escaped string.
      expected_onclick_handler = CGI.escape_html("TextMate.system('open file://path/to/a\\%20html\\%20file'); return false;")
      expect(content_without_styles).to eql(%{original content<p>} +
        %{Saved files: <a href="file://path/to/a%20html%20file" onclick="#{expected_onclick_handler}">HTML page</a></p>}
      )
    end
  end

  context 'when a html file and an image were saved' do
    before do
      set_example double("example", metadata: {screenshot: {html: "path/to/html", image: "path/to/an image"}})
    end

    it 'appends links to both files to the original content' do
      content_without_styles = @reporter.extra_failure_content(nil).gsub(/ ?style=".*?"/, "")
      # Single quotes are handled differently by CGI.escape_html in Ruby 1.9 / Ruby 2, so to be
      # compatible with both versions we can't hard code the final escaped string.
      expected_onclick_handler_1 = CGI.escape_html("TextMate.system('open file://path/to/html'); return false;")
      expected_onclick_handler_2 = CGI.escape_html("TextMate.system('open file://path/to/an\\%20image'); return false;")
      expect(content_without_styles).to eql(%{original content<p>} +
        %{Saved files: <a href="file://path/to/html" onclick="#{expected_onclick_handler_1}">HTML page</a>} +
        %{<a href="file://path/to/an%20image" onclick="#{expected_onclick_handler_2}">Screenshot</a></p>}
      )
    end
  end
end
