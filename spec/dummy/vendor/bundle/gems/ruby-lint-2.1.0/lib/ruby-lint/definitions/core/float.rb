# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Float') do |defs|
  defs.define_constant('Float') do |klass|
    klass.inherits(defs.constant_proxy('Numeric', RubyLint.registry))
    klass.inherits(defs.constant_proxy('JSON::Ext::Generator::GeneratorMethods::Float', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Precision', RubyLint.registry))

    klass.define_method('induced_from') do |method|
      method.define_argument('obj')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('%') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('*') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('**') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-@')

    klass.define_instance_method('/') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('abs')

    klass.define_instance_method('angle')

    klass.define_instance_method('arg')

    klass.define_instance_method('ceil')

    klass.define_instance_method('coerce') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('denominator')

    klass.define_instance_method('divide') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('divmod') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('dtoa')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('fdiv') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('finite?')

    klass.define_instance_method('floor')

    klass.define_instance_method('imaginary')

    klass.define_instance_method('infinite?')

    klass.define_instance_method('inspect')

    klass.define_instance_method('magnitude')

    klass.define_instance_method('modulo') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('nan?')

    klass.define_instance_method('negative?')

    klass.define_instance_method('numerator')

    klass.define_instance_method('phase')

    klass.define_instance_method('power!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('quo') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('rationalize') do |method|
      method.define_optional_argument('eps')
    end

    klass.define_instance_method('round') do |method|
      method.define_optional_argument('ndigits')
    end

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_f')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_int')

    klass.define_instance_method('to_packed') do |method|
      method.define_argument('size')
    end

    klass.define_instance_method('to_r')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_s_minimal')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('truncate')
  end

  defs.define_constant('Float::DIG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::EPSILON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::FFI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_typedef') do |method|
      method.define_argument('current')
      method.define_argument('add')
    end

    klass.define_method('config') do |method|
      method.define_argument('name')
    end

    klass.define_method('config_hash') do |method|
      method.define_argument('name')
    end

    klass.define_method('errno')

    klass.define_method('find_type') do |method|
      method.define_argument('name')
    end

    klass.define_method('generate_function') do |method|
      method.define_argument('ptr')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('generate_trampoline') do |method|
      method.define_argument('obj')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('size_to_type') do |method|
      method.define_argument('size')
    end

    klass.define_method('type_size') do |method|
      method.define_argument('type')
    end
  end

  defs.define_constant('Float::INFINITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::MANT_DIG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::MAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::MAX_10_EXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::MAX_EXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::MIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::MIN_10_EXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::MIN_EXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::NAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::RADIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Float::ROUNDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
