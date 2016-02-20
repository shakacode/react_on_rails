# encoding: UTF-8

class Integer
  unless public_method_defined?('ord') then
    # Returns the int itself.
    #
    # This method is defined here only if not already defined elsewhere, such as
    # versions of Ruby prior to 1.8.7.
    def ord
      self
    end
  end
end
