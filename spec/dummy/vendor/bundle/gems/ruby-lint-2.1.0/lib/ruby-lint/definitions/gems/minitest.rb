# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.5.n63

RubyLint.registry.register('Minitest') do |defs|
  defs.define_constant('Minitest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('__run') do |method|
      method.define_argument('reporter')
      method.define_argument('options')
    end

    klass.define_method('after_run') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('autorun')

    klass.define_method('backtrace_filter')

    klass.define_method('backtrace_filter=')

    klass.define_method('extensions')

    klass.define_method('extensions=')

    klass.define_method('filter_backtrace') do |method|
      method.define_argument('bt')
    end

    klass.define_method('init_plugins') do |method|
      method.define_argument('options')
    end

    klass.define_method('load_plugins')

    klass.define_method('parallel_executor')

    klass.define_method('parallel_executor=')

    klass.define_method('process_args') do |method|
      method.define_optional_argument('args')
    end

    klass.define_method('reporter')

    klass.define_method('reporter=')

    klass.define_method('run') do |method|
      method.define_optional_argument('args')
    end

    klass.define_method('run_one_method') do |method|
      method.define_argument('klass')
      method.define_argument('method_name')
    end
  end

  defs.define_constant('Minitest::AbstractReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mutex_m', RubyLint.registry))

    klass.define_instance_method('lock')

    klass.define_instance_method('locked?')

    klass.define_instance_method('passed?')

    klass.define_instance_method('record') do |method|
      method.define_argument('result')
    end

    klass.define_instance_method('report')

    klass.define_instance_method('start')

    klass.define_instance_method('synchronize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('try_lock')

    klass.define_instance_method('unlock')
  end

  defs.define_constant('Minitest::Assertion') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

    klass.define_instance_method('error')

    klass.define_instance_method('location')

    klass.define_instance_method('result_code')

    klass.define_instance_method('result_label')
  end

  defs.define_constant('Minitest::Assertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('diff')

    klass.define_method('diff=') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('_synchronize')

    klass.define_instance_method('assert') do |method|
      method.define_argument('test')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_empty') do |method|
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_equal') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_in_delta') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('delta')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_in_epsilon') do |method|
      method.define_argument('a')
      method.define_argument('b')
      method.define_optional_argument('epsilon')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_includes') do |method|
      method.define_argument('collection')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_instance_of') do |method|
      method.define_argument('cls')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_kind_of') do |method|
      method.define_argument('cls')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_match') do |method|
      method.define_argument('matcher')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_nil') do |method|
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_operator') do |method|
      method.define_argument('o1')
      method.define_argument('op')
      method.define_optional_argument('o2')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_output') do |method|
      method.define_optional_argument('stdout')
      method.define_optional_argument('stderr')
    end

    klass.define_instance_method('assert_predicate') do |method|
      method.define_argument('o1')
      method.define_argument('op')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_raises') do |method|
      method.define_rest_argument('exp')
    end

    klass.define_instance_method('assert_respond_to') do |method|
      method.define_argument('obj')
      method.define_argument('meth')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_same') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_send') do |method|
      method.define_argument('send_ary')
      method.define_optional_argument('m')
    end

    klass.define_instance_method('assert_silent')

    klass.define_instance_method('assert_throws') do |method|
      method.define_argument('sym')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('capture_io')

    klass.define_instance_method('capture_subprocess_io')

    klass.define_instance_method('diff') do |method|
      method.define_argument('exp')
      method.define_argument('act')
    end

    klass.define_instance_method('exception_details') do |method|
      method.define_argument('e')
      method.define_argument('msg')
    end

    klass.define_instance_method('flunk') do |method|
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('message') do |method|
      method.define_optional_argument('msg')
      method.define_optional_argument('ending')
      method.define_block_argument('default')
    end

    klass.define_instance_method('mu_pp') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('mu_pp_for_diff') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('pass') do |method|
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute') do |method|
      method.define_argument('test')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_empty') do |method|
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_equal') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_in_delta') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('delta')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_in_epsilon') do |method|
      method.define_argument('a')
      method.define_argument('b')
      method.define_optional_argument('epsilon')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_includes') do |method|
      method.define_argument('collection')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_instance_of') do |method|
      method.define_argument('cls')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_kind_of') do |method|
      method.define_argument('cls')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_match') do |method|
      method.define_argument('matcher')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_nil') do |method|
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_operator') do |method|
      method.define_argument('o1')
      method.define_argument('op')
      method.define_optional_argument('o2')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_predicate') do |method|
      method.define_argument('o1')
      method.define_argument('op')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_respond_to') do |method|
      method.define_argument('obj')
      method.define_argument('meth')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('refute_same') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('skip') do |method|
      method.define_optional_argument('msg')
      method.define_optional_argument('bt')
    end

    klass.define_instance_method('skipped?')
  end

  defs.define_constant('Minitest::Assertions::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('Minitest::BacktraceFilter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('filter') do |method|
      method.define_argument('bt')
    end
  end

  defs.define_constant('Minitest::CompositeReporter') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::AbstractReporter', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('reporter')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('reporters')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('passed?')

    klass.define_instance_method('record') do |method|
      method.define_argument('result')
    end

    klass.define_instance_method('report')

    klass.define_instance_method('reporters')

    klass.define_instance_method('reporters=')

    klass.define_instance_method('start')
  end

  defs.define_constant('Minitest::Guard') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('jruby?') do |method|
      method.define_optional_argument('platform')
    end

    klass.define_instance_method('maglev?') do |method|
      method.define_optional_argument('platform')
    end

    klass.define_instance_method('mri?') do |method|
      method.define_optional_argument('platform')
    end

    klass.define_instance_method('rubinius?') do |method|
      method.define_optional_argument('platform')
    end

    klass.define_instance_method('windows?') do |method|
      method.define_optional_argument('platform')
    end
  end

  defs.define_constant('Minitest::Parallel') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Minitest::Parallel::Executor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('work')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('size')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('shutdown')

    klass.define_instance_method('size')
  end

  defs.define_constant('Minitest::Parallel::Test') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_synchronize')
  end

  defs.define_constant('Minitest::Parallel::Test::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('run_one_method') do |method|
      method.define_argument('klass')
      method.define_argument('method_name')
      method.define_argument('reporter')
    end

    klass.define_instance_method('test_order')
  end

  defs.define_constant('Minitest::ProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::Reporter', RubyLint.registry))

    klass.define_instance_method('record') do |method|
      method.define_argument('result')
    end
  end

  defs.define_constant('Minitest::Reporter') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::AbstractReporter', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('io')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('io')

    klass.define_instance_method('io=')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')
  end

  defs.define_constant('Minitest::Runnable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inherited') do |method|
      method.define_argument('klass')
    end

    klass.define_method('methods_matching') do |method|
      method.define_argument('re')
    end

    klass.define_method('on_signal') do |method|
      method.define_argument('name')
      method.define_argument('action')
    end

    klass.define_method('reset')

    klass.define_method('run') do |method|
      method.define_argument('reporter')
      method.define_optional_argument('options')
    end

    klass.define_method('run_one_method') do |method|
      method.define_argument('klass')
      method.define_argument('method_name')
      method.define_argument('reporter')
    end

    klass.define_method('runnable_methods')

    klass.define_method('runnables')

    klass.define_method('with_info_handler') do |method|
      method.define_argument('reporter')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assertions')

    klass.define_instance_method('assertions=')

    klass.define_instance_method('failure')

    klass.define_instance_method('failures')

    klass.define_instance_method('failures=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('ary')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('passed?')

    klass.define_instance_method('result_code')

    klass.define_instance_method('run')

    klass.define_instance_method('skipped?')
  end

  defs.define_constant('Minitest::Skip') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::Assertion', RubyLint.registry))

    klass.define_instance_method('result_label')
  end

  defs.define_constant('Minitest::StatisticsReporter') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::Reporter', RubyLint.registry))

    klass.define_instance_method('assertions')

    klass.define_instance_method('assertions=')

    klass.define_instance_method('count')

    klass.define_instance_method('count=')

    klass.define_instance_method('errors')

    klass.define_instance_method('errors=')

    klass.define_instance_method('failures')

    klass.define_instance_method('failures=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('io')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('passed?')

    klass.define_instance_method('record') do |method|
      method.define_argument('result')
    end

    klass.define_instance_method('report')

    klass.define_instance_method('results')

    klass.define_instance_method('results=')

    klass.define_instance_method('skips')

    klass.define_instance_method('skips=')

    klass.define_instance_method('start')

    klass.define_instance_method('start_time')

    klass.define_instance_method('start_time=')

    klass.define_instance_method('total_time')

    klass.define_instance_method('total_time=')
  end

  defs.define_constant('Minitest::SummaryReporter') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::StatisticsReporter', RubyLint.registry))

    klass.define_instance_method('aggregated_results')

    klass.define_instance_method('old_sync')

    klass.define_instance_method('old_sync=')

    klass.define_instance_method('report')

    klass.define_instance_method('start')

    klass.define_instance_method('statistics')

    klass.define_instance_method('summary')

    klass.define_instance_method('sync')

    klass.define_instance_method('sync=')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Minitest::Test') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::Runnable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Minitest::Guard', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Minitest::Test::LifecycleHooks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Minitest::Assertions', RubyLint.registry))

    klass.define_method('i_suck_and_my_tests_are_order_dependent!')

    klass.define_method('io_lock')

    klass.define_method('io_lock=')

    klass.define_method('make_my_diffs_pretty!')

    klass.define_method('parallelize_me!')

    klass.define_method('runnable_methods')

    klass.define_method('test_order')

    klass.define_instance_method('capture_exceptions')

    klass.define_instance_method('error?')

    klass.define_instance_method('location')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('ary')
    end

    klass.define_instance_method('passed?')

    klass.define_instance_method('result_code')

    klass.define_instance_method('run')

    klass.define_instance_method('skipped?')

    klass.define_instance_method('time')

    klass.define_instance_method('time=')

    klass.define_instance_method('time_it')

    klass.define_instance_method('to_s')

    klass.define_instance_method('with_info_handler') do |method|
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Minitest::Test::LifecycleHooks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_setup')

    klass.define_instance_method('after_teardown')

    klass.define_instance_method('before_setup')

    klass.define_instance_method('before_teardown')

    klass.define_instance_method('setup')

    klass.define_instance_method('teardown')
  end

  defs.define_constant('Minitest::Test::PASSTHROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Minitest::Test::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('Minitest::UnexpectedError') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::Assertion', RubyLint.registry))

    klass.define_instance_method('backtrace')

    klass.define_instance_method('error')

    klass.define_instance_method('exception')

    klass.define_instance_method('exception=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('message')

    klass.define_instance_method('result_label')
  end

  defs.define_constant('Minitest::Unit') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('after_tests') do |method|
      method.define_block_argument('b')
    end

    klass.define_method('autorun')
  end

  defs.define_constant('Minitest::Unit::TestCase') do |klass|
    klass.inherits(defs.constant_proxy('Minitest::Test', RubyLint.registry))

    klass.define_method('inherited') do |method|
      method.define_argument('klass')
    end
  end

  defs.define_constant('Minitest::Unit::TestCase::LifecycleHooks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_setup')

    klass.define_instance_method('after_teardown')

    klass.define_instance_method('before_setup')

    klass.define_instance_method('before_teardown')

    klass.define_instance_method('setup')

    klass.define_instance_method('teardown')
  end

  defs.define_constant('Minitest::Unit::TestCase::PASSTHROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Minitest::Unit::TestCase::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('Minitest::Unit::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Minitest::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
