require "rails/generators"

module ReactOnRails
  module Generators
    class NodeGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      def create_node_directory
        empty_directory("client/node")
      end

      def copy_base_redux_files
        base_path = "node/base/"
        %w(client/node/server.js
           client/node/package.json).each do |file|
             copy_file(base_path + file, file)
           end
      end
    end
  end
end
