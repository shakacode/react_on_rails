require "rails/generators"

module ReactOnRails
  module Generators
    class LintersGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      def add_linter_gems
        linter_gems = <<-GEMS

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

      def copy_linter_config_files
        base_path = "linters/"
        %w(client/.eslintrc
           client/.eslintignore
           client/.jscsrc).each { |file| copy_file(base_path + file, file) }
      end

      def copy_linting_and_audting_tasks
        base_path = "linters/"
        %w(lib/tasks/brakeman.rake
           lib/tasks/ci.rake
           lib/tasks/linters.rake).each { |file| copy_file(base_path + file, file) }
      end
    end
  end
end
