require 'rails/engine'

module Coffee
  module Rails
    class Engine < ::Rails::Engine
      config.app_generators.javascript_engine :coffee

      if config.respond_to?(:annotations)
        config.annotations.register_extensions("coffee") { |annotation| /#\s*(#{annotation}):?\s*(.*)$/ }
      end
    end
  end
end
