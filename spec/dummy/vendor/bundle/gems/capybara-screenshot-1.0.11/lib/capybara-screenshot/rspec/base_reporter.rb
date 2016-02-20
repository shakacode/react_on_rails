module Capybara
  module Screenshot
    module RSpec
      module BaseReporter

        # Automatically set up method aliases (very much like ActiveSupport's `alias_method_chain`) 
        # when the module gets included.
        def enhance_with_screenshot(method)
          with_method, without_method = "#{method}_with_screenshot", "#{method}_without_screenshot"
          define_singleton_method :included do |mod|
            if mod.method_defined?(method) || mod.private_method_defined?(method)
              mod.send :alias_method, without_method, method
              mod.send :alias_method, method, with_method
            end
          end
        end

      end
    end
  end
end
