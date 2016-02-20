module WebConsole
  # Simple Ruby code evaluator.
  #
  # This class wraps a +Binding+ object and evaluates code inside of it. The
  # difference of a regular +Binding+ eval is that +Evaluator+ will always
  # return a string and will format exception output.
  class Evaluator
    # Cleanses exceptions raised inside #eval.
    cattr_reader :cleaner
    @@cleaner = ActiveSupport::BacktraceCleaner.new
    @@cleaner.add_silencer { |line| line.start_with?(File.expand_path('..', __FILE__)) }

    def initialize(binding = TOPLEVEL_BINDING)
      @binding = binding
    end

    def eval(input)
      "=> #{@binding.eval(input).inspect}\n"
    rescue Exception => exc
      format_exception(exc)
    end

    private

      def format_exception(exc)
        backtrace = cleaner.clean(Array(exc.backtrace) - caller)

        format = "#{exc.class.name}: #{exc}\n"
        format << backtrace.map { |trace| "\tfrom #{trace}\n" }.join
        format
      end
  end
end
