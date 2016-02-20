# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('ActiveModel') do |defs|
  defs.define_constant('ActiveModel') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('version')

    klass.define_instance_method('eager_load!')
  end

  defs.define_constant('ActiveModel::AttributeMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attribute_method?') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('attribute_missing') do |method|
      method.define_argument('match')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('method')
      method.define_optional_argument('include_private_methods')
    end

    klass.define_instance_method('respond_to_without_attributes?') do |method|
      method.define_argument('meth')
      method.define_optional_argument('include_private')
    end
  end

  defs.define_constant('ActiveModel::AttributeMethods::CALL_COMPILABLE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alias_attribute') do |method|
      method.define_argument('new_name')
      method.define_argument('old_name')
    end

    klass.define_instance_method('attribute_method_affix') do |method|
      method.define_rest_argument('affixes')
    end

    klass.define_instance_method('attribute_method_prefix') do |method|
      method.define_rest_argument('prefixes')
    end

    klass.define_instance_method('attribute_method_suffix') do |method|
      method.define_rest_argument('suffixes')
    end

    klass.define_instance_method('define_attribute_method') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('define_attribute_methods') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('generated_attribute_methods')

    klass.define_instance_method('instance_method_already_implemented?') do |method|
      method.define_argument('method_name')
    end

    klass.define_instance_method('undefine_attribute_methods')
  end

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match') do |method|
      method.define_argument('method_name')
    end

    klass.define_instance_method('method_missing_target')

    klass.define_instance_method('method_name') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('plain?')

    klass.define_instance_method('prefix')

    klass.define_instance_method('suffix')
  end

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('attr_name')

    klass.define_instance_method('attr_name=')

    klass.define_instance_method('method_name')

    klass.define_instance_method('method_name=')

    klass.define_instance_method('target')

    klass.define_instance_method('target=')
  end

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch::Enumerator') do |klass|
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

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch::SortedElement') do |klass|
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

  defs.define_constant('ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch::Tms') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('cstime')

    klass.define_instance_method('cstime=')

    klass.define_instance_method('cutime')

    klass.define_instance_method('cutime=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('utime')
      method.define_optional_argument('stime')
      method.define_optional_argument('cutime')
      method.define_optional_argument('cstime')
      method.define_optional_argument('tutime')
      method.define_optional_argument('tstime')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('stime')

    klass.define_instance_method('stime=')

    klass.define_instance_method('tstime')

    klass.define_instance_method('tstime=')

    klass.define_instance_method('tutime')

    klass.define_instance_method('tutime=')

    klass.define_instance_method('utime')

    klass.define_instance_method('utime=')
  end

  defs.define_constant('ActiveModel::AttributeMethods::NAME_COMPILABLE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::BlockValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveModel::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extended') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('define_model_callbacks') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActiveModel::Conversion') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_key')

    klass.define_instance_method('to_model')

    klass.define_instance_method('to_param')

    klass.define_instance_method('to_partial_path')
  end

  defs.define_constant('ActiveModel::Conversion::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_to_partial_path')
  end

  defs.define_constant('ActiveModel::DeprecatedMassAssignmentSecurity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::DeprecatedMassAssignmentSecurity::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attr_accessible') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('attr_protected') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveModel::Dirty') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('changed')

    klass.define_instance_method('changed?')

    klass.define_instance_method('changed_attributes')

    klass.define_instance_method('changes')

    klass.define_instance_method('previous_changes')
  end

  defs.define_constant('ActiveModel::EachValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::Validator', RubyLint.registry))

    klass.define_instance_method('attributes')

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('validate') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Errors') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('attribute')
      method.define_argument('error')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('message')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_on_blank') do |method|
      method.define_argument('attributes')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_on_empty') do |method|
      method.define_argument('attributes')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('added?') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('message')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('blank?')

    klass.define_instance_method('clear')

    klass.define_instance_method('count')

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('full_message') do |method|
      method.define_argument('attribute')
      method.define_argument('message')
    end

    klass.define_instance_method('full_messages')

    klass.define_instance_method('full_messages_for') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('generate_message') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('get') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keys')

    klass.define_instance_method('messages')

    klass.define_instance_method('set') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_hash') do |method|
      method.define_optional_argument('full_messages')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('values')
  end

  defs.define_constant('ActiveModel::Errors::CALLBACKS_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Errors::Enumerator') do |klass|
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

  defs.define_constant('ActiveModel::Errors::SortedElement') do |klass|
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

  defs.define_constant('ActiveModel::ForbiddenAttributesError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::ForbiddenAttributesProtection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('sanitize_for_mass_assignment') do |method|
      method.define_argument('attributes')
    end
  end

  defs.define_constant('ActiveModel::Lint') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Lint::Tests') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('test_errors_aref')

    klass.define_instance_method('test_model_naming')

    klass.define_instance_method('test_persisted?')

    klass.define_instance_method('test_to_key')

    klass.define_instance_method('test_to_param')

    klass.define_instance_method('test_to_partial_path')
  end

  defs.define_constant('ActiveModel::MissingAttributeError') do |klass|
    klass.inherits(defs.constant_proxy('NoMethodError', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Model') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('persisted?')
  end

  defs.define_constant('ActiveModel::Name') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_instance_method('!~') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('=~') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_key')

    klass.define_instance_method('collection')

    klass.define_instance_method('element')

    klass.define_instance_method('eql?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('human') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('i18n_key')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_optional_argument('namespace')
      method.define_optional_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('param_key')

    klass.define_instance_method('plural')

    klass.define_instance_method('route_key')

    klass.define_instance_method('singular')

    klass.define_instance_method('singular_route_key')

    klass.define_instance_method('to_s') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_str') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveModel::Naming') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('param_key') do |method|
      method.define_argument('record_or_class')
    end

    klass.define_method('plural') do |method|
      method.define_argument('record_or_class')
    end

    klass.define_method('route_key') do |method|
      method.define_argument('record_or_class')
    end

    klass.define_method('singular') do |method|
      method.define_argument('record_or_class')
    end

    klass.define_method('singular_route_key') do |method|
      method.define_argument('record_or_class')
    end

    klass.define_method('uncountable?') do |method|
      method.define_argument('record_or_class')
    end

    klass.define_instance_method('model_name')
  end

  defs.define_constant('ActiveModel::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Railtie::ClassMethods') do |klass|
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

  defs.define_constant('ActiveModel::Railtie::Collection') do |klass|
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

  defs.define_constant('ActiveModel::Railtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Railtie::Configuration') do |klass|
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

  defs.define_constant('ActiveModel::Railtie::Initializer') do |klass|
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

  defs.define_constant('ActiveModel::SecurePassword') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('min_cost')

    klass.define_method('min_cost=')
  end

  defs.define_constant('ActiveModel::SecurePassword::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('has_secure_password') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveModel::SecurePassword::InstanceMethodsOnActivation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('authenticate') do |method|
      method.define_argument('unencrypted_password')
    end

    klass.define_instance_method('password=') do |method|
      method.define_argument('unencrypted_password')
    end

    klass.define_instance_method('password_confirmation=') do |method|
      method.define_argument('unencrypted_password')
    end
  end

  defs.define_constant('ActiveModel::Serialization') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('read_attribute_for_serialization') do |method|
      method.define_argument('message')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('serializable_hash') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveModel::Serializers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Serializers::JSON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('from_json') do |method|
      method.define_argument('json')
      method.define_optional_argument('include_root')
    end
  end

  defs.define_constant('ActiveModel::Serializers::Xml') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('from_xml') do |method|
      method.define_argument('xml')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveModel::Serializers::Xml::Serializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('serializable')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('serializable_collection')

    klass.define_instance_method('serializable_hash')

    klass.define_instance_method('serialize')
  end

  defs.define_constant('ActiveModel::Serializers::Xml::Serializer::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('compute_type')

    klass.define_instance_method('decorations')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('serializable')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('type')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActiveModel::Serializers::Xml::Serializer::MethodAttribute') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::Serializers::Xml::Serializer::Attribute', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::StrictValidationFailed') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::TestCase') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::TestCase', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::TestCase::Assertion') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::TestCase::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::TestCase::Callback') do |klass|
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

  defs.define_constant('ActiveModel::TestCase::CallbackChain') do |klass|
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

  defs.define_constant('ActiveModel::TestCase::ClassMethods') do |klass|
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

  defs.define_constant('ActiveModel::TestCase::PASSTHROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::TestCase::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('ActiveModel::Translation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('human_attribute_name') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('i18n_scope')

    klass.define_instance_method('lookup_ancestors')
  end

  defs.define_constant('ActiveModel::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::VERSION::MAJOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::VERSION::MINOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::VERSION::PRE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::VERSION::STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::VERSION::TINY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('errors')

    klass.define_instance_method('invalid?') do |method|
      method.define_optional_argument('context')
    end

    klass.define_instance_method('read_attribute_for_validation') do |method|
      method.define_argument('message')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('run_validations!')

    klass.define_instance_method('valid?') do |method|
      method.define_optional_argument('context')
    end

    klass.define_instance_method('validates_with') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveModel::Validations::AbsenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::AcceptanceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('run_validations!')
  end

  defs.define_constant('ActiveModel::Validations::Callbacks::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_validation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_validation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveModel::Validations::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_parse_validates_options') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('_validates_default_keys')

    klass.define_instance_method('attribute_method?') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('clear_validators!')

    klass.define_instance_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('validate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('validates') do |method|
      method.define_rest_argument('attributes')
    end

    klass.define_instance_method('validates!') do |method|
      method.define_rest_argument('attributes')
    end

    klass.define_instance_method('validates_each') do |method|
      method.define_rest_argument('attr_names')
      method.define_block_argument('block')
    end

    klass.define_instance_method('validates_with') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('validators')

    klass.define_instance_method('validators_on') do |method|
      method.define_rest_argument('attributes')
    end
  end

  defs.define_constant('ActiveModel::Validations::Clusivity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('check_validity!')
  end

  defs.define_constant('ActiveModel::Validations::Clusivity::ERROR_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::ConfirmationValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::ExclusionValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::Clusivity', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::ExclusionValidator::ERROR_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::FormatValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::HelperMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validates_absence_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_acceptance_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_confirmation_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_exclusion_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_format_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_inclusion_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_length_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_numericality_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_presence_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_size_of') do |method|
      method.define_rest_argument('attr_names')
    end
  end

  defs.define_constant('ActiveModel::Validations::InclusionValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::Clusivity', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::InclusionValidator::ERROR_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::LengthValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::LengthValidator::CHECKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::LengthValidator::MESSAGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::LengthValidator::RESERVED_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::NumericalityValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('filtered_options') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('parse_raw_value_as_a_number') do |method|
      method.define_argument('raw_value')
    end

    klass.define_instance_method('parse_raw_value_as_an_integer') do |method|
      method.define_argument('raw_value')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::NumericalityValidator::CHECKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::NumericalityValidator::RESERVED_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveModel::Validations::PresenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveModel::Validations::WithValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr')
      method.define_argument('val')
    end
  end

  defs.define_constant('ActiveModel::Validator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('kind')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('options')

    klass.define_instance_method('validate') do |method|
      method.define_argument('record')
    end
  end
end
