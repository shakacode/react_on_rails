#
# Main container module for Pry-Byebug functionality
#
module PryByebug
  #
  # Checks that a target binding is in a local file context.
  #
  def file_context?(target)
    file = target.eval('__FILE__')
    file == Pry.eval_path || !Pry::Helpers::BaseHelpers.not_a_real_file?(file)
  end
  module_function :file_context?

  #
  # Ensures that a command is executed in a local file context.
  #
  def check_file_context(target, e = nil)
    e ||= 'Cannot find local context. Did you use `binding.pry`?'
    fail(Pry::CommandError, e) unless file_context?(target)
  end
  module_function :check_file_context

  # Reference to currently running pry-remote server. Used by the processor.
  attr_accessor :current_remote_server
end
