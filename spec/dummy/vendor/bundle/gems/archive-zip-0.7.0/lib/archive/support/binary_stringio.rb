# encoding: UTF-8

require 'stringio'

# This class is a version of StringIO that always uses the binary encoding on
# any Ruby platform that has a notion of encodings.  On Ruby platforms without
# encoding support, this class is equivalent to StringIO.
class BinaryStringIO < StringIO
  # Creates a new instance of this class.
  #
  # This takes all the arguments of StringIO.new.
  def initialize(*args)
    super

    # Force a binary encoding when possible.
    if respond_to?(:set_encoding, true)
      @encoding_locked = false
      set_encoding('binary')
    end
  end

  if instance_methods.include?(:set_encoding)
    # Raise an exception on attempts to change the encoding.
    def set_encoding(*args)
      raise 'Changing encoding is not allowed' if @encoding_locked
      @encoding_locked = true
      super
    end
  end
end
