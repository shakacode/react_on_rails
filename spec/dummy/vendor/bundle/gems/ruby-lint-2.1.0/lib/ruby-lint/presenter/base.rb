module RubyLint
  module Presenter
    ##
    # Base presenter class that provides some commonly used methods.
    #
    class Base
      ##
      # Registers the presenter in
      # {RubyLint::Configuration.available_presenters}.
      #
      # @param [String] name
      #
      def self.register(name)
        Configuration.available_presenters[name] = self
      end
    end # Base
  end # Presenter
end # RubyLint
