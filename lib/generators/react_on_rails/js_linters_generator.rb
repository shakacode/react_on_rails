require "rails/generators"

module ReactOnRails
  module Generators
    class JsLintersGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      # NOTE: linter modules are included via template in base/base/client/package.json.tt

      def copy_js_linter_config_files
        base_path = "js_linters/"
        %w(client/.eslintrc
           client/.eslintignore
           client/.jscsrc).each { |file| copy_file(base_path + file, file) }
      end
    end
  end
end
