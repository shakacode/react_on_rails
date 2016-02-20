module PryStackExplorer
  class WhenStartedHook
    include Pry::Helpers::BaseHelpers

    def caller_bindings(target)
      bindings = binding.callers

      bindings = remove_internal_frames(bindings)
      bindings = remove_debugger_frames(bindings)
      bindings = bindings.drop(1) if pry_method_frame?(bindings.first)

      # Use the binding returned by #of_caller if possible (as we get
      # access to frame_type).
      # Otherwise stick to the given binding (target).
      if !PryStackExplorer.bindings_equal?(target, bindings.first)
        bindings.shift
        bindings.unshift(target)
      end

      bindings
    end

    def call(target, options, _pry_)
      target ||= _pry_.binding_stack.first if _pry_
      options = {
        :call_stack    => true,
        :initial_frame => 0
      }.merge!(options)

      return if !options[:call_stack]

      if options[:call_stack].is_a?(Array)
        bindings = options[:call_stack]

        if !valid_call_stack?(bindings)
          raise ArgumentError, ":call_stack must be an array of bindings"
        end
      else
        bindings = caller_bindings(target)
      end

      PryStackExplorer.create_and_push_frame_manager bindings, _pry_, :initial_frame => options[:initial_frame]
    end

    private

    # remove internal frames related to setting up the session
    def remove_internal_frames(bindings)
      start_frames = internal_frames_with_indices(bindings)
      start_frame_index = start_frames.first.last

      if start_frames.size >= 2
        # god knows what's going on in here
        idx1, idx2 = start_frames.take(2).map(&:last)
        start_frame_index = idx2 if !nested_session?(bindings[idx1..idx2])
      end

      bindings.drop(start_frame_index + 1)
    end

    # remove pry-nav / pry-debugger / pry-byebug frames
    def remove_debugger_frames(bindings)
      bindings.drop_while { |b| b.eval("__FILE__") =~ /pry-(?:nav|debugger|byebug)/ }
    end

    # binding.pry frame
    # @return [Boolean]
    def pry_method_frame?(binding)
      safe_send(binding.eval("__method__"), :==, :pry)
    end

    # When a pry session is started within a pry session
    # @return [Boolean]
    def nested_session?(bindings)
      bindings.detect do |b|
        safe_send(b.eval("__method__"), :==, :re) &&
          safe_send(b.eval("self.class"), :equal?, Pry)
      end
    end

    # @return [Array<Array<Binding, Fixnum>>]
    def internal_frames_with_indices(bindings)
      bindings.each_with_index.select do |b, i|
        b.frame_type == :method &&
          safe_send(b.eval("self"), :equal?, Pry) &&
          safe_send(b.eval("__method__"), :==, :start)
      end
    end

    def valid_call_stack?(bindings)
      bindings.any? && bindings.all? { |v| v.is_a?(Binding) }
    end
  end
end
