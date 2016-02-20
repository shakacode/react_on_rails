require 'pry-rescue'

# Minitest 5 handles all unknown exceptions, so to get them out of
# minitest, we need to add Exception to its passthrough types
# Note: We need to check the explicit minitest version because the minitest ecosystem
# may redefine Minitest::Test for Minitest versions < 5.
if defined?(Minitest::Test) && Minitest::Unit::VERSION.split('.').first.to_i >= 5

  class Minitest::Test
    alias_method :run_without_rescue, :run

    def run
      Minitest::Test::PASSTHROUGH_EXCEPTIONS << Exception
      Pry::rescue do
        run_without_rescue
      end
    end
  end

else

  # TODO: it should be possible to do all this by simply wrapping
  # MiniTest::Unit::TestCase in recent versions of minitest.
  # Unfortunately the version of minitest bundled with ruby seems to
  # take precedence over the new gem, so we can't do this and still
  # support ruby-1.9.3

  class MiniTest::Unit::TestCase
    alias_method :run_without_rescue, :run

    def run(runner)
      Pry::rescue do
        run_without_rescue(runner)
      end
    end
  end

  class << MiniTest::Unit.runner; self; end.class_eval do
    alias_method :puke_without_rescue, :puke

    def puke(suite, test, e)
      Pry::rescued(e)
      puke_without_rescue(suite, test, e)
    end
  end

end
