require 'tins/write'

module Tins
  #class ::Object
  #  include Tins::Write
  #end

  class ::IO
    extend Tins::Write
  end
end
