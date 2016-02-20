require 'jbuilder/jbuilder'

class Jbuilder
  class NullError < ::NoMethodError
    def self.build(key)
      message = "Failed to add #{key.to_s.inspect} property to null object"
      new(message)
    end
  end

  class ArrayError < ::StandardError
    def self.build(key)
      message = "Failed to add #{key.to_s.inspect} property to an array"
      new(message)
    end
  end
end
