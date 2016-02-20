# pry-stack_explorer.rb
# (C) John Mair (banisterfiend); MIT license

require "pry-stack_explorer/version"
require "pry-stack_explorer/commands"
require "pry-stack_explorer/frame_manager"
require "pry-stack_explorer/when_started_hook"
require "binding_of_caller"

module PryStackExplorer

  # short-hand for `PryStackExplorer`
  ::SE = self

  class << self
    # @return [Hash] The hash storing all frames for all Pry instances for
    #   the current thread.
    def frame_hash
      Thread.current[:__pry_frame_managers__] ||= Hash.new { |h, k| h[k] = [] }
    end

    # Return the complete frame manager stack for the Pry instance
    # @param [Pry] _pry_ The Pry instance associated with the frame
    #   managers
    # @return [Array] The stack of Pry::FrameManager objections
    def frame_managers(_pry_)
      frame_hash[_pry_]
    end

    # Create a `Pry::FrameManager` object and push it onto the frame
    # manager stack for the relevant `_pry_` instance.
    # @param [Array] bindings The array of bindings (frames)
    # @param [Pry] _pry_ The Pry instance associated with the frame manager
    def create_and_push_frame_manager(bindings, _pry_, options={})
      fm = FrameManager.new(bindings, _pry_)
      frame_hash[_pry_].push fm
      push_helper(fm, options)
      fm
    end

    # Update the Pry instance to operate on the specified frame for the
    # current frame manager.
    # @param [PryStackExplorer::FrameManager] fm The active frame manager.
    # @param [Hash] options The options hash.
    def push_helper(fm, options={})
      options = {
        :initial_frame => 0
      }.merge!(options)

      fm.change_frame_to(options[:initial_frame], false)
    end

    private :push_helper

    # Delete the currently active frame manager
    # @param [Pry] _pry_ The Pry instance associated with the frame
    #   managers.
    # @return [Pry::FrameManager] The popped frame manager.
    def pop_frame_manager(_pry_)
      return if frame_managers(_pry_).empty?

      popped_fm = frame_managers(_pry_).pop
      pop_helper(popped_fm, _pry_)
      popped_fm
    end

    # Restore the Pry instance to operate on the previous
    # binding. Also responsible for restoring Pry instance's backtrace.
    # @param [Pry::FrameManager] popped_fm The recently popped frame manager.
    # @param [Pry] _pry_ The Pry instance associated with the frame managers.
    def pop_helper(popped_fm, _pry_)
      if frame_managers(_pry_).empty?
        if _pry_.binding_stack.empty?
          _pry_.binding_stack.push popped_fm.prior_binding
        else
          _pry_.binding_stack[-1] = popped_fm.prior_binding
        end

        frame_hash.delete(_pry_)
      else
        frame_manager(_pry_).refresh_frame(false)
      end

      # restore backtrace
      _pry_.backtrace = popped_fm.prior_backtrace
    end

    private :pop_helper

    # Clear the stack of frame managers for the Pry instance
    # @param [Pry] _pry_ The Pry instance associated with the frame managers
    def clear_frame_managers(_pry_)
      pop_frame_manager(_pry_) until frame_managers(_pry_).empty?
      frame_hash.delete(_pry_) # this line should be unnecessary!
    end

    alias_method :delete_frame_managers, :clear_frame_managers

    # @return [PryStackExplorer::FrameManager] The currently active frame manager
    def frame_manager(_pry_)
      frame_hash[_pry_].last
    end

    # Simple test to check whether two `Binding` objects are equal.
    # @param [Binding] b1 First binding.
    # @param [Binding] b2 Second binding.
    # @return [Boolean] Whether the `Binding`s are equal.
    def bindings_equal?(b1, b2)
      (b1.eval('self').equal?(b2.eval('self'))) &&
        (b1.eval('__method__') == b2.eval('__method__')) &&
        (b1.eval('local_variables').map { |v| b1.eval("#{v}") }.equal?(
         b2.eval('local_variables').map { |v| b2.eval("#{v}") }))
    end
  end
end

Pry.config.hooks.add_hook(:after_session, :delete_frame_manager) do |_, _, _pry_|
  PryStackExplorer.clear_frame_managers(_pry_)
end

Pry.config.hooks.add_hook(:when_started, :save_caller_bindings, PryStackExplorer::WhenStartedHook.new)

# Import the StackExplorer commands
Pry.config.commands.import PryStackExplorer::Commands

# monkey-patch the whereami command to show some frame information,
# useful for navigating stack.
Pry.config.commands.before_command("whereami") do |num|
  if PryStackExplorer.frame_manager(_pry_) && !internal_binding?(target)
    bindings      = PryStackExplorer.frame_manager(_pry_).bindings
    binding_index = PryStackExplorer.frame_manager(_pry_).binding_index

    output.puts "\n"
    output.puts "#{Pry::Helpers::Text.bold('Frame number:')} #{binding_index}/#{bindings.size - 1}"
    output.puts "#{Pry::Helpers::Text.bold('Frame type:')} #{bindings[binding_index].frame_type}" if bindings[binding_index].frame_type
  end
end
