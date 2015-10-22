require "rails/generators"

module ReactOnRails
  module Generators
    class ReactAndReduxGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      def create_react_and_redux_directories
        dirs = %w(actions components constants middlewares
                  startup utils reducers stores)
        dirs.each do |name|
          empty_directory "client/app/#{name}"
        end
      end

      def copy_react_and_redux_package_json
        copy_file "client/redux_package.json", "client/package.json"
      end
    end
  end
end
