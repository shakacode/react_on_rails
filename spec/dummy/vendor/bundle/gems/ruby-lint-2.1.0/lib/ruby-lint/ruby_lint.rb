module RubyLint
  ##
  # Returns the global registry instance used for registering and applying
  # definitions.
  #
  # @return [RubyLint::Definition::Registry]
  #
  def self.registry
    return @registry ||= Definition::Registry.new
  end
end # RubyLint
