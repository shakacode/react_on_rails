class Pry
  module Byebug
    #
    # Wrapper for Byebug.breakpoints that respects our Processor and has better
    # failure behavior. Acts as an Enumerable.
    #
    module Breakpoints
      extend Enumerable
      extend self

      #
      # Breakpoint in a file:line location
      #
      class FileBreakpoint < SimpleDelegator
        def source_code
          Pry::Code.from_file(source).around(pos, 3).with_marker(pos)
        end

        def to_s
          "#{source} @ #{pos}"
        end
      end

      #
      # Breakpoint in a Class#method location
      #
      class MethodBreakpoint < SimpleDelegator
        def initialize(byebug_bp, method)
          __setobj__ byebug_bp
          @method = method
        end

        def source_code
          Pry::Code.from_method(Pry::Method.from_str(@method))
        end

        def to_s
          @method
        end
      end

      def breakpoints
        @breakpoints ||= []
      end

      #
      # Adds a method breakpoint.
      #
      def add_method(method, expression = nil)
        validate_expression expression
        owner, name = method.split(/[\.#]/)
        byebug_bp = ::Byebug::Breakpoint.add(owner, name.to_sym, expression)
        bp = MethodBreakpoint.new byebug_bp, method
        breakpoints << bp
        bp
      end

      #
      # Adds a file breakpoint.
      #
      def add_file(file, line, expression = nil)
        real_file = (file != Pry.eval_path)
        fail(ArgumentError, 'Invalid file!') if real_file && !File.exist?(file)
        validate_expression expression

        path = (real_file ? File.expand_path(file) : file)
        bp = FileBreakpoint.new ::Byebug::Breakpoint.add(path, line, expression)
        breakpoints << bp
        bp
      end

      #
      # Changes the conditional expression for a breakpoint.
      #
      def change(id, expression = nil)
        validate_expression expression

        breakpoint = find_by_id(id)
        breakpoint.expr = expression
        breakpoint
      end

      #
      # Deletes an existing breakpoint with the given ID.
      #
      def delete(id)
        deleted =
          ::Byebug.started? &&
          ::Byebug::Breakpoint.remove(id) &&
          breakpoints.delete(find_by_id(id))

        fail(ArgumentError, "No breakpoint ##{id}") unless deleted
      end

      #
      # Deletes all breakpoints.
      #
      def delete_all
        @breakpoints = []
        ::Byebug.breakpoints.clear if ::Byebug.started?
      end

      #
      # Enables a disabled breakpoint with the given ID.
      #
      def enable(id)
        change_status id, true
      end

      #
      # Disables a breakpoint with the given ID.
      #
      def disable(id)
        change_status id, false
      end

      #
      # Disables all breakpoints.
      #
      def disable_all
        each do |breakpoint|
          breakpoint.enabled = false
        end
      end

      def to_a
        breakpoints
      end

      def size
        to_a.size
      end

      def each(&block)
        to_a.each(&block)
      end

      def last
        to_a.last
      end

      def find_by_id(id)
        breakpoint = find { |b| b.id == id }
        fail(ArgumentError, "No breakpoint ##{id}!") unless breakpoint
        breakpoint
      end

      private

      def change_status(id, enabled = true)
        breakpoint = find_by_id(id)
        breakpoint.enabled = enabled
        breakpoint
      end

      def validate_expression(exp)
        valid = exp && (exp.empty? || !Pry::Code.complete_expression?(exp))
        return unless valid

        fail("Invalid breakpoint conditional: #{expression}")
      end
    end
  end
end
