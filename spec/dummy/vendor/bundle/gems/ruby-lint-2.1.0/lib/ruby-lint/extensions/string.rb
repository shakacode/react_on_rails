class String
  unless method_defined?(:snake_case)
    ##
    # Creates a new string that is `snake_cased`.
    #
    # @example
    #  "FooBar".snake_case # => "foo_bar"
    #
    # @return [String]
    #
    def snake_case
      return self.gsub(/([a-z])([A-Z])/, '\\1_\\2').gsub('::', '_').downcase
    end
  end
end # String
