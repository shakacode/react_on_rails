require 'irb'

module Tins
  IRB = ::IRB

  module ::IRB
    def self.examine(binding = TOPLEVEL_BINDING)
      setup nil
      workspace = WorkSpace.new binding
      irb = Irb.new workspace
      @CONF[:MAIN_CONTEXT] = irb.context
      catch(:IRB_EXIT) { irb.eval_input }
    rescue Interrupt
      exit
    end
  end

  class ::Object
    def examine(binding = TOPLEVEL_BINDING)
      IRB.examine(binding)
    end
  end
end
