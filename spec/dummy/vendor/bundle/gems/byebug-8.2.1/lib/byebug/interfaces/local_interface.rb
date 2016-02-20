module Byebug
  #
  # Interface class for standard byebug use.
  #
  class LocalInterface < Interface
    EOF_ALIAS = 'continue'

    def initialize
      super()
      @input = STDIN
      @output = STDOUT
      @error = STDERR
    end

    #
    # Reads a single line of input using Readline. If Ctrl-C is pressed in the
    # middle of input, the line is reset to only the prompt and we ask for input
    # again. If Ctrl-D is pressed, it returns "continue".
    #
    # @param prompt Prompt to be displayed.
    #
    def readline(prompt)
      Readline.readline(prompt, false) || EOF_ALIAS
    rescue Interrupt
      puts('^C')
      retry
    end
  end
end
