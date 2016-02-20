class PryRescue
  def self.peek_on_signal signal
    trap signal, &method(:peek!)
  end

  # Called when rescue --peek is used and the user hits <Ctrl+C>
  # or sends whichever signal is configured.
  def self.peek!(*)
    puts 'Preparing to peek via pry!' unless ENV['NO_PEEK_STARTUP_MESSAGE']
    require 'pry'
    unless binding.respond_to?(:of_caller)
      raise "pry-stack_explorer is not installed"
    end
    throw :raise_up, Interrupt if Pry === binding.of_caller(1).eval('self')
    binding.of_caller(1).pry
    # TODO pry :call_stack => binding.of_callers, :initial_frame => 1
  end
end
