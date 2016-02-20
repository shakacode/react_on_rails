require 'tins/secure_write'

module Tins
  #class ::Object
  #  include Tins::SecureWrite
  #end

  class ::IO
    extend Tins::SecureWrite
  end
end
