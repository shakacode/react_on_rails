# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('JSON') do |defs|
  defs.define_constant('JSON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_argument('object')
      method.define_optional_argument('opts')
    end

    klass.define_method('const_defined_in?') do |method|
      method.define_argument('modul')
      method.define_argument('constant')
    end

    klass.define_method('create_id')

    klass.define_method('create_id=')

    klass.define_method('deep_const_get') do |method|
      method.define_argument('path')
    end

    klass.define_method('dump') do |method|
      method.define_argument('obj')
      method.define_optional_argument('anIO')
      method.define_optional_argument('limit')
    end

    klass.define_method('dump_default_options')

    klass.define_method('dump_default_options=')

    klass.define_method('fast_generate') do |method|
      method.define_argument('obj')
      method.define_optional_argument('opts')
    end

    klass.define_method('fast_unparse') do |method|
      method.define_argument('obj')
      method.define_optional_argument('opts')
    end

    klass.define_method('generate') do |method|
      method.define_argument('obj')
      method.define_optional_argument('opts')
    end

    klass.define_method('generator')

    klass.define_method('generator=') do |method|
      method.define_argument('generator')
    end

    klass.define_method('iconv') do |method|
      method.define_argument('to')
      method.define_argument('from')
      method.define_argument('string')
    end

    klass.define_method('load') do |method|
      method.define_argument('source')
      method.define_optional_argument('proc')
      method.define_optional_argument('options')
    end

    klass.define_method('load_default_options')

    klass.define_method('load_default_options=')

    klass.define_method('parse') do |method|
      method.define_argument('source')
      method.define_optional_argument('opts')
    end

    klass.define_method('parse!') do |method|
      method.define_argument('source')
      method.define_optional_argument('opts')
    end

    klass.define_method('parser')

    klass.define_method('parser=') do |method|
      method.define_argument('parser')
    end

    klass.define_method('pretty_generate') do |method|
      method.define_argument('obj')
      method.define_optional_argument('opts')
    end

    klass.define_method('pretty_unparse') do |method|
      method.define_argument('obj')
      method.define_optional_argument('opts')
    end

    klass.define_method('recurse_proc') do |method|
      method.define_argument('result')
      method.define_block_argument('proc')
    end

    klass.define_method('restore') do |method|
      method.define_argument('source')
      method.define_optional_argument('proc')
      method.define_optional_argument('options')
    end

    klass.define_method('state')

    klass.define_method('state=')

    klass.define_method('swap!') do |method|
      method.define_argument('string')
    end

    klass.define_method('unparse') do |method|
      method.define_argument('obj')
      method.define_optional_argument('opts')
    end
  end

  defs.define_constant('JSON::CircularDatastructure') do |klass|
    klass.inherits(defs.constant_proxy('JSON::NestingError', RubyLint.registry))

  end

  defs.define_constant('JSON::Ext') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::Ext::Generator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::Array') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::Bignum') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::FalseClass') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::Fixnum') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::Float') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::Hash') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::NilClass') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::Object') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::String') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included')

    klass.define_instance_method('to_json')

    klass.define_instance_method('to_json_raw')

    klass.define_instance_method('to_json_raw_object')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::String::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('JSON::Ext::Generator::GeneratorMethods::TrueClass') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_json')
  end

  defs.define_constant('JSON::Ext::Generator::State') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('from_state')

    klass.define_instance_method('[]')

    klass.define_instance_method('[]=')

    klass.define_instance_method('allow_nan?')

    klass.define_instance_method('array_nl')

    klass.define_instance_method('array_nl=')

    klass.define_instance_method('ascii_only?')

    klass.define_instance_method('buffer_initial_length')

    klass.define_instance_method('buffer_initial_length=')

    klass.define_instance_method('check_circular?')

    klass.define_instance_method('configure')

    klass.define_instance_method('depth')

    klass.define_instance_method('depth=')

    klass.define_instance_method('generate')

    klass.define_instance_method('indent')

    klass.define_instance_method('indent=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('max_nesting')

    klass.define_instance_method('max_nesting=')

    klass.define_instance_method('merge')

    klass.define_instance_method('object_nl')

    klass.define_instance_method('object_nl=')

    klass.define_instance_method('quirks_mode')

    klass.define_instance_method('quirks_mode=')

    klass.define_instance_method('quirks_mode?')

    klass.define_instance_method('space')

    klass.define_instance_method('space=')

    klass.define_instance_method('space_before')

    klass.define_instance_method('space_before=')

    klass.define_instance_method('to_h')

    klass.define_instance_method('to_hash')
  end

  defs.define_constant('JSON::Ext::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('parse')

    klass.define_instance_method('quirks_mode?')

    klass.define_instance_method('source')
  end

  defs.define_constant('JSON::FAST_STATE_PROTOTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::GeneratorError') do |klass|
    klass.inherits(defs.constant_proxy('JSON::JSONError', RubyLint.registry))

  end

  defs.define_constant('JSON::GenericObject') do |klass|
    klass.inherits(defs.constant_proxy('OpenStruct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('dump') do |method|
      method.define_argument('obj')
      method.define_rest_argument('args')
    end

    klass.define_method('from_hash') do |method|
      method.define_argument('object')
    end

    klass.define_method('json_creatable=')

    klass.define_method('json_creatable?')

    klass.define_method('json_create') do |method|
      method.define_argument('data')
    end

    klass.define_method('load') do |method|
      method.define_argument('source')
      method.define_optional_argument('proc')
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('as_json') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('to_hash')

    klass.define_instance_method('to_json') do |method|
      method.define_rest_argument('a')
    end

    klass.define_instance_method('|') do |method|
      method.define_argument('other')
    end
  end

  defs.define_constant('JSON::GenericObject::InspectKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::Infinity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::JSONError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_method('wrap') do |method|
      method.define_argument('exception')
    end
  end

  defs.define_constant('JSON::JSON_LOADED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::MinusInfinity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::MissingUnicodeSupport') do |klass|
    klass.inherits(defs.constant_proxy('JSON::JSONError', RubyLint.registry))

  end

  defs.define_constant('JSON::NaN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::NestingError') do |klass|
    klass.inherits(defs.constant_proxy('JSON::ParserError', RubyLint.registry))

  end

  defs.define_constant('JSON::PRETTY_STATE_PROTOTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('parse')

    klass.define_instance_method('quirks_mode?')

    klass.define_instance_method('source')
  end

  defs.define_constant('JSON::ParserError') do |klass|
    klass.inherits(defs.constant_proxy('JSON::JSONError', RubyLint.registry))

  end

  defs.define_constant('JSON::SAFE_STATE_PROTOTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::State') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('from_state')

    klass.define_instance_method('[]')

    klass.define_instance_method('[]=')

    klass.define_instance_method('allow_nan?')

    klass.define_instance_method('array_nl')

    klass.define_instance_method('array_nl=')

    klass.define_instance_method('ascii_only?')

    klass.define_instance_method('buffer_initial_length')

    klass.define_instance_method('buffer_initial_length=')

    klass.define_instance_method('check_circular?')

    klass.define_instance_method('configure')

    klass.define_instance_method('depth')

    klass.define_instance_method('depth=')

    klass.define_instance_method('generate')

    klass.define_instance_method('indent')

    klass.define_instance_method('indent=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('max_nesting')

    klass.define_instance_method('max_nesting=')

    klass.define_instance_method('merge')

    klass.define_instance_method('object_nl')

    klass.define_instance_method('object_nl=')

    klass.define_instance_method('quirks_mode')

    klass.define_instance_method('quirks_mode=')

    klass.define_instance_method('quirks_mode?')

    klass.define_instance_method('space')

    klass.define_instance_method('space=')

    klass.define_instance_method('space_before')

    klass.define_instance_method('space_before=')

    klass.define_instance_method('to_h')

    klass.define_instance_method('to_hash')
  end

  defs.define_constant('JSON::UnparserError') do |klass|
    klass.inherits(defs.constant_proxy('JSON::JSONError', RubyLint.registry))

  end

  defs.define_constant('JSON::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::VERSION_ARRAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::VERSION_BUILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::VERSION_MAJOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('JSON::VERSION_MINOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
