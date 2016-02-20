require 'debug_inspector'

module BindingOfCaller
  module BindingExtensions
    # Retrieve the binding of the nth caller of the current frame.
    # @return [Binding]
    def of_caller(n)
      c = callers.drop(1)
      if n > (c.size - 1)
        raise "No such frame, gone beyond end of stack!"
      else
        c[n]
      end
    end

    # Return bindings for all caller frames.
    # @return [Array<Binding>]
    def callers
      ary = []
    
      RubyVM::DebugInspector.open do |i|
        n = 0
        loop do
          begin
            b = i.frame_binding(n) 
          rescue ArgumentError
            break
          end

          if b
            b.instance_variable_set(:@iseq, i.frame_iseq(n))
            ary << b
          end
          
          n += 1
        end
      end
      
      ary.drop(1)
    end

    # Number of parent frames available at the point of call.
    # @return [Fixnum]
    def frame_count
      callers.size - 1
    end

    # The type of the frame.
    # @return [Symbol]
    def frame_type
      return nil if !@iseq
      
      # apparently the 9th element of the iseq array holds the frame type
      # ...not sure how reliable this is.
      @frame_type ||= @iseq.to_a[9]
    end

    # The description of the frame.
    # @return [String]
    def frame_description
      return nil if !@iseq
      @frame_description ||= @iseq.label
    end
  end
end

class ::Binding
  include BindingOfCaller::BindingExtensions
end
