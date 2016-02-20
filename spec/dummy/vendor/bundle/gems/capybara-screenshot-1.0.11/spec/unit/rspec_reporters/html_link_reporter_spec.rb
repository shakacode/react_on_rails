require 'spec_helper'

describe Capybara::Screenshot::RSpec::HtmlLinkReporter do
  include_context 'html reporter'

  context 'when a html file was saved' do
    before do
      set_example double("example", metadata: {screenshot: {html: "path/to/a html file"}})
    end

    it 'appends a link to the html to the original content' do
      content_without_styles = @reporter.extra_failure_content(nil).gsub(/ ?style=".*?" ?/, "")
      expect(content_without_styles).to eql(%{original content<p>Saved files: <a href="file://path/to/a%20html%20file">HTML page</a></p>})
    end
  end

  context 'when a html file and an image were saved' do
    before do
      set_example double("example", metadata: {screenshot: {html: "path/to/html", image: "path/to/an image"}})
    end

    it 'appends links to both files to the original content' do
      content_without_styles = @reporter.extra_failure_content(nil).gsub(/ ?style=".*?" ?/, "")
      expect(content_without_styles).to eql(%{original content<p>Saved files: <a href="file://path/to/html">HTML page</a><a href="file://path/to/an%20image">Screenshot</a></p>})
    end
  end
end
