# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 2.2.1

RubyLint.registry.register('Test') do |defs|
  defs.define_constant('Test') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::AssertionFailedError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('actual')

    klass.define_instance_method('actual=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('expected')

    klass.define_instance_method('expected=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('message')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspected_actual')

    klass.define_instance_method('inspected_actual=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('inspected_expected')

    klass.define_instance_method('inspected_expected=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('user_message')

    klass.define_instance_method('user_message=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Test::Unit::Assertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('use_pp=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('add_assertion')

    klass.define_instance_method('assert') do |method|
      method.define_optional_argument('object')
      method.define_optional_argument('message')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_alias_method') do |method|
      method.define_argument('object')
      method.define_argument('alias_name')
      method.define_argument('original_name')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_block') do |method|
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_boolean') do |method|
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_compare') do |method|
      method.define_argument('expected')
      method.define_argument('operator')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_const_defined') do |method|
      method.define_argument('object')
      method.define_argument('constant_name')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_empty') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_equal') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_fail_assertion') do |method|
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_false') do |method|
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_in_delta') do |method|
      method.define_argument('expected_float')
      method.define_argument('actual_float')
      method.define_optional_argument('delta')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_in_epsilon') do |method|
      method.define_argument('expected_float')
      method.define_argument('actual_float')
      method.define_optional_argument('epsilon')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_include') do |method|
      method.define_argument('collection')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_includes') do |method|
      method.define_argument('collection')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_instance_of') do |method|
      method.define_argument('klass')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_kind_of') do |method|
      method.define_argument('klass')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_match') do |method|
      method.define_argument('pattern')
      method.define_argument('string')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_nil') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_no_match') do |method|
      method.define_argument('regexp')
      method.define_argument('string')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_const_defined') do |method|
      method.define_argument('object')
      method.define_argument('constant_name')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_empty') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_equal') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_in_delta') do |method|
      method.define_argument('expected_float')
      method.define_argument('actual_float')
      method.define_optional_argument('delta')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_in_epsilon') do |method|
      method.define_argument('expected_float')
      method.define_argument('actual_float')
      method.define_optional_argument('epsilon')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_include') do |method|
      method.define_argument('collection')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_includes') do |method|
      method.define_argument('collection')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_instance_of') do |method|
      method.define_argument('klass')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_kind_of') do |method|
      method.define_argument('klass')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_match') do |method|
      method.define_argument('regexp')
      method.define_argument('string')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_nil') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_operator') do |method|
      method.define_argument('object1')
      method.define_argument('operator')
      method.define_argument('object2')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_predicate') do |method|
      method.define_argument('object')
      method.define_argument('predicate')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_respond_to') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_same') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_not_send') do |method|
      method.define_argument('send_array')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_nothing_raised') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('assert_nothing_thrown') do |method|
      method.define_optional_argument('message')
      method.define_block_argument('proc')
    end

    klass.define_instance_method('assert_operator') do |method|
      method.define_argument('object1')
      method.define_argument('operator')
      method.define_argument('object2')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_path_exist') do |method|
      method.define_argument('path')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_path_not_exist') do |method|
      method.define_argument('path')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_predicate') do |method|
      method.define_argument('object')
      method.define_argument('predicate')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_raise') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_raise_kind_of') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_raise_message') do |method|
      method.define_argument('expected')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_raises') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_respond_to') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_same') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_send') do |method|
      method.define_argument('send_array')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_throw') do |method|
      method.define_argument('expected_object')
      method.define_optional_argument('message')
      method.define_block_argument('proc')
    end

    klass.define_instance_method('assert_throws') do |method|
      method.define_argument('expected_object')
      method.define_optional_argument('message')
      method.define_block_argument('proc')
    end

    klass.define_instance_method('assert_true') do |method|
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('build_message') do |method|
      method.define_argument('head')
      method.define_optional_argument('template')
      method.define_rest_argument('arguments')
    end

    klass.define_instance_method('flunk') do |method|
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_empty') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_equal') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_in_delta') do |method|
      method.define_argument('expected_float')
      method.define_argument('actual_float')
      method.define_optional_argument('delta')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_in_epsilon') do |method|
      method.define_argument('expected_float')
      method.define_argument('actual_float')
      method.define_optional_argument('epsilon')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_includes') do |method|
      method.define_argument('collection')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_instance_of') do |method|
      method.define_argument('klass')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_kind_of') do |method|
      method.define_argument('klass')
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_match') do |method|
      method.define_argument('regexp')
      method.define_argument('string')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_nil') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_operator') do |method|
      method.define_argument('object1')
      method.define_argument('operator')
      method.define_argument('object2')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_predicate') do |method|
      method.define_argument('object')
      method.define_argument('predicate')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_respond_to') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('refute_same') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end
  end

  defs.define_constant('Test::Unit::Assertions::AssertExceptionHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('expected?') do |method|
      method.define_argument('actual_exception')
      method.define_optional_argument('equality')
    end

    klass.define_instance_method('expected_exceptions')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_case')
      method.define_argument('expected_exceptions')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Test::Unit::Assertions::AssertExceptionHelper::WrappedException') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('exception')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::BacktraceFilter', RubyLint.registry))

    klass.define_method('convert') do |method|
      method.define_argument('object')
    end

    klass.define_method('delayed_diff') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('delayed_literal') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('diff_target_string?') do |method|
      method.define_argument('string')
    end

    klass.define_method('ensure_diffable_string') do |method|
      method.define_argument('string')
    end

    klass.define_method('literal') do |method|
      method.define_argument('value')
    end

    klass.define_method('max_diff_target_string_size')

    klass.define_method('max_diff_target_string_size=') do |method|
      method.define_argument('size')
    end

    klass.define_method('maybe_container') do |method|
      method.define_argument('value')
      method.define_block_argument('formatter')
    end

    klass.define_method('prepare_for_diff') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('use_pp')

    klass.define_method('use_pp=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_period') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('convert') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('head')
      method.define_argument('template_string')
      method.define_argument('parameters')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('template')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::ArrayInspector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('target?') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('array')
      method.define_argument('inspected_objects')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::DelayedLiteral') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::HashInspector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('target?') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('each_pair')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('hash')
      method.define_argument('inspected_objects')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::Inspector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('cached_new') do |method|
      method.define_argument('object')
      method.define_argument('inspected_objects')
    end

    klass.define_method('inspector_classes')

    klass.define_method('register_inspector_class') do |method|
      method.define_argument('inspector_class')
    end

    klass.define_method('unregister_inspector_class') do |method|
      method.define_argument('inspector_class')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object')
      method.define_optional_argument('inspected_objects')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('native_inspect')

    klass.define_instance_method('object')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::Literal') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::MaybeContainer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')
      method.define_block_argument('formatter')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::NumericInspector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('target?') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('numeric')
      method.define_argument('inspected_objects')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end
  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::TESTUNIT_FILE_SEPARATORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::TESTUNIT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::TESTUNIT_RB_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Assertions::AssertionMessage::Template') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('count')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('parts')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('result') do |method|
      method.define_argument('parameters')
    end
  end

  defs.define_constant('Test::Unit::Assertions::NOT_SPECIFIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Assertions::ThrowTagExtractor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('extract_tag')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('error')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Test::Unit::Assertions::ThrowTagExtractor::UncaughtThrowPatterns') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('attributes')
  end

  defs.define_constant('Test::Unit::Attribute::BaseClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attributes_table')
  end

  defs.define_constant('Test::Unit::Attribute::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attribute') do |method|
      method.define_argument('name')
      method.define_argument('value')
      method.define_optional_argument('options')
      method.define_rest_argument('method_names')
    end

    klass.define_instance_method('attribute_observers') do |method|
      method.define_argument('attribute_name')
    end

    klass.define_instance_method('attributes') do |method|
      method.define_argument('method_name')
    end

    klass.define_instance_method('attributes_table')

    klass.define_instance_method('current_attribute') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('current_attributes')

    klass.define_instance_method('find_attribute') do |method|
      method.define_argument('method_name')
      method.define_argument('name')
    end

    klass.define_instance_method('method_added') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('register_attribute_observer') do |method|
      method.define_argument('attribute_name')
      method.define_optional_argument('observer')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('method_name')
      method.define_argument('new_attributes')
    end
  end

  defs.define_constant('Test::Unit::Attribute::StringifyKeyHash') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_method('stringify') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end
  end

  defs.define_constant('Test::Unit::AttributeMatcher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match?') do |method|
      method.define_argument('expression')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Test::Unit::AutoRunner') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('collector') do |method|
      method.define_argument('id')
    end

    klass.define_method('default_runner')

    klass.define_method('default_runner=') do |method|
      method.define_argument('id')
    end

    klass.define_method('need_auto_run=') do |method|
      method.define_argument('need')
    end

    klass.define_method('need_auto_run?')

    klass.define_method('prepare') do |method|
      method.define_optional_argument('hook')
    end

    klass.define_method('register_collector') do |method|
      method.define_argument('id')
      method.define_optional_argument('collector_builder')
    end

    klass.define_method('register_color_scheme') do |method|
      method.define_argument('id')
      method.define_argument('scheme')
    end

    klass.define_method('register_runner') do |method|
      method.define_argument('id')
      method.define_optional_argument('runner_builder')
    end

    klass.define_method('run') do |method|
      method.define_optional_argument('force_standalone')
      method.define_optional_argument('default_dir')
      method.define_optional_argument('argv')
      method.define_block_argument('block')
    end

    klass.define_method('runner') do |method|
      method.define_argument('id')
    end

    klass.define_method('setup_option') do |method|
      method.define_optional_argument('option_builder')
    end

    klass.define_method('standalone?')

    klass.define_instance_method('base')

    klass.define_instance_method('base=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('collector=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('color_scheme')

    klass.define_instance_method('color_scheme=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('exclude')

    klass.define_instance_method('exclude=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('filters')

    klass.define_instance_method('filters=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('standalone')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keyword_display') do |method|
      method.define_argument('keywords')
    end

    klass.define_instance_method('listeners')

    klass.define_instance_method('listeners=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('load_config') do |method|
      method.define_argument('file')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('pattern')

    klass.define_instance_method('pattern=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('prepare')

    klass.define_instance_method('process_args') do |method|
      method.define_optional_argument('args')
    end

    klass.define_instance_method('run')

    klass.define_instance_method('runner=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('runner_options')

    klass.define_instance_method('suite')

    klass.define_instance_method('to_run')

    klass.define_instance_method('to_run=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('workdir')

    klass.define_instance_method('workdir=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Test::Unit::AutoRunner::ADDITIONAL_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::AutoRunner::COLLECTORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::AutoRunner::PREPARE_HOOKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::AutoRunner::RUNNERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Color') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('parse_256_color') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('background?')

    klass.define_instance_method('bold?')

    klass.define_instance_method('escape_sequence')

    klass.define_instance_method('foreground?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('intensity?')

    klass.define_instance_method('italic?')

    klass.define_instance_method('name')

    klass.define_instance_method('sequence')

    klass.define_instance_method('underline?')
  end

  defs.define_constant('Test::Unit::Color::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Color::NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Color::ParseError') do |klass|
    klass.inherits(defs.constant_proxy('Test::Unit::Color::Error', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::ColorScheme') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_argument('id')
    end

    klass.define_method('[]=') do |method|
      method.define_argument('id')
      method.define_argument('scheme_or_spec')
    end

    klass.define_method('all')

    klass.define_method('available_colors')

    klass.define_method('default')

    klass.define_method('default_for_256_colors')

    klass.define_method('default_for_8_colors')

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('color_spec')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('scheme_spec')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_hash')
  end

  defs.define_constant('Test::Unit::Data') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('Test::Unit::Data::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('data') do |method|
      method.define_rest_argument('arguments')
      method.define_block_argument('block')
    end

    klass.define_instance_method('load_data') do |method|
      method.define_argument('file_name')
    end
  end

  defs.define_constant('Test::Unit::Data::ClassMethods::Loader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_case')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('file_name')
    end

    klass.define_instance_method('load_csv') do |method|
      method.define_argument('file_name')
    end

    klass.define_instance_method('load_tsv') do |method|
      method.define_argument('file_name')
    end
  end

  defs.define_constant('Test::Unit::Diff') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('diff') do |method|
      method.define_argument('differ_class')
      method.define_argument('from')
      method.define_argument('to')
      method.define_optional_argument('options')
    end

    klass.define_method('fold') do |method|
      method.define_argument('string')
    end

    klass.define_method('folded_readable') do |method|
      method.define_argument('from')
      method.define_argument('to')
      method.define_optional_argument('options')
    end

    klass.define_method('need_fold?') do |method|
      method.define_argument('diff')
    end

    klass.define_method('readable') do |method|
      method.define_argument('from')
      method.define_argument('to')
      method.define_optional_argument('options')
    end

    klass.define_method('unified') do |method|
      method.define_argument('from')
      method.define_argument('to')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Test::Unit::Diff::Differ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('from')
      method.define_argument('to')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Test::Unit::Diff::ReadableDiffer') do |klass|
    klass.inherits(defs.constant_proxy('Test::Unit::Diff::Differ', RubyLint.registry))

    klass.define_instance_method('diff') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Test::Unit::Diff::SequenceMatcher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('blocks')

    klass.define_instance_method('grouped_operations') do |method|
      method.define_optional_argument('context_size')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('from')
      method.define_argument('to')
      method.define_block_argument('junk_predicate')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('longest_match') do |method|
      method.define_argument('from_start')
      method.define_argument('from_end')
      method.define_argument('to_start')
      method.define_argument('to_end')
    end

    klass.define_instance_method('operations')

    klass.define_instance_method('ratio')
  end

  defs.define_constant('Test::Unit::Diff::UTF8Line') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('wide_character?') do |method|
      method.define_argument('character')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('compute_width') do |method|
      method.define_argument('start')
      method.define_argument('_end')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('line')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('size')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::Diff::UnifiedDiffer') do |klass|
    klass.inherits(defs.constant_proxy('Test::Unit::Diff::Differ', RubyLint.registry))

    klass.define_instance_method('diff') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Test::Unit::Error') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::BacktraceFilter', RubyLint.registry))

    klass.define_instance_method('backtrace')

    klass.define_instance_method('critical?')

    klass.define_instance_method('exception')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_name')
      method.define_argument('exception')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('location')

    klass.define_instance_method('long_display')

    klass.define_instance_method('message')

    klass.define_instance_method('method_name')

    klass.define_instance_method('short_display')

    klass.define_instance_method('single_character_display')

    klass.define_instance_method('test_name')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::Error::LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Error::SINGLE_CHARACTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Error::TESTUNIT_FILE_SEPARATORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Error::TESTUNIT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Error::TESTUNIT_RB_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::ErrorHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('Test::Unit::ErrorHandler::NOT_PASS_THROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::ErrorHandler::NOT_PASS_THROUGH_EXCEPTION_NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::ErrorHandler::PASS_THROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::ErrorHandler::PASS_THROUGH_EXCEPTION_NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::ExceptionHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('exception_handlers')

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('Test::Unit::ExceptionHandler::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('exception_handler') do |method|
      method.define_rest_argument('method_name_or_handlers')
      method.define_block_argument('block')
    end

    klass.define_instance_method('exception_handlers')

    klass.define_instance_method('unregister_exception_handler') do |method|
      method.define_rest_argument('method_name_or_handlers')
    end
  end

  defs.define_constant('Test::Unit::Failure') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('actual')

    klass.define_instance_method('critical?')

    klass.define_instance_method('diff')

    klass.define_instance_method('expected')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_name')
      method.define_argument('location')
      method.define_argument('message')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspected_actual')

    klass.define_instance_method('inspected_expected')

    klass.define_instance_method('label')

    klass.define_instance_method('location')

    klass.define_instance_method('long_display')

    klass.define_instance_method('message')

    klass.define_instance_method('method_name')

    klass.define_instance_method('short_display')

    klass.define_instance_method('single_character_display')

    klass.define_instance_method('source_location')

    klass.define_instance_method('test_name')

    klass.define_instance_method('to_s')

    klass.define_instance_method('user_message')
  end

  defs.define_constant('Test::Unit::Failure::LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Failure::SINGLE_CHARACTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::FailureHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('add_failure') do |method|
      method.define_argument('message')
      method.define_argument('backtrace')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Test::Unit::Fixture') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('Test::Unit::Fixture::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cleanup') do |method|
      method.define_rest_argument('method_names')
      method.define_block_argument('callback')
    end

    klass.define_instance_method('fixture')

    klass.define_instance_method('setup') do |method|
      method.define_rest_argument('method_names')
      method.define_block_argument('callback')
    end

    klass.define_instance_method('teardown') do |method|
      method.define_rest_argument('method_names')
      method.define_block_argument('callback')
    end

    klass.define_instance_method('unregister_cleanup') do |method|
      method.define_rest_argument('method_names_or_callbacks')
    end

    klass.define_instance_method('unregister_setup') do |method|
      method.define_rest_argument('method_names_or_callbacks')
    end

    klass.define_instance_method('unregister_teardown') do |method|
      method.define_rest_argument('method_names_or_callbacks')
    end
  end

  defs.define_constant('Test::Unit::Fixture::Fixture') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('after_callbacks') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('before_callbacks') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('cleanup')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_case')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('setup')

    klass.define_instance_method('teardown')
  end

  defs.define_constant('Test::Unit::Fixture::HookPoint') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_append_callbacks')

    klass.define_instance_method('after_prepend_callbacks')

    klass.define_instance_method('before_append_callbacks')

    klass.define_instance_method('before_prepend_callbacks')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('default_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('register') do |method|
      method.define_argument('method_name_or_callback')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('unregister') do |method|
      method.define_argument('method_name_or_callback')
    end
  end

  defs.define_constant('Test::Unit::MixColor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('colors')

    klass.define_instance_method('escape_sequence')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('colors')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sequence')
  end

  defs.define_constant('Test::Unit::Notification') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::BacktraceFilter', RubyLint.registry))

    klass.define_instance_method('critical?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_name')
      method.define_argument('location')
      method.define_argument('message')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('location')

    klass.define_instance_method('long_display')

    klass.define_instance_method('message')

    klass.define_instance_method('method_name')

    klass.define_instance_method('short_display')

    klass.define_instance_method('single_character_display')

    klass.define_instance_method('test_name')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::Notification::LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Notification::SINGLE_CHARACTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Notification::TESTUNIT_FILE_SEPARATORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Notification::TESTUNIT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Notification::TESTUNIT_RB_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::NotificationHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('Test::Unit::NotifiedError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Omission') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::BacktraceFilter', RubyLint.registry))

    klass.define_instance_method('critical?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_name')
      method.define_argument('location')
      method.define_argument('message')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('location')

    klass.define_instance_method('long_display')

    klass.define_instance_method('message')

    klass.define_instance_method('method_name')

    klass.define_instance_method('short_display')

    klass.define_instance_method('single_character_display')

    klass.define_instance_method('test_name')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::Omission::LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Omission::SINGLE_CHARACTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Omission::TESTUNIT_FILE_SEPARATORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Omission::TESTUNIT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Omission::TESTUNIT_RB_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::OmissionHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('Test::Unit::OmittedError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::PendedError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Pending') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::BacktraceFilter', RubyLint.registry))

    klass.define_instance_method('critical?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_name')
      method.define_argument('location')
      method.define_argument('message')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('location')

    klass.define_instance_method('long_display')

    klass.define_instance_method('message')

    klass.define_instance_method('method_name')

    klass.define_instance_method('short_display')

    klass.define_instance_method('single_character_display')

    klass.define_instance_method('test_name')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::Pending::LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Pending::SINGLE_CHARACTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Pending::TESTUNIT_FILE_SEPARATORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Pending::TESTUNIT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Pending::TESTUNIT_RB_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::PendingHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('Test::Unit::Priority') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_values')

    klass.define_method('default')

    klass.define_method('default=') do |method|
      method.define_argument('default')
    end

    klass.define_method('disable')

    klass.define_method('enable')

    klass.define_method('enabled?')

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('priority_setup')

    klass.define_instance_method('priority_teardown')
  end

  defs.define_constant('Test::Unit::Priority::Checker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_priorities')

    klass.define_method('have_priority?') do |method|
      method.define_argument('name')
    end

    klass.define_method('need_to_run?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_high?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_important?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_low?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_must?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_never?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_normal?') do |method|
      method.define_argument('test')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('need_to_run?')

    klass.define_instance_method('setup')

    klass.define_instance_method('teardown')

    klass.define_instance_method('test')
  end

  defs.define_constant('Test::Unit::Priority::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('priority') do |method|
      method.define_argument('name')
      method.define_rest_argument('tests')
    end
  end

  defs.define_constant('Test::Unit::TestCase') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::Output', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::BacktraceFilter', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Assertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Data', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Priority', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::NotificationHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::TestCaseNotificationSupport', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::OmissionHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::TestCaseOmissionSupport', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::PendingHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::TestCasePendingSupport', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::FailureHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::ErrorHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::ExceptionHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Fixture', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Attribute', RubyLint.registry))

    klass.define_method('added_method_names')

    klass.define_method('description') do |method|
      method.define_argument('value')
      method.define_optional_argument('target')
    end

    klass.define_method('inherited') do |method|
      method.define_argument('sub_class')
    end

    klass.define_method('method_added') do |method|
      method.define_argument('name')
    end

    klass.define_method('shutdown')

    klass.define_method('startup')

    klass.define_method('sub_test_case') do |method|
      method.define_argument('name')
      method.define_block_argument('block')
    end

    klass.define_method('suite')

    klass.define_method('test') do |method|
      method.define_rest_argument('test_description_or_targets')
      method.define_block_argument('block')
    end

    klass.define_method('test_defined?') do |method|
      method.define_argument('query')
    end

    klass.define_method('test_order')

    klass.define_method('test_order=') do |method|
      method.define_argument('order')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('add_pass')

    klass.define_instance_method('assign_test_data') do |method|
      method.define_argument('label')
      method.define_argument('data')
    end

    klass.define_instance_method('cleanup')

    klass.define_instance_method('data_label')

    klass.define_instance_method('default_test')

    klass.define_instance_method('description')

    klass.define_instance_method('elapsed_time')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_method_name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('interrupted?')

    klass.define_instance_method('method_name')

    klass.define_instance_method('name')

    klass.define_instance_method('passed?')

    klass.define_instance_method('problem_occurred')

    klass.define_instance_method('run') do |method|
      method.define_argument('result')
    end

    klass.define_instance_method('setup')

    klass.define_instance_method('size')

    klass.define_instance_method('start_time')

    klass.define_instance_method('teardown')

    klass.define_instance_method('to_s')

    klass.define_instance_method('valid?')
  end

  defs.define_constant('Test::Unit::TestCase::AVAILABLE_ORDERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::AssertExceptionHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('expected?') do |method|
      method.define_argument('actual_exception')
      method.define_optional_argument('equality')
    end

    klass.define_instance_method('expected_exceptions')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_case')
      method.define_argument('expected_exceptions')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Test::Unit::TestCase::AssertionMessage') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Test::Unit::Util::BacktraceFilter', RubyLint.registry))

    klass.define_method('convert') do |method|
      method.define_argument('object')
    end

    klass.define_method('delayed_diff') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('delayed_literal') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('diff_target_string?') do |method|
      method.define_argument('string')
    end

    klass.define_method('ensure_diffable_string') do |method|
      method.define_argument('string')
    end

    klass.define_method('literal') do |method|
      method.define_argument('value')
    end

    klass.define_method('max_diff_target_string_size')

    klass.define_method('max_diff_target_string_size=') do |method|
      method.define_argument('size')
    end

    klass.define_method('maybe_container') do |method|
      method.define_argument('value')
      method.define_block_argument('formatter')
    end

    klass.define_method('prepare_for_diff') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('use_pp')

    klass.define_method('use_pp=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_period') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('convert') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('head')
      method.define_argument('template_string')
      method.define_argument('parameters')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('template')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::TestCase::BaseClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attributes_table')
  end

  defs.define_constant('Test::Unit::TestCase::Checker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_priorities')

    klass.define_method('have_priority?') do |method|
      method.define_argument('name')
    end

    klass.define_method('need_to_run?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_high?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_important?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_low?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_must?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_never?') do |method|
      method.define_argument('test')
    end

    klass.define_method('run_priority_normal?') do |method|
      method.define_argument('test')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('need_to_run?')

    klass.define_instance_method('setup')

    klass.define_instance_method('teardown')

    klass.define_instance_method('test')
  end

  defs.define_constant('Test::Unit::TestCase::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('data') do |method|
      method.define_rest_argument('arguments')
      method.define_block_argument('block')
    end

    klass.define_instance_method('load_data') do |method|
      method.define_argument('file_name')
    end
  end

  defs.define_constant('Test::Unit::TestCase::DESCENDANTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::FINISHED_OBJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::Fixture') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('after_callbacks') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('before_callbacks') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('cleanup')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_case')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('setup')

    klass.define_instance_method('teardown')
  end

  defs.define_constant('Test::Unit::TestCase::HookPoint') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_append_callbacks')

    klass.define_instance_method('after_prepend_callbacks')

    klass.define_instance_method('before_append_callbacks')

    klass.define_instance_method('before_prepend_callbacks')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('default_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('register') do |method|
      method.define_argument('method_name_or_callback')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('unregister') do |method|
      method.define_argument('method_name_or_callback')
    end
  end

  defs.define_constant('Test::Unit::TestCase::InternalData') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assign_test_data') do |method|
      method.define_argument('label')
      method.define_argument('data')
    end

    klass.define_instance_method('elapsed_time')

    klass.define_instance_method('have_test_data?')

    klass.define_instance_method('initialize')

    klass.define_instance_method('interrupted')

    klass.define_instance_method('interrupted?')

    klass.define_instance_method('passed?')

    klass.define_instance_method('problem_occurred')

    klass.define_instance_method('start_time')

    klass.define_instance_method('test_data')

    klass.define_instance_method('test_data_label')

    klass.define_instance_method('test_finished')

    klass.define_instance_method('test_started')
  end

  defs.define_constant('Test::Unit::TestCase::NOT_PASS_THROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::NOT_PASS_THROUGH_EXCEPTION_NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::NOT_SPECIFIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::PASS_THROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::PASS_THROUGH_EXCEPTION_NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::STARTED_OBJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::StringifyKeyHash') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_method('stringify') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end
  end

  defs.define_constant('Test::Unit::TestCase::TESTUNIT_FILE_SEPARATORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::TESTUNIT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::TESTUNIT_RB_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestCase::ThrowTagExtractor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('extract_tag')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('error')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Test::Unit::TestCaseNotificationSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('notify') do |method|
      method.define_argument('message')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Test::Unit::TestCaseOmissionSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('omit') do |method|
      method.define_optional_argument('message')
      method.define_block_argument('block')
    end

    klass.define_instance_method('omit_if') do |method|
      method.define_argument('condition')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('omit_unless') do |method|
      method.define_argument('condition')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Test::Unit::TestCasePendingSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('pend') do |method|
      method.define_optional_argument('message')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Test::Unit::TestResultErrorSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_error') do |method|
      method.define_argument('error')
    end

    klass.define_instance_method('error_count')

    klass.define_instance_method('error_occurred?')

    klass.define_instance_method('errors')
  end

  defs.define_constant('Test::Unit::TestResultFailureSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_failure') do |method|
      method.define_argument('failure')
    end

    klass.define_instance_method('failure_count')

    klass.define_instance_method('failure_occurred?')

    klass.define_instance_method('failures')
  end

  defs.define_constant('Test::Unit::TestResultNotificationSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_notification') do |method|
      method.define_argument('notification')
    end

    klass.define_instance_method('notification_count')

    klass.define_instance_method('notifications')
  end

  defs.define_constant('Test::Unit::TestResultOmissionSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_omission') do |method|
      method.define_argument('omission')
    end

    klass.define_instance_method('omission_count')

    klass.define_instance_method('omissions')
  end

  defs.define_constant('Test::Unit::TestResultPendingSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_pending') do |method|
      method.define_argument('pending')
    end

    klass.define_instance_method('pending_count')

    klass.define_instance_method('pendings')
  end

  defs.define_constant('Test::Unit::TestSuite') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('test')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('test')
    end

    klass.define_instance_method('delete_tests') do |method|
      method.define_argument('tests')
    end

    klass.define_instance_method('elapsed_time')

    klass.define_instance_method('empty?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('test_case')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('passed?')

    klass.define_instance_method('priority')

    klass.define_instance_method('priority=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('run') do |method|
      method.define_argument('result')
      method.define_block_argument('progress_block')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('start_time')

    klass.define_instance_method('test_case')

    klass.define_instance_method('tests')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Test::Unit::TestSuite::FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestSuite::FINISHED_OBJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestSuite::STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestSuite::STARTED_OBJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::TestSuiteCreator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('test_case')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Test::Unit::Util') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Util::BacktraceFilter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('filter_backtrace') do |method|
      method.define_argument('backtrace')
      method.define_optional_argument('prefix')
    end
  end

  defs.define_constant('Test::Unit::Util::BacktraceFilter::TESTUNIT_FILE_SEPARATORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Util::BacktraceFilter::TESTUNIT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Util::BacktraceFilter::TESTUNIT_RB_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Test::Unit::Util::MethodOwnerFinder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('find') do |method|
      method.define_argument('object')
      method.define_argument('method_name')
    end
  end

  defs.define_constant('Test::Unit::Util::Output') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('capture_output')
  end
end
