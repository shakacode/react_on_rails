#
# Main Container for all of Byebug's code
#
module Byebug
  #
  # Enters byebug right before (or right after if _before_ is false) return
  # events occur. Before entering byebug the init script is read.
  #
  def self.attach
    require 'byebug/core'

    unless started?
      self.mode = :attached

      start
      run_init_script
    end

    current_context.step_out(3, true)
  end
end

#
# Adds a `byebug` method to the Kernel module.
#
# Dropping a `byebug` call anywhere in your code, you get a debug prompt.
#
module Kernel
  def byebug
    Byebug.attach
  end

  alias_method :debugger, :byebug
end
