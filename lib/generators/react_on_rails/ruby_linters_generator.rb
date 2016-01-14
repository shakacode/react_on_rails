require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class RubyLintersGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root File.expand_path("../templates", __FILE__)

      def add_ruby_linter_gems_to_gemfile
        linter_gems = <<-GEMS.strip_heredoc

          # require: false is necessary for the linters as we only want them loaded
          # when used by the linting rake tasks.
          group :development do
            gem("rubocop", require: false)
            gem("ruby-lint", require: false)
            gem("scss_lint", require: false)
          end
        GEMS
        append_to_file("Gemfile", linter_gems)
      end

      def copy_ruby_linting_and_auditing_tasks
        base_path = "ruby_linters/"
        %w(lib/tasks/brakeman.rake
           lib/tasks/ci.rake
           .rubocop.yml
           .scss-lint.yml).each { |file| copy_file(base_path + file, file) }
        template("ruby_linters/ruby-lint.yml.tt", "ruby-lint.yml")
      end
    end
  end
end
