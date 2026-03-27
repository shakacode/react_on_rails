# frozen_string_literal: true

require "yard"
require "commonmarker"

class GithubMarkdown
  attr_reader :to_html

  def initialize(text)
    @to_html = CommonMarker.render_html(text)
  end
end

YARD::Rake::YardocTask.new do |t|
  helper = YARD::Templates::Helpers::MarkupHelper
  helper.clear_markup_cache
  helper::MARKUP_PROVIDERS[:markdown].unshift const: "GithubMarkdown"
  t.files = %w[lib/react_on_rails_pro/utils.rb app/helpers/react_on_rails_pro_helper.rb]
  t.options = ["-o", "gen-documentation", "-r", "README.md"]
end
