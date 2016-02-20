# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('Arel') do |defs|
  defs.define_constant('Arel') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('sql') do |method|
      method.define_argument('raw_sql')
    end

    klass.define_method('star')
  end

  defs.define_constant('Arel::AliasPredication') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as') do |method|
      method.define_argument('other')
    end
  end

  defs.define_constant('Arel::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('lower')
  end

  defs.define_constant('Arel::Attributes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('for') do |method|
      method.define_argument('column')
    end
  end

  defs.define_constant('Arel::Attributes::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('lower')
  end

  defs.define_constant('Arel::Attributes::Attribute::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::Attribute::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::Attribute::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::Attribute::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Attribute::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::Attribute::Tms') do |klass|
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

  defs.define_constant('Arel::Attributes::Boolean') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Attributes::Attribute', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Boolean::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::Boolean::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::Boolean::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::Boolean::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Boolean::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::Boolean::Tms') do |klass|
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

  defs.define_constant('Arel::Attributes::Decimal') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Attributes::Attribute', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Decimal::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::Decimal::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::Decimal::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::Decimal::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Decimal::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::Decimal::Tms') do |klass|
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

  defs.define_constant('Arel::Attributes::Float') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Attributes::Attribute', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Float::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::Float::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::Float::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::Float::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Float::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::Float::Tms') do |klass|
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

  defs.define_constant('Arel::Attributes::Integer') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Attributes::Attribute', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Integer::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::Integer::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::Integer::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::Integer::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Integer::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::Integer::Tms') do |klass|
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

  defs.define_constant('Arel::Attributes::String') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Attributes::Attribute', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::String::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::String::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::String::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::String::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::String::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::String::Tms') do |klass|
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

  defs.define_constant('Arel::Attributes::Time') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Attributes::Attribute', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Time::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::Time::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::Time::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::Time::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Time::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::Time::Tms') do |klass|
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

  defs.define_constant('Arel::Attributes::Undefined') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Attributes::Attribute', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Undefined::Enumerator') do |klass|
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

  defs.define_constant('Arel::Attributes::Undefined::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Attributes::Undefined::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Attributes::Undefined::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Attributes::Undefined::SortedElement') do |klass|
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

  defs.define_constant('Arel::Attributes::Undefined::Tms') do |klass|
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

  defs.define_constant('Arel::Compatibility') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Compatibility::Wheres') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('engine')
      method.define_argument('collection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Compatibility::Wheres::Enumerator') do |klass|
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

  defs.define_constant('Arel::Compatibility::Wheres::SortedElement') do |klass|
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

  defs.define_constant('Arel::Compatibility::Wheres::Value') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('name')

    klass.define_instance_method('value')

    klass.define_instance_method('visitor')

    klass.define_instance_method('visitor=')
  end

  defs.define_constant('Arel::Crud') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('compile_delete')

    klass.define_instance_method('compile_insert') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('compile_update') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('create_insert')

    klass.define_instance_method('delete')

    klass.define_instance_method('insert') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('update') do |method|
      method.define_argument('values')
    end
  end

  defs.define_constant('Arel::DeleteManager') do |klass|
    klass.inherits(defs.constant_proxy('Arel::TreeManager', RubyLint.registry))

    klass.define_instance_method('from') do |method|
      method.define_argument('relation')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('engine')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('wheres=') do |method|
      method.define_argument('list')
    end
  end

  defs.define_constant('Arel::Expression') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Expressions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('average')

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('distinct')
    end

    klass.define_instance_method('extract') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('sum')
  end

  defs.define_constant('Arel::FactoryMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create_and') do |method|
      method.define_argument('clauses')
    end

    klass.define_instance_method('create_false')

    klass.define_instance_method('create_join') do |method|
      method.define_argument('to')
      method.define_optional_argument('constraint')
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('create_on') do |method|
      method.define_argument('expr')
    end

    klass.define_instance_method('create_string_join') do |method|
      method.define_argument('to')
    end

    klass.define_instance_method('create_table_alias') do |method|
      method.define_argument('relation')
      method.define_argument('name')
    end

    klass.define_instance_method('create_true')

    klass.define_instance_method('grouping') do |method|
      method.define_argument('expr')
    end

    klass.define_instance_method('lower') do |method|
      method.define_argument('column')
    end
  end

  defs.define_constant('Arel::InnerJoin') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Join', RubyLint.registry))

  end

  defs.define_constant('Arel::InsertManager') do |klass|
    klass.inherits(defs.constant_proxy('Arel::TreeManager', RubyLint.registry))

    klass.define_instance_method('columns')

    klass.define_instance_method('create_values') do |method|
      method.define_argument('values')
      method.define_argument('columns')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('engine')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('fields')
    end

    klass.define_instance_method('into') do |method|
      method.define_argument('table')
    end

    klass.define_instance_method('values=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Arel::Math') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('*') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('/') do |method|
      method.define_argument('other')
    end
  end

  defs.define_constant('Arel::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::FactoryMethods', RubyLint.registry))

    klass.define_instance_method('and') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('not')

    klass.define_instance_method('or') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('to_sql') do |method|
      method.define_optional_argument('engine')
    end
  end

  defs.define_constant('Arel::Nodes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Addition') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::InfixOperation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_argument('right')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Addition::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Addition::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::And') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('children')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('children')
      method.define_optional_argument('right')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('left')

    klass.define_instance_method('right')
  end

  defs.define_constant('Arel::Nodes::And::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::And::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::As') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::As::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::As::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Ascending') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Ordering', RubyLint.registry))

    klass.define_instance_method('ascending?')

    klass.define_instance_method('descending?')

    klass.define_instance_method('direction')

    klass.define_instance_method('reverse')
  end

  defs.define_constant('Arel::Nodes::Ascending::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Ascending::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Assignment') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Assignment::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Assignment::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Avg') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Function', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Avg::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Avg::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Between') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Between::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Between::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Bin') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Bin::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Bin::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Binary') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_argument('right')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('left')

    klass.define_instance_method('left=')

    klass.define_instance_method('right')

    klass.define_instance_method('right=')
  end

  defs.define_constant('Arel::Nodes::Binary::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Binary::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::BindParam') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::SqlLiteral', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::BindParam::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::BindParam::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::BindParam::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::BindParam::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('Arel::Nodes::BindParam::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Count') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Function', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('expr')
      method.define_optional_argument('distinct')
      method.define_optional_argument('aliaz')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Count::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Count::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::CurrentRow') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')
  end

  defs.define_constant('Arel::Nodes::CurrentRow::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::CurrentRow::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::DeleteStatement') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('relation')
      method.define_optional_argument('wheres')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')

    klass.define_instance_method('wheres')

    klass.define_instance_method('wheres=')
  end

  defs.define_constant('Arel::Nodes::DeleteStatement::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::DeleteStatement::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Descending') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Ordering', RubyLint.registry))

    klass.define_instance_method('ascending?')

    klass.define_instance_method('descending?')

    klass.define_instance_method('direction')

    klass.define_instance_method('reverse')
  end

  defs.define_constant('Arel::Nodes::Descending::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Descending::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Distinct') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')
  end

  defs.define_constant('Arel::Nodes::Distinct::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Distinct::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::DistinctOn') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::DistinctOn::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::DistinctOn::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Division') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::InfixOperation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_argument('right')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Division::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Division::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::DoesNotMatch') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::DoesNotMatch::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::DoesNotMatch::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Equality') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

    klass.define_instance_method('operand1')

    klass.define_instance_method('operand2')

    klass.define_instance_method('operator')
  end

  defs.define_constant('Arel::Nodes::Equality::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Equality::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Except') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Except::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Except::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Exists') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Function', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Exists::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Exists::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Extract') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Predications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Expression', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::OrderPredications', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('alias')

    klass.define_instance_method('alias=')

    klass.define_instance_method('as') do |method|
      method.define_argument('aliaz')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('field')

    klass.define_instance_method('field=')

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('expr')
      method.define_argument('field')
      method.define_optional_argument('aliaz')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Extract::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Extract::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::False') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')
  end

  defs.define_constant('Arel::Nodes::False::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::False::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Following') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('expr')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Following::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Following::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Function') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::WindowPredications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Predications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Expression', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::OrderPredications', RubyLint.registry))

    klass.define_instance_method('alias')

    klass.define_instance_method('alias=')

    klass.define_instance_method('as') do |method|
      method.define_argument('aliaz')
    end

    klass.define_instance_method('distinct')

    klass.define_instance_method('distinct=')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('expressions')

    klass.define_instance_method('expressions=')

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('expr')
      method.define_optional_argument('aliaz')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Function::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Function::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::GreaterThan') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::GreaterThan::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::GreaterThan::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::GreaterThanOrEqual') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::GreaterThanOrEqual::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::GreaterThanOrEqual::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Group') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Group::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Group::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Grouping') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Predications', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Grouping::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Grouping::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Having') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Having::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Having::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::In') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Equality', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::In::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::In::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::InfixOperation') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Math', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::AliasPredication', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::OrderPredications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Predications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Expressions', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('operator')
      method.define_argument('left')
      method.define_argument('right')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('operator')
  end

  defs.define_constant('Arel::Nodes::InfixOperation::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::InfixOperation::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::InnerJoin') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Join', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::InnerJoin::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::InnerJoin::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::InsertStatement') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('columns')

    klass.define_instance_method('columns=')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize')

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')

    klass.define_instance_method('values')

    klass.define_instance_method('values=')
  end

  defs.define_constant('Arel::Nodes::InsertStatement::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::InsertStatement::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Intersect') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Intersect::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Intersect::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Join') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Join::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Join::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::JoinSource') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

    klass.define_instance_method('empty?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('single_source')
      method.define_optional_argument('joinop')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::JoinSource::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::JoinSource::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::LessThan') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::LessThan::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::LessThan::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::LessThanOrEqual') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::LessThanOrEqual::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::LessThanOrEqual::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Limit') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Limit::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Limit::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Lock') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Lock::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Lock::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Matches') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Matches::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Matches::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Max') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Function', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Max::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Max::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Min') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Function', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Min::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Min::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Multiplication') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::InfixOperation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_argument('right')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Multiplication::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Multiplication::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::NamedFunction') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Function', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('expr')
      method.define_optional_argument('aliaz')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')
  end

  defs.define_constant('Arel::Nodes::NamedFunction::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::NamedFunction::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::NamedWindow') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Window', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')
  end

  defs.define_constant('Arel::Nodes::NamedWindow::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::NamedWindow::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::FactoryMethods', RubyLint.registry))

    klass.define_instance_method('and') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('not')

    klass.define_instance_method('or') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('to_sql') do |method|
      method.define_optional_argument('engine')
    end
  end

  defs.define_constant('Arel::Nodes::Node::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Node::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Not') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Not::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Not::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::NotEqual') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::NotEqual::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::NotEqual::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::NotIn') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::NotIn::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::NotIn::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Offset') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Offset::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Offset::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::On') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::On::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::On::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Or') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Or::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Or::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Ordering') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Ordering::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Ordering::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::OuterJoin') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Join', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::OuterJoin::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::OuterJoin::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Over') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::AliasPredication', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_optional_argument('right')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('operator')
  end

  defs.define_constant('Arel::Nodes::Over::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Over::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Preceding') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('expr')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Preceding::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Preceding::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Range') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('expr')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Range::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Range::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Rows') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('expr')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Rows::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Rows::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::SelectCore') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('from')

    klass.define_instance_method('from=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('froms')

    klass.define_instance_method('froms=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('groups')

    klass.define_instance_method('groups=')

    klass.define_instance_method('hash')

    klass.define_instance_method('having')

    klass.define_instance_method('having=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('projections')

    klass.define_instance_method('projections=')

    klass.define_instance_method('set_quantifier')

    klass.define_instance_method('set_quantifier=')

    klass.define_instance_method('source')

    klass.define_instance_method('source=')

    klass.define_instance_method('top')

    klass.define_instance_method('top=')

    klass.define_instance_method('wheres')

    klass.define_instance_method('wheres=')

    klass.define_instance_method('windows')

    klass.define_instance_method('windows=')
  end

  defs.define_constant('Arel::Nodes::SelectCore::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::SelectCore::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::SelectStatement') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('cores')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('cores')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('limit')

    klass.define_instance_method('limit=')

    klass.define_instance_method('lock')

    klass.define_instance_method('lock=')

    klass.define_instance_method('offset')

    klass.define_instance_method('offset=')

    klass.define_instance_method('orders')

    klass.define_instance_method('orders=')

    klass.define_instance_method('with')

    klass.define_instance_method('with=')
  end

  defs.define_constant('Arel::Nodes::SelectStatement::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::SelectStatement::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::SqlLiteral') do |klass|
    klass.inherits(defs.constant_proxy('String', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::OrderPredications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::AliasPredication', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Predications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Expressions', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::SqlLiteral::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::SqlLiteral::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::SqlLiteral::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::SqlLiteral::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('Arel::Nodes::SqlLiteral::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::StringJoin') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Join', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_optional_argument('right')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::StringJoin::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::StringJoin::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Subtraction') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::InfixOperation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('left')
      method.define_argument('right')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Subtraction::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Subtraction::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Sum') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Function', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Sum::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Sum::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::TableAlias') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('engine')

    klass.define_instance_method('name')

    klass.define_instance_method('relation')

    klass.define_instance_method('table_alias')

    klass.define_instance_method('table_name')
  end

  defs.define_constant('Arel::Nodes::TableAlias::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::TableAlias::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Top') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Top::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Top::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::True') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')
  end

  defs.define_constant('Arel::Nodes::True::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::True::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Unary') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('expr')

    klass.define_instance_method('expr=')

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('expr')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('value')
  end

  defs.define_constant('Arel::Nodes::Unary::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Unary::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Union') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::Union::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Union::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::UnionAll') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::UnionAll::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::UnionAll::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::UnqualifiedColumn') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('attribute')

    klass.define_instance_method('attribute=')

    klass.define_instance_method('column')

    klass.define_instance_method('name')

    klass.define_instance_method('relation')
  end

  defs.define_constant('Arel::Nodes::UnqualifiedColumn::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::UnqualifiedColumn::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::UpdateStatement') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize')

    klass.define_instance_method('key')

    klass.define_instance_method('key=')

    klass.define_instance_method('limit')

    klass.define_instance_method('limit=')

    klass.define_instance_method('orders')

    klass.define_instance_method('orders=')

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')

    klass.define_instance_method('values')

    klass.define_instance_method('values=')

    klass.define_instance_method('wheres')

    klass.define_instance_method('wheres=')
  end

  defs.define_constant('Arel::Nodes::UpdateStatement::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::UpdateStatement::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Values') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Binary', RubyLint.registry))

    klass.define_instance_method('columns')

    klass.define_instance_method('columns=')

    klass.define_instance_method('expressions')

    klass.define_instance_method('expressions=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('exprs')
      method.define_optional_argument('columns')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Nodes::Values::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Values::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::Window') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Node', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Expression', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::OrderPredications', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('frame') do |method|
      method.define_argument('expr')
    end

    klass.define_instance_method('framing')

    klass.define_instance_method('framing=')

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize')

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('expr')
    end

    klass.define_instance_method('orders')

    klass.define_instance_method('orders=')

    klass.define_instance_method('range') do |method|
      method.define_optional_argument('expr')
    end

    klass.define_instance_method('rows') do |method|
      method.define_optional_argument('expr')
    end
  end

  defs.define_constant('Arel::Nodes::Window::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::Window::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::With') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Unary', RubyLint.registry))

    klass.define_instance_method('children')
  end

  defs.define_constant('Arel::Nodes::With::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::With::SortedElement') do |klass|
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

  defs.define_constant('Arel::Nodes::WithRecursive') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::With', RubyLint.registry))

  end

  defs.define_constant('Arel::Nodes::WithRecursive::Enumerator') do |klass|
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

  defs.define_constant('Arel::Nodes::WithRecursive::SortedElement') do |klass|
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

  defs.define_constant('Arel::OrderPredications') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('asc')

    klass.define_instance_method('desc')
  end

  defs.define_constant('Arel::OuterJoin') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::Join', RubyLint.registry))

  end

  defs.define_constant('Arel::Predications') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('does_not_match') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('does_not_match_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('does_not_match_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('eq') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eq_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('eq_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('gt') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('gt_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('gt_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('gteq') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('gteq_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('gteq_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('in') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('in_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('in_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('lt') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('lt_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('lt_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('lteq') do |method|
      method.define_argument('right')
    end

    klass.define_instance_method('lteq_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('lteq_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('matches') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('matches_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('matches_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('not_eq') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('not_eq_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('not_eq_any') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('not_in') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('not_in_all') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('not_in_any') do |method|
      method.define_argument('others')
    end
  end

  defs.define_constant('Arel::SelectManager') do |klass|
    klass.inherits(defs.constant_proxy('Arel::TreeManager', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Crud', RubyLint.registry))

    klass.define_instance_method('as') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('constraints')

    klass.define_instance_method('distinct') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('except') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('exists')

    klass.define_instance_method('from') do |method|
      method.define_argument('table')
    end

    klass.define_instance_method('froms')

    klass.define_instance_method('group') do |method|
      method.define_rest_argument('columns')
    end

    klass.define_instance_method('having') do |method|
      method.define_rest_argument('exprs')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('engine')
      method.define_optional_argument('table')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('intersect') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('join') do |method|
      method.define_argument('relation')
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('join_sources')

    klass.define_instance_method('join_sql')

    klass.define_instance_method('joins') do |method|
      method.define_argument('manager')
    end

    klass.define_instance_method('limit')

    klass.define_instance_method('limit=') do |method|
      method.define_argument('limit')
    end

    klass.define_instance_method('lock') do |method|
      method.define_optional_argument('locking')
    end

    klass.define_instance_method('locked')

    klass.define_instance_method('minus') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('offset')

    klass.define_instance_method('offset=') do |method|
      method.define_argument('amount')
    end

    klass.define_instance_method('on') do |method|
      method.define_rest_argument('exprs')
    end

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('expr')
    end

    klass.define_instance_method('order_clauses')

    klass.define_instance_method('orders')

    klass.define_instance_method('project') do |method|
      method.define_rest_argument('projections')
    end

    klass.define_instance_method('projections')

    klass.define_instance_method('projections=') do |method|
      method.define_argument('projections')
    end

    klass.define_instance_method('skip') do |method|
      method.define_argument('amount')
    end

    klass.define_instance_method('source')

    klass.define_instance_method('take') do |method|
      method.define_argument('limit')
    end

    klass.define_instance_method('taken')

    klass.define_instance_method('to_a')

    klass.define_instance_method('union') do |method|
      method.define_argument('operation')
      method.define_optional_argument('other')
    end

    klass.define_instance_method('where_clauses')

    klass.define_instance_method('where_sql')

    klass.define_instance_method('wheres')

    klass.define_instance_method('window') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('with') do |method|
      method.define_rest_argument('subqueries')
    end
  end

  defs.define_constant('Arel::SelectManager::Row') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('id')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Arel::SelectManager::Row::Enumerator') do |klass|
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

  defs.define_constant('Arel::SelectManager::Row::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::SelectManager::Row::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::SelectManager::Row::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::SelectManager::Row::SortedElement') do |klass|
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

  defs.define_constant('Arel::SelectManager::Row::Tms') do |klass|
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

  defs.define_constant('Arel::Sql') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Sql::Engine') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_argument('thing')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::SqlLiteral') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Nodes::SqlLiteral', RubyLint.registry))

  end

  defs.define_constant('Arel::SqlLiteral::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::SqlLiteral::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::SqlLiteral::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::SqlLiteral::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('Arel::SqlLiteral::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Table') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::FactoryMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::Crud', RubyLint.registry))

    klass.define_method('engine')

    klass.define_method('engine=')

    klass.define_method('table_cache') do |method|
      method.define_argument('engine')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('alias') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('aliases')

    klass.define_instance_method('aliases=')

    klass.define_instance_method('columns')

    klass.define_instance_method('engine')

    klass.define_instance_method('engine=')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('from') do |method|
      method.define_argument('table')
    end

    klass.define_instance_method('group') do |method|
      method.define_rest_argument('columns')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('having') do |method|
      method.define_argument('expr')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_optional_argument('engine')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_manager')

    klass.define_instance_method('join') do |method|
      method.define_argument('relation')
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('joins') do |method|
      method.define_argument('manager')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('expr')
    end

    klass.define_instance_method('primary_key')

    klass.define_instance_method('project') do |method|
      method.define_rest_argument('things')
    end

    klass.define_instance_method('select_manager')

    klass.define_instance_method('skip') do |method|
      method.define_argument('amount')
    end

    klass.define_instance_method('table_alias')

    klass.define_instance_method('table_alias=')

    klass.define_instance_method('table_name')

    klass.define_instance_method('take') do |method|
      method.define_argument('amount')
    end

    klass.define_instance_method('where') do |method|
      method.define_argument('condition')
    end
  end

  defs.define_constant('Arel::TreeManager') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Arel::FactoryMethods', RubyLint.registry))

    klass.define_instance_method('ast')

    klass.define_instance_method('engine')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('engine')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_dot')

    klass.define_instance_method('to_sql')

    klass.define_instance_method('visitor')

    klass.define_instance_method('where') do |method|
      method.define_argument('expr')
    end
  end

  defs.define_constant('Arel::UpdateManager') do |klass|
    klass.inherits(defs.constant_proxy('Arel::TreeManager', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('engine')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key')

    klass.define_instance_method('key=') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('expr')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('table') do |method|
      method.define_argument('table')
    end

    klass.define_instance_method('take') do |method|
      method.define_argument('limit')
    end

    klass.define_instance_method('where') do |method|
      method.define_argument('expr')
    end

    klass.define_instance_method('wheres=') do |method|
      method.define_argument('exprs')
    end
  end

  defs.define_constant('Arel::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('for') do |method|
      method.define_argument('engine')
    end

    klass.define_method('visitor_for') do |method|
      method.define_argument('engine')
    end
  end

  defs.define_constant('Arel::Visitors::DepthFirst') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('block')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Visitors::DepthFirst::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Dot') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Arel::Visitors::Dot::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Dot::Edge') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Dot::Edge::Enumerator') do |klass|
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

  defs.define_constant('Arel::Visitors::Dot::Edge::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Arel::Visitors::Dot::Edge::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Arel::Visitors::Dot::Edge::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Dot::Edge::SortedElement') do |klass|
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

  defs.define_constant('Arel::Visitors::Dot::Edge::Tms') do |klass|
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

  defs.define_constant('Arel::Visitors::Dot::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('fields')

    klass.define_instance_method('fields=')

    klass.define_instance_method('id')

    klass.define_instance_method('id=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_optional_argument('fields')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')
  end

  defs.define_constant('Arel::Visitors::ENGINE_VISITORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::IBM_DB::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Informix::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::JoinSql') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MSSQL::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::MySQL::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Oracle::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::OrderClauses::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::PostgreSQL::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::SQLite::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::Visitor', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('connection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Arel::Visitors::ToSql::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::ToSql::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::VISITORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::Visitor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Arel::Visitors::Visitor::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql') do |klass|
    klass.inherits(defs.constant_proxy('Arel::Visitors::ToSql', RubyLint.registry))

    klass.define_instance_method('visit_Arel_Nodes_SelectCore') do |method|
      method.define_argument('o')
      method.define_argument('a')
    end
  end

  defs.define_constant('Arel::Visitors::WhereSql::AND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::COMMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::DISTINCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::GROUP_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::ORDER_BY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::WHERE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::Visitors::WhereSql::WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Arel::WindowPredications') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('over') do |method|
      method.define_optional_argument('expr')
    end
  end
end
