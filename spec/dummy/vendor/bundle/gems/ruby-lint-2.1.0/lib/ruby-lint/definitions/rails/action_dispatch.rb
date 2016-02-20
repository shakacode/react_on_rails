# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('ActionDispatch') do |defs|
  defs.define_constant('ActionDispatch') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('test_app')

    klass.define_method('test_app=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('test_app')

    klass.define_instance_method('test_app=') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('ActionDispatch::Assertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Assertions::DomAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_dom_equal') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_dom_not_equal') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end
  end

  defs.define_constant('ActionDispatch::Assertions::NO_STRIP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Assertions::ResponseAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_redirected_to') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_response') do |method|
      method.define_argument('type')
      method.define_optional_argument('message')
    end
  end

  defs.define_constant('ActionDispatch::Assertions::RoutingAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_generates') do |method|
      method.define_argument('expected_path')
      method.define_argument('options')
      method.define_optional_argument('defaults')
      method.define_optional_argument('extras')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_recognizes') do |method|
      method.define_argument('expected_options')
      method.define_argument('path')
      method.define_optional_argument('extras')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_routing') do |method|
      method.define_argument('path')
      method.define_argument('options')
      method.define_optional_argument('defaults')
      method.define_optional_argument('extras')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('selector')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_routing')
  end

  defs.define_constant('ActionDispatch::Assertions::SelectorAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_select') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_select_email') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_select_encoded') do |method|
      method.define_optional_argument('element')
      method.define_block_argument('block')
    end

    klass.define_instance_method('count_description') do |method|
      method.define_argument('min')
      method.define_argument('max')
      method.define_argument('count')
    end

    klass.define_instance_method('css_select') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('response_from_page')
  end

  defs.define_constant('ActionDispatch::Assertions::TagAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_no_tag') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('assert_tag') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('find_all_tag') do |method|
      method.define_argument('conditions')
    end

    klass.define_instance_method('find_tag') do |method|
      method.define_argument('conditions')
    end

    klass.define_instance_method('html_document')
  end

  defs.define_constant('ActionDispatch::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Callbacks', RubyLint.registry))

    klass.define_method('_call_callbacks')

    klass.define_method('_call_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_call_callbacks?')

    klass.define_method('after') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('before') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('to_cleanup') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('to_prepare') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('_call_callbacks')

    klass.define_instance_method('_call_callbacks=')

    klass.define_instance_method('_call_callbacks?')

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Callbacks::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Callbacks::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActionDispatch::Callbacks::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActionDispatch::Callbacks::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__callback_runner_name_cache')

    klass.define_instance_method('__define_callbacks') do |method|
      method.define_argument('kind')
      method.define_argument('object')
    end

    klass.define_instance_method('__generate_callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__reset_runner') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('__update_callbacks') do |method|
      method.define_argument('name')
      method.define_optional_argument('filters')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('define_callbacks') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('reset_callbacks') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('set_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end

    klass.define_instance_method('skip_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionDispatch::Cookies') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Cookies::ChainedCookieJars') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('encrypted')

    klass.define_instance_method('permanent')

    klass.define_instance_method('signed')

    klass.define_instance_method('signed_or_encrypted')
  end

  defs.define_constant('ActionDispatch::Cookies::CookieJar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::ChainedCookieJars', RubyLint.registry))

    klass.define_method('always_write_cookie')

    klass.define_method('always_write_cookie=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('build') do |method|
      method.define_argument('request')
    end

    klass.define_method('options_for_env') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('options')
    end

    klass.define_instance_method('always_write_cookie')

    klass.define_instance_method('always_write_cookie=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('deleted?') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('fetch') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('handle_options') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('key_generator')
      method.define_optional_argument('host')
      method.define_optional_argument('secure')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('recycle!')

    klass.define_instance_method('update') do |method|
      method.define_argument('other_hash')
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('headers')
    end
  end

  defs.define_constant('ActionDispatch::Cookies::CookieJar::DOMAIN_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::CookieJar::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('ActionDispatch::Cookies::CookieJar::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActionDispatch::Cookies::CookieOverflow') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::ENCRYPTED_COOKIE_SALT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::ENCRYPTED_SIGNED_COOKIE_SALT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::EncryptedCookieJar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::ChainedCookieJars', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('parent_jar')
      method.define_argument('key_generator')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Cookies::GENERATOR_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::HTTP_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::MAX_COOKIE_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::PermanentCookieJar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::ChainedCookieJars', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('parent_jar')
      method.define_argument('key_generator')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Cookies::SECRET_KEY_BASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::SECRET_TOKEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::SIGNED_COOKIE_SALT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Cookies::SignedCookieJar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::ChainedCookieJars', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('parent_jar')
      method.define_argument('key_generator')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Cookies::UpgradeLegacyEncryptedCookieJar') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::EncryptedCookieJar', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::VerifyAndUpgradeLegacySignedMessage', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActionDispatch::Cookies::UpgradeLegacySignedCookieJar') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::SignedCookieJar', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Cookies::VerifyAndUpgradeLegacySignedMessage', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActionDispatch::Cookies::VerifyAndUpgradeLegacySignedMessage') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('verify_and_upgrade_legacy_signed_message') do |method|
      method.define_argument('name')
      method.define_argument('signed_message')
    end
  end

  defs.define_constant('ActionDispatch::DebugExceptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('routes_app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::DebugExceptions::RESCUES_TEMPLATE_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::ExceptionWrapper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('rescue_responses')

    klass.define_method('rescue_responses=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('rescue_templates')

    klass.define_method('rescue_templates=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('status_code_for_exception') do |method|
      method.define_argument('class_name')
    end

    klass.define_instance_method('application_trace')

    klass.define_instance_method('env')

    klass.define_instance_method('exception')

    klass.define_instance_method('file')

    klass.define_instance_method('framework_trace')

    klass.define_instance_method('full_trace')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')
      method.define_argument('exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('line_number')

    klass.define_instance_method('rescue_responses')

    klass.define_instance_method('rescue_responses=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('rescue_template')

    klass.define_instance_method('rescue_templates')

    klass.define_instance_method('rescue_templates=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('source_extract')

    klass.define_instance_method('status_code')
  end

  defs.define_constant('ActionDispatch::Flash') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Flash::FlashHash') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('from_session_value') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('k')
      method.define_argument('v')
    end

    klass.define_instance_method('alert')

    klass.define_instance_method('alert=') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('discard') do |method|
      method.define_optional_argument('k')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('flashes')
      method.define_optional_argument('discard')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keep') do |method|
      method.define_optional_argument('k')
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('keys')

    klass.define_instance_method('merge!') do |method|
      method.define_argument('h')
    end

    klass.define_instance_method('notice')

    klass.define_instance_method('notice=') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('now')

    klass.define_instance_method('now_is_loaded?')

    klass.define_instance_method('replace') do |method|
      method.define_argument('h')
    end

    klass.define_instance_method('sweep')

    klass.define_instance_method('to_hash')

    klass.define_instance_method('to_session_value')

    klass.define_instance_method('update') do |method|
      method.define_argument('h')
    end
  end

  defs.define_constant('ActionDispatch::Flash::FlashHash::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('ActionDispatch::Flash::FlashHash::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActionDispatch::Flash::FlashNow') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('k')
      method.define_argument('v')
    end

    klass.define_instance_method('alert=') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('flash')

    klass.define_instance_method('flash=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('flash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('notice=') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('ActionDispatch::Flash::KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Request') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('etag_matches?') do |method|
      method.define_argument('etag')
    end

    klass.define_instance_method('fresh?') do |method|
      method.define_argument('response')
    end

    klass.define_instance_method('if_modified_since')

    klass.define_instance_method('if_none_match')

    klass.define_instance_method('if_none_match_etags')

    klass.define_instance_method('not_modified?') do |method|
      method.define_argument('modified_at')
    end
  end

  defs.define_constant('ActionDispatch::Http::Cache::Request::HTTP_IF_MODIFIED_SINCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Request::HTTP_IF_NONE_MATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache_control')

    klass.define_instance_method('date')

    klass.define_instance_method('date=') do |method|
      method.define_argument('utc_time')
    end

    klass.define_instance_method('date?')

    klass.define_instance_method('etag')

    klass.define_instance_method('etag=') do |method|
      method.define_argument('etag')
    end

    klass.define_instance_method('etag?')

    klass.define_instance_method('last_modified')

    klass.define_instance_method('last_modified=') do |method|
      method.define_argument('utc_time')
    end

    klass.define_instance_method('last_modified?')
  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::CACHE_CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::DEFAULT_CACHE_CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::ETAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::LAST_MODIFIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::MUST_REVALIDATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::NO_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::PRIVATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::PUBLIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Cache::Response::SPECIAL_KEYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::FilterParameters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('env_filter')

    klass.define_instance_method('filtered_env')

    klass.define_instance_method('filtered_parameters')

    klass.define_instance_method('filtered_path')

    klass.define_instance_method('filtered_query_string')

    klass.define_instance_method('parameter_filter')

    klass.define_instance_method('parameter_filter_for') do |method|
      method.define_argument('filters')
    end
  end

  defs.define_constant('ActionDispatch::Http::FilterParameters::ENV_MATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::FilterParameters::KV_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::FilterParameters::NULL_ENV_FILTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::FilterParameters::NULL_PARAM_FILTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::FilterParameters::PAIR_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::FilterRedirect') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('filtered_location')
  end

  defs.define_constant('ActionDispatch::Http::FilterRedirect::FILTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Headers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('env')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('key')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('headers_or_env')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('headers_or_env')
    end
  end

  defs.define_constant('ActionDispatch::Http::Headers::CGI_VARIABLES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Headers::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('ActionDispatch::Http::Headers::HTTP_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Headers::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActionDispatch::Http::MimeNegotiation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accepts')

    klass.define_instance_method('content_mime_type')

    klass.define_instance_method('content_type')

    klass.define_instance_method('format') do |method|
      method.define_optional_argument('view_path')
    end

    klass.define_instance_method('format=') do |method|
      method.define_argument('extension')
    end

    klass.define_instance_method('formats')

    klass.define_instance_method('formats=') do |method|
      method.define_argument('extensions')
    end

    klass.define_instance_method('negotiate_mime') do |method|
      method.define_argument('order')
    end

    klass.define_instance_method('use_accept_header')

    klass.define_instance_method('valid_accept_header')
  end

  defs.define_constant('ActionDispatch::Http::MimeNegotiation::BROWSER_LIKE_ACCEPTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::ParameterFilter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('filter') do |method|
      method.define_argument('params')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('filters')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Http::ParameterFilter::CompiledFilter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('compile') do |method|
      method.define_argument('filters')
    end

    klass.define_instance_method('blocks')

    klass.define_instance_method('call') do |method|
      method.define_argument('original_params')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('regexps')
      method.define_argument('blocks')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('regexps')
  end

  defs.define_constant('ActionDispatch::Http::ParameterFilter::FILTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Parameters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('parameters')

    klass.define_instance_method('params')

    klass.define_instance_method('path_parameters')

    klass.define_instance_method('path_parameters=') do |method|
      method.define_argument('parameters')
    end

    klass.define_instance_method('reset_parameters')

    klass.define_instance_method('symbolized_path_parameters')
  end

  defs.define_constant('ActionDispatch::Http::URL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extract_domain') do |method|
      method.define_argument('host')
      method.define_optional_argument('tld_length')
    end

    klass.define_method('extract_subdomain') do |method|
      method.define_argument('host')
      method.define_optional_argument('tld_length')
    end

    klass.define_method('extract_subdomains') do |method|
      method.define_argument('host')
      method.define_optional_argument('tld_length')
    end

    klass.define_method('tld_length')

    klass.define_method('tld_length=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('url_for') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('domain') do |method|
      method.define_optional_argument('tld_length')
    end

    klass.define_instance_method('host')

    klass.define_instance_method('host_with_port')

    klass.define_instance_method('optional_port')

    klass.define_instance_method('port')

    klass.define_instance_method('port_string')

    klass.define_instance_method('protocol')

    klass.define_instance_method('raw_host_with_port')

    klass.define_instance_method('server_port')

    klass.define_instance_method('standard_port')

    klass.define_instance_method('standard_port?')

    klass.define_instance_method('subdomain') do |method|
      method.define_optional_argument('tld_length')
    end

    klass.define_instance_method('subdomains') do |method|
      method.define_optional_argument('tld_length')
    end

    klass.define_instance_method('tld_length')

    klass.define_instance_method('tld_length=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('url')
  end

  defs.define_constant('ActionDispatch::Http::URL::HOST_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::URL::IP_HOST_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::URL::PROTOCOL_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::Upload') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Http::UploadedFile') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('close') do |method|
      method.define_optional_argument('unlink_now')
    end

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type=')

    klass.define_instance_method('eof?')

    klass.define_instance_method('headers')

    klass.define_instance_method('headers=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('open')

    klass.define_instance_method('original_filename')

    klass.define_instance_method('original_filename=')

    klass.define_instance_method('path')

    klass.define_instance_method('read') do |method|
      method.define_optional_argument('length')
      method.define_optional_argument('buffer')
    end

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('tempfile')

    klass.define_instance_method('tempfile=')
  end

  defs.define_constant('ActionDispatch::IllegalStateError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Formatter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('clear')

    klass.define_instance_method('generate') do |method|
      method.define_argument('type')
      method.define_argument('name')
      method.define_argument('options')
      method.define_optional_argument('recall')
      method.define_optional_argument('parameterize')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('routes')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('routes')
  end

  defs.define_constant('ActionDispatch::Journey::GTG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::GTG::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('ast')

    klass.define_instance_method('endpoints')

    klass.define_instance_method('firstpos') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('followpos') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('root')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lastpos') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('nullable?') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('root')

    klass.define_instance_method('transition_table')
  end

  defs.define_constant('ActionDispatch::Journey::GTG::Builder::DUMMY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::GTG::MatchData') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('memos')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('memos')
  end

  defs.define_constant('ActionDispatch::Journey::GTG::Simulator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('=~') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('transition_table')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('simulate') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('tt')
  end

  defs.define_constant('ActionDispatch::Journey::GTG::TransitionTable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::NFA::Dot', RubyLint.registry))

    klass.define_instance_method('[]=') do |method|
      method.define_argument('from')
      method.define_argument('to')
      method.define_argument('sym')
    end

    klass.define_instance_method('accepting?') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('accepting_states')

    klass.define_instance_method('add_accepting') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('add_memo') do |method|
      method.define_argument('idx')
      method.define_argument('memo')
    end

    klass.define_instance_method('eclosure') do |method|
      method.define_argument('t')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('memo') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('memos')

    klass.define_instance_method('move') do |method|
      method.define_argument('t')
      method.define_argument('a')
    end

    klass.define_instance_method('states')

    klass.define_instance_method('to_json')

    klass.define_instance_method('to_svg')

    klass.define_instance_method('transitions')

    klass.define_instance_method('visualizer') do |method|
      method.define_argument('paths')
      method.define_optional_argument('title')
    end
  end

  defs.define_constant('ActionDispatch::Journey::NFA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::NFA::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('ast')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('transition_table')
  end

  defs.define_constant('ActionDispatch::Journey::NFA::Dot') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_dot')
  end

  defs.define_constant('ActionDispatch::Journey::NFA::MatchData') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('memos')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('memos')
  end

  defs.define_constant('ActionDispatch::Journey::NFA::Simulator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('=~') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('transition_table')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('simulate') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('tt')
  end

  defs.define_constant('ActionDispatch::Journey::NFA::TransitionTable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::NFA::Dot', RubyLint.registry))

    klass.define_instance_method('[]=') do |method|
      method.define_argument('i')
      method.define_argument('f')
      method.define_argument('s')
    end

    klass.define_instance_method('accepting')

    klass.define_instance_method('accepting=')

    klass.define_instance_method('accepting?') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('accepting_states')

    klass.define_instance_method('add_memo') do |method|
      method.define_argument('idx')
      method.define_argument('memo')
    end

    klass.define_instance_method('alphabet')

    klass.define_instance_method('eclosure') do |method|
      method.define_argument('t')
    end

    klass.define_instance_method('following_states') do |method|
      method.define_argument('t')
      method.define_argument('a')
    end

    klass.define_instance_method('generalized_table')

    klass.define_instance_method('initialize')

    klass.define_instance_method('memo') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('memos')

    klass.define_instance_method('merge') do |method|
      method.define_argument('left')
      method.define_argument('right')
    end

    klass.define_instance_method('move') do |method|
      method.define_argument('t')
      method.define_argument('a')
    end

    klass.define_instance_method('states')

    klass.define_instance_method('transitions')
  end

  defs.define_constant('ActionDispatch::Journey::NFA::Visitor') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('tt')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('terminal') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_CAT') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_GROUP') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_OR') do |method|
      method.define_argument('node')
    end
  end

  defs.define_constant('ActionDispatch::Journey::NFA::Visitor::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Nodes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Racc::Parser', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes', RubyLint.registry))

    klass.define_instance_method('_reduce_1') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_14') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_15') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_16') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_17') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_2') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_7') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_8') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_9') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_none') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('next_token')

    klass.define_instance_method('parse') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Binary') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('children')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_argument('right')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('right')

    klass.define_instance_method('right=')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Cat') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Binary', RubyLint.registry))

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Dot') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Terminal', RubyLint.registry))

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Dummy') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Literal', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('x')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('literal?')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Group') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Literal') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Terminal', RubyLint.registry))

    klass.define_instance_method('literal?')

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('left')

    klass.define_instance_method('left=')

    klass.define_instance_method('literal?')

    klass.define_instance_method('memo')

    klass.define_instance_method('memo=')

    klass.define_instance_method('name')

    klass.define_instance_method('symbol?')

    klass.define_instance_method('to_dot')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_sym')

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Or') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('children')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('children')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Main_Parsing_Routine') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Core_Id_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Core_Revision') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Core_Revision_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Core_Revision_R') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Core_Version') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Core_Version_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Core_Version_R') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Revision') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Type') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_Runtime_Version') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_YY_Parse_Method') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_arg') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_debug_parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Racc_token_to_s_table') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Parser::Slash') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Terminal', RubyLint.registry))

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Star') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Symbol') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Terminal', RubyLint.registry))

    klass.define_instance_method('default_regexp?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('regexp')

    klass.define_instance_method('regexp=')

    klass.define_instance_method('symbol')

    klass.define_instance_method('symbol?')

    klass.define_instance_method('type')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Terminal') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('symbol')
  end

  defs.define_constant('ActionDispatch::Journey::Parser::Unary') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('children')
  end

  defs.define_constant('ActionDispatch::Journey::Path') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('=~') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('anchored')

    klass.define_instance_method('ast')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('strexp')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('names')

    klass.define_instance_method('optional_names')

    klass.define_instance_method('required_names')

    klass.define_instance_method('requirements')

    klass.define_instance_method('source')

    klass.define_instance_method('spec')

    klass.define_instance_method('to_regexp')
  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern::AnchoredRegexp') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('separator')
      method.define_argument('matchers')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('visit_CAT') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_DOT') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_GROUP') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_LITERAL') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_SLASH') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_STAR') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_SYMBOL') do |method|
      method.define_argument('node')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern::AnchoredRegexp::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern::MatchData') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('captures')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('names')
      method.define_argument('offsets')
      method.define_argument('match')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('length')

    klass.define_instance_method('names')

    klass.define_instance_method('post_match')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern::RegexpOffsets') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('matchers')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('offsets')

    klass.define_instance_method('visit') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_SYMBOL') do |method|
      method.define_argument('node')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern::RegexpOffsets::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern::UnanchoredRegexp') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Path::Pattern::AnchoredRegexp', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('node')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Path::Pattern::UnanchoredRegexp::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Route') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('app')

    klass.define_instance_method('ast')

    klass.define_instance_method('conditions')

    klass.define_instance_method('constraints')

    klass.define_instance_method('defaults')

    klass.define_instance_method('dispatcher?')

    klass.define_instance_method('format') do |method|
      method.define_argument('path_options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('app')
      method.define_argument('path')
      method.define_argument('constraints')
      method.define_optional_argument('defaults')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ip')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('request')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('optimized_path')

    klass.define_instance_method('optional_parts')

    klass.define_instance_method('parts')

    klass.define_instance_method('path')

    klass.define_instance_method('precedence')

    klass.define_instance_method('precedence=')

    klass.define_instance_method('required_default?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('required_defaults')

    klass.define_instance_method('required_keys')

    klass.define_instance_method('required_parts')

    klass.define_instance_method('requirements')

    klass.define_instance_method('score') do |method|
      method.define_argument('constraints')
    end

    klass.define_instance_method('segment_keys')

    klass.define_instance_method('segments')

    klass.define_instance_method('verb')
  end

  defs.define_constant('ActionDispatch::Journey::Router') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('formatter')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('routes')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recognize') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('request_class')

    klass.define_instance_method('routes')

    klass.define_instance_method('routes=')

    klass.define_instance_method('visualizer')
  end

  defs.define_constant('ActionDispatch::Journey::Router::NullReq') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('env')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ip')

    klass.define_instance_method('path_info')

    klass.define_instance_method('request_method')
  end

  defs.define_constant('ActionDispatch::Journey::Router::RoutingError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Router::Strexp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('compile') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('anchor')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')
      method.define_argument('requirements')
      method.define_argument('separators')
      method.define_optional_argument('anchor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('names')

    klass.define_instance_method('path')

    klass.define_instance_method('requirements')

    klass.define_instance_method('separators')
  end

  defs.define_constant('ActionDispatch::Journey::Router::Utils') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('escape_fragment') do |method|
      method.define_argument('fragment')
    end

    klass.define_method('escape_path') do |method|
      method.define_argument('path')
    end

    klass.define_method('normalize_path') do |method|
      method.define_argument('path')
    end

    klass.define_method('unescape_uri') do |method|
      method.define_argument('uri')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Router::Utils::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Router::Utils::UriEscape') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Router::Utils::UriEscape::UNSAFE_FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Router::Utils::UriEscape::UNSAFE_SEGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Router::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Routes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('add_route') do |method|
      method.define_argument('app')
      method.define_argument('path')
      method.define_argument('conditions')
      method.define_argument('defaults')
      method.define_optional_argument('name')
    end

    klass.define_instance_method('ast')

    klass.define_instance_method('clear')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('named_routes')

    klass.define_instance_method('partitioned_routes')

    klass.define_instance_method('routes')

    klass.define_instance_method('simulator')

    klass.define_instance_method('size')
  end

  defs.define_constant('ActionDispatch::Journey::Routes::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Routes::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActionDispatch::Journey::Scanner') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('eos?')

    klass.define_instance_method('initialize')

    klass.define_instance_method('next_token')

    klass.define_instance_method('pos')

    klass.define_instance_method('pre_match')

    klass.define_instance_method('scan_setup') do |method|
      method.define_argument('str')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Visitors') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Dot') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Dot::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Each') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('visit') do |method|
      method.define_argument('node')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Each::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Formatter') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('consumed')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')
  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Formatter::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::OptimizedPath') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::String', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::OptimizedPath::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::String') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Journey::Visitors::Visitor', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::String::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Visitor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_DOT') do |method|
      method.define_argument('n')
    end

    klass.define_instance_method('visit_LITERAL') do |method|
      method.define_argument('n')
    end

    klass.define_instance_method('visit_SLASH') do |method|
      method.define_argument('n')
    end

    klass.define_instance_method('visit_SYMBOL') do |method|
      method.define_argument('n')
    end
  end

  defs.define_constant('ActionDispatch::Journey::Visitors::Visitor::DISPATCH_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::MiddlewareStack') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('i')
    end

    klass.define_instance_method('assert_index') do |method|
      method.define_argument('index')
      method.define_argument('where')
    end

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('app')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('target')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('index')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('insert_after') do |method|
      method.define_argument('index')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('insert_before') do |method|
      method.define_argument('index')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('middlewares')

    klass.define_instance_method('middlewares=')

    klass.define_instance_method('size')

    klass.define_instance_method('swap') do |method|
      method.define_argument('target')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('unshift') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('use') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionDispatch::MiddlewareStack::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('ActionDispatch::MiddlewareStack::Middleware') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('middleware')
    end

    klass.define_instance_method('args')

    klass.define_instance_method('block')

    klass.define_instance_method('build') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('classcache')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass_or_name')
      method.define_rest_argument('args')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('klass')

    klass.define_instance_method('name')
  end

  defs.define_constant('ActionDispatch::MiddlewareStack::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActionDispatch::ParamsParser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('parsers')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::ParamsParser::DEFAULT_PARSERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::ParamsParser::ParseError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('message')
      method.define_argument('original_exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('original_exception')
  end

  defs.define_constant('ActionDispatch::PublicExceptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('public_path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('public_path')

    klass.define_instance_method('public_path=')
  end

  defs.define_constant('ActionDispatch::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Railtie::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('configure') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('instance')

    klass.define_instance_method('method_missing') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionDispatch::Railtie::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('ActionDispatch::Railtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Railtie::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('eager_load_namespaces')

    klass.define_instance_method('after_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('app_generators')

    klass.define_instance_method('app_middleware')

    klass.define_instance_method('before_configuration') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_eager_load') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('eager_load_namespaces')

    klass.define_instance_method('initialize')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('to_prepare') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('to_prepare_blocks')

    klass.define_instance_method('watchable_dirs')

    klass.define_instance_method('watchable_files')
  end

  defs.define_constant('ActionDispatch::Railtie::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionDispatch::Reloader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Callbacks', RubyLint.registry))

    klass.define_method('_cleanup_callbacks')

    klass.define_method('_cleanup_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_cleanup_callbacks?')

    klass.define_method('_prepare_callbacks')

    klass.define_method('_prepare_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_prepare_callbacks?')

    klass.define_method('cleanup!')

    klass.define_method('prepare!')

    klass.define_method('to_cleanup') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('to_prepare') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('_cleanup_callbacks')

    klass.define_instance_method('_cleanup_callbacks=')

    klass.define_instance_method('_cleanup_callbacks?')

    klass.define_instance_method('_prepare_callbacks')

    klass.define_instance_method('_prepare_callbacks=')

    klass.define_instance_method('_prepare_callbacks?')

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('cleanup!')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('condition')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('prepare!')
  end

  defs.define_constant('ActionDispatch::Reloader::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Reloader::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActionDispatch::Reloader::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActionDispatch::Reloader::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__callback_runner_name_cache')

    klass.define_instance_method('__define_callbacks') do |method|
      method.define_argument('kind')
      method.define_argument('object')
    end

    klass.define_instance_method('__generate_callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__reset_runner') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('__update_callbacks') do |method|
      method.define_argument('name')
      method.define_optional_argument('filters')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('define_callbacks') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('reset_callbacks') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('set_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end

    klass.define_instance_method('skip_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionDispatch::RemoteIp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('check_ip')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('check_ip_spoofing')
      method.define_optional_argument('custom_proxies')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('proxies')
  end

  defs.define_constant('ActionDispatch::RemoteIp::GetIp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('calculate_ip')

    klass.define_instance_method('filter_proxies') do |method|
      method.define_argument('ips')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')
      method.define_argument('middleware')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ips_from') do |method|
      method.define_argument('header')
    end

    klass.define_instance_method('to_s')
  end

  defs.define_constant('ActionDispatch::RemoteIp::GetIp::VALID_IP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::RemoteIp::IpSpoofAttackError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::RemoteIp::TRUSTED_PROXIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Request', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::URL', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::Upload', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::FilterParameters', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::Parameters', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::MimeNegotiation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::Cache::Request', RubyLint.registry))

    klass.define_method('ignore_accept_header')

    klass.define_method('ignore_accept_header=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('GET')

    klass.define_instance_method('POST')

    klass.define_instance_method('accept')

    klass.define_instance_method('accept_charset')

    klass.define_instance_method('accept_encoding')

    klass.define_instance_method('accept_language')

    klass.define_instance_method('auth_type')

    klass.define_instance_method('authorization')

    klass.define_instance_method('body')

    klass.define_instance_method('body_stream')

    klass.define_instance_method('cache_control')

    klass.define_instance_method('content_length')

    klass.define_instance_method('cookie_jar')

    klass.define_instance_method('deep_munge') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('delete?')

    klass.define_instance_method('flash')

    klass.define_instance_method('form_data?')

    klass.define_instance_method('from')

    klass.define_instance_method('fullpath')

    klass.define_instance_method('gateway_interface')

    klass.define_instance_method('get?')

    klass.define_instance_method('head?')

    klass.define_instance_method('headers')

    klass.define_instance_method('ignore_accept_header')

    klass.define_instance_method('ignore_accept_header=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ip')

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('local?')

    klass.define_instance_method('media_type')

    klass.define_instance_method('method')

    klass.define_instance_method('method_symbol')

    klass.define_instance_method('negotiate')

    klass.define_instance_method('original_fullpath')

    klass.define_instance_method('original_url')

    klass.define_instance_method('parse_query') do |method|
      method.define_argument('qs')
    end

    klass.define_instance_method('patch?')

    klass.define_instance_method('path_translated')

    klass.define_instance_method('post?')

    klass.define_instance_method('pragma')

    klass.define_instance_method('put?')

    klass.define_instance_method('query_parameters')

    klass.define_instance_method('raw_post')

    klass.define_instance_method('remote_addr')

    klass.define_instance_method('remote_host')

    klass.define_instance_method('remote_ident')

    klass.define_instance_method('remote_ip')

    klass.define_instance_method('remote_user')

    klass.define_instance_method('request_method')

    klass.define_instance_method('request_method_symbol')

    klass.define_instance_method('request_parameters')

    klass.define_instance_method('reset_session')

    klass.define_instance_method('server_name')

    klass.define_instance_method('server_protocol')

    klass.define_instance_method('server_software')

    klass.define_instance_method('session=') do |method|
      method.define_argument('session')
    end

    klass.define_instance_method('session_options=') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('uuid')

    klass.define_instance_method('xhr?')

    klass.define_instance_method('xml_http_request?')
  end

  defs.define_constant('ActionDispatch::Request::BROWSER_LIKE_ACCEPTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::DEFAULT_PORTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::ENV_MATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::ENV_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::FORM_DATA_MEDIA_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::HOST_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::HTTP_IF_MODIFIED_SINCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::HTTP_IF_NONE_MATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::HTTP_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::HTTP_METHOD_LOOKUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::IP_HOST_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::KV_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::LOCALHOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::NULL_ENV_FILTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::NULL_PARAM_FILTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::PAIR_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::PARSEABLE_DATA_MEDIA_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::PROTOCOL_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::RFC2518') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::RFC2616') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::RFC3253') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::RFC3648') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::RFC3744') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::RFC5323') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::RFC5789') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::Session') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('store')
      method.define_argument('env')
      method.define_argument('default_options')
    end

    klass.define_method('find') do |method|
      method.define_argument('env')
    end

    klass.define_method('set') do |method|
      method.define_argument('env')
      method.define_argument('session')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('destroy')

    klass.define_instance_method('empty?')

    klass.define_instance_method('exists?')

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('id')

    klass.define_instance_method('include?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('by')
      method.define_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('keys')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('to_hash')

    klass.define_instance_method('update') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('values')
  end

  defs.define_constant('ActionDispatch::Request::Session::ENV_SESSION_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::Session::ENV_SESSION_OPTIONS_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Request::Session::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('find') do |method|
      method.define_argument('env')
    end

    klass.define_method('set') do |method|
      method.define_argument('env')
      method.define_argument('options')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('k')
      method.define_argument('v')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('by')
      method.define_argument('env')
      method.define_argument('default_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_hash')

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionDispatch::RequestId') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Response') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('MonitorMixin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::Cache::Response', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Http::FilterRedirect', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rack::Response::Helpers', RubyLint.registry))

    klass.define_method('default_charset')

    klass.define_method('default_charset=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('default_headers')

    klass.define_method('default_headers=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('await_commit')

    klass.define_instance_method('body')

    klass.define_instance_method('body=') do |method|
      method.define_argument('body')
    end

    klass.define_instance_method('body_parts')

    klass.define_instance_method('charset')

    klass.define_instance_method('charset=')

    klass.define_instance_method('close')

    klass.define_instance_method('code')

    klass.define_instance_method('commit!')

    klass.define_instance_method('committed?')

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type=') do |method|
      method.define_argument('content_type')
    end

    klass.define_instance_method('cookies')

    klass.define_instance_method('default_charset')

    klass.define_instance_method('default_charset=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('default_headers')

    klass.define_instance_method('default_headers=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('delete_cookie') do |method|
      method.define_argument('key')
      method.define_optional_argument('value')
    end

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('header')

    klass.define_instance_method('header=')

    klass.define_instance_method('headers')

    klass.define_instance_method('headers=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('status')
      method.define_optional_argument('header')
      method.define_optional_argument('body')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('location')

    klass.define_instance_method('location=') do |method|
      method.define_argument('url')
    end

    klass.define_instance_method('message')

    klass.define_instance_method('prepare!')

    klass.define_instance_method('redirect_url')

    klass.define_instance_method('request')

    klass.define_instance_method('request=')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('method')
    end

    klass.define_instance_method('response_code')

    klass.define_instance_method('sending_file=')

    klass.define_instance_method('set_cookie') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('status')

    klass.define_instance_method('status=') do |method|
      method.define_argument('status')
    end

    klass.define_instance_method('status_message')

    klass.define_instance_method('stream')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('to_path')
  end

  defs.define_constant('ActionDispatch::Response::Buffer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('response')
      method.define_argument('buf')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('ActionDispatch::Response::CACHE_CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::CONTENT_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('monitor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('wait_until')

    klass.define_instance_method('wait_while')
  end

  defs.define_constant('ActionDispatch::Response::DEFAULT_CACHE_CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::ETAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::FILTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::LAST_MODIFIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::LOCATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::MUST_REVALIDATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::NO_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::NO_CONTENT_CODES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::PRIVATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::PUBLIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::SET_COOKIE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Response::SPECIAL_KEYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::SSL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('default_hsts_options')

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::SSL::YEAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Session') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Session::AbstractStore') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Session::Abstract::ID', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::SessionObject', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::StaleSessionCheck', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::Compatibility', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Session::AbstractStore::DEFAULT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Session::CacheStore') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::AbstractStore', RubyLint.registry))

    klass.define_instance_method('destroy_session') do |method|
      method.define_argument('env')
      method.define_argument('sid')
      method.define_argument('options')
    end

    klass.define_instance_method('get_session') do |method|
      method.define_argument('env')
      method.define_argument('sid')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('set_session') do |method|
      method.define_argument('env')
      method.define_argument('sid')
      method.define_argument('session')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActionDispatch::Session::CacheStore::DEFAULT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Session::CookieStore') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Session::Abstract::ID', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::SessionObject', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::StaleSessionCheck', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::Compatibility', RubyLint.registry))

    klass.define_instance_method('destroy_session') do |method|
      method.define_argument('env')
      method.define_argument('session_id')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load_session') do |method|
      method.define_argument('env')
    end
  end

  defs.define_constant('ActionDispatch::Session::CookieStore::DEFAULT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Session::MemCacheStore') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Session::Dalli', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::SessionObject', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::StaleSessionCheck', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Session::Compatibility', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::Session::MemCacheStore::DEFAULT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::ShowExceptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_argument('exceptions_app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::ShowExceptions::FAILSAFE_RESPONSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::Static') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_argument('path')
      method.define_optional_argument('cache_control')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionDispatch::TestProcess') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assigns') do |method|
      method.define_optional_argument('key')
    end

    klass.define_instance_method('cookies')

    klass.define_instance_method('fixture_file_upload') do |method|
      method.define_argument('path')
      method.define_optional_argument('mime_type')
      method.define_optional_argument('binary')
    end

    klass.define_instance_method('flash')

    klass.define_instance_method('redirect_to_url')

    klass.define_instance_method('session')
  end

  defs.define_constant('ActionDispatch::TestRequest') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Request', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_optional_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('accept=') do |method|
      method.define_argument('mime_types')
    end

    klass.define_instance_method('action=') do |method|
      method.define_argument('action_name')
    end

    klass.define_instance_method('cookies')

    klass.define_instance_method('host=') do |method|
      method.define_argument('host')
    end

    klass.define_instance_method('if_modified_since=') do |method|
      method.define_argument('last_modified')
    end

    klass.define_instance_method('if_none_match=') do |method|
      method.define_argument('etag')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('path=') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('port=') do |method|
      method.define_argument('number')
    end

    klass.define_instance_method('rack_cookies')

    klass.define_instance_method('remote_addr=') do |method|
      method.define_argument('addr')
    end

    klass.define_instance_method('request_method=') do |method|
      method.define_argument('method')
    end

    klass.define_instance_method('request_uri=') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('user_agent=') do |method|
      method.define_argument('user_agent')
    end
  end

  defs.define_constant('ActionDispatch::TestRequest::BROWSER_LIKE_ACCEPTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::DEFAULT_ENV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::DEFAULT_PORTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::ENV_MATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::ENV_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::FORM_DATA_MEDIA_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::HOST_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::HTTP_IF_MODIFIED_SINCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::HTTP_IF_NONE_MATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::HTTP_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::HTTP_METHOD_LOOKUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::IP_HOST_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::KV_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::LOCALHOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::NULL_ENV_FILTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::NULL_PARAM_FILTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::PAIR_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::PARSEABLE_DATA_MEDIA_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::PROTOCOL_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::RFC2518') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::RFC2616') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::RFC3253') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::RFC3648') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::RFC3744') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::RFC5323') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::RFC5789') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestRequest::Session') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('store')
      method.define_argument('env')
      method.define_argument('default_options')
    end

    klass.define_method('find') do |method|
      method.define_argument('env')
    end

    klass.define_method('set') do |method|
      method.define_argument('env')
      method.define_argument('session')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('destroy')

    klass.define_instance_method('empty?')

    klass.define_instance_method('exists?')

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('id')

    klass.define_instance_method('include?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('by')
      method.define_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('keys')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('to_hash')

    klass.define_instance_method('update') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('values')
  end

  defs.define_constant('ActionDispatch::TestResponse') do |klass|
    klass.inherits(defs.constant_proxy('ActionDispatch::Response', RubyLint.registry))

    klass.define_method('from_response') do |method|
      method.define_argument('response')
    end

    klass.define_instance_method('error?')

    klass.define_instance_method('missing?')

    klass.define_instance_method('redirect?')

    klass.define_instance_method('success?')
  end

  defs.define_constant('ActionDispatch::TestResponse::Buffer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('response')
      method.define_argument('buf')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('ActionDispatch::TestResponse::CACHE_CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::CONTENT_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('monitor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('wait_until')

    klass.define_instance_method('wait_while')
  end

  defs.define_constant('ActionDispatch::TestResponse::DEFAULT_CACHE_CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::ETAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::FILTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::LAST_MODIFIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::LOCATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::MUST_REVALIDATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::NO_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::NO_CONTENT_CODES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::PRIVATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::PUBLIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::SET_COOKIE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionDispatch::TestResponse::SPECIAL_KEYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
