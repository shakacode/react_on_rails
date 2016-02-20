require 'readline'

module Tins
  module Complete
    module_function

    @@sync = Sync.new

    def complete(prompt: '', add_hist: false, &block)
      @@sync.synchronize do
        Readline.completion_proc = block
        Readline.input           = STDIN
        Readline.output          = STDOUT
        Readline.readline(prompt, add_hist)
      end
    end
  end
end
