require 'English'
require 'active_support/core_ext/string/strip'

java_import org.jruby.RubyInstanceConfig

module WebConsole
  module JRuby
    class << self
      # Returns whether JRuby is ran in interpreted mode.
      def interpreted_mode?
        compile_mode     = ::JRuby.runtime.instance_config.compile_mode
        interpreted_mode = RubyInstanceConfig::CompileMode::OFF

        compile_mode == interpreted_mode
      end

      # A proc to be used in Kernel#set_trace_func.
      #
      # It sets Exception#bindings for an error with all the bindings the
      # current ThreadContext contains.
      def set_exception_bindings_trace_func
        proc do |event, file, line, id, binding, classname|
          case event
          when 'raise'
            if $ERROR_INFO.bindings.empty?
              # binding_of_caller will generate an improperly built binding at
              # caller[1]. Every call to a non existent method, constant or a
              # local variable will result in a Java NullPointerException.
              #
              # The binding that Kernel#set_trace_func is giving us is properly
              # built, so we can use in place of the broken one.
              bindings = ::Kernel.binding.callers.drop(2).unshift(binding)
              $ERROR_INFO.instance_variable_set(:@bindings, bindings)
            end
          end
        end
      end
    end

    # A fake binding for JRuby in non interpreted mode.
    #
    # It won't actually evaluate any code, rather it will tell the user how to
    # enable interpreted mode.
    class FakeJRubyBinding
      TURN_ON_INTERPRETED_MODE_TEXT = <<-END.strip_heredoc
        JRuby needs to run in interpreted mode for introspection support.

        To turn on interpreted mode, put -J-Djruby.compile.mode=OFF in the
        JRUBY_OPTS environment variable.
      END

      def TURN_ON_INTERPRETED_MODE_TEXT.inspect
        self
      end

      TURN_ON_INTERPRETED_MODE_TEXT.freeze

      def eval(*)
        TURN_ON_INTERPRETED_MODE_TEXT
      end
    end

    # A fake array of FakeJRubyBinding objects.
    #
    # It is used in Exception#bindings to make sure that when users switch
    # bindings on the UI, they get a FakeJRubyBinding notifying them what to do
    # if they want introspection.
    class FakeJRubyBindingsArray < Array
      def [](*)
        FakeJRubyBinding.new
      end

      # For Kernel#Array and other implicit conversion API. JRuby expects it to
      # return an object that is_a? an Array. This is the reasoning of
      # FakeJRubyBindingsArray being a subclass of Array.
      def to_ary
        self
      end
    end
  end
end

if WebConsole::JRuby.interpreted_mode?
  ::Exception.class_eval do
    def bindings
      @bindings || []
    end
  end

  # Kernel#set_trace_func will complain about not being able to capture all the
  # events without the JRuby --debug flag.
  silence_warnings do
    set_trace_func WebConsole::JRuby.set_exception_bindings_trace_func
  end
else
  ::Exception.class_eval do
    def bindings
      WebConsole::JRuby::FakeJRubyBindingsArray.new
    end
  end

  ::Binding.class_eval do
    def of_caller(*)
      WebConsole::JRuby::FakeJRubyBinding.new
    end

    def callers
      WebConsole::JRuby::FakeJRubyBindingsArray.new
    end
  end
end
