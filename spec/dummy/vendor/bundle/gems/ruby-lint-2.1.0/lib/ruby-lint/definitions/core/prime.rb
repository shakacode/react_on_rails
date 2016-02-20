# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Prime') do |defs|
  defs.define_constant('Prime') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('instance')

    klass.define_method('int_from_prime_division') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('method_added') do |method|
      method.define_argument('method')
    end

    klass.define_method('prime?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('prime_division') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each') do |method|
      method.define_optional_argument('ubound')
      method.define_optional_argument('generator')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('int_from_prime_division') do |method|
      method.define_argument('pd')
    end

    klass.define_instance_method('prime?') do |method|
      method.define_argument('value')
      method.define_optional_argument('generator')
    end

    klass.define_instance_method('prime_division') do |method|
      method.define_argument('value')
      method.define_optional_argument('generator')
    end
  end

  defs.define_constant('Prime::Enumerator') do |klass|
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

  defs.define_constant('Prime::EratosthenesGenerator') do |klass|
    klass.inherits(defs.constant_proxy('Prime::PseudoPrimeGenerator', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('next')

    klass.define_instance_method('rewind')

    klass.define_instance_method('succ')
  end

  defs.define_constant('Prime::EratosthenesGenerator::Enumerator') do |klass|
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

  defs.define_constant('Prime::EratosthenesGenerator::SortedElement') do |klass|
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

  defs.define_constant('Prime::EratosthenesSieve') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Singleton', RubyLint.registry))

    klass.define_method('instance')

    klass.define_instance_method('get_nth_prime') do |method|
      method.define_argument('n')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Prime::EratosthenesSieve::SingletonClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('clone')
  end

  defs.define_constant('Prime::Generator23') do |klass|
    klass.inherits(defs.constant_proxy('Prime::PseudoPrimeGenerator', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('next')

    klass.define_instance_method('rewind')

    klass.define_instance_method('succ')
  end

  defs.define_constant('Prime::Generator23::Enumerator') do |klass|
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

  defs.define_constant('Prime::Generator23::SortedElement') do |klass|
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

  defs.define_constant('Prime::OldCompatibility') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('next')

    klass.define_instance_method('succ')
  end

  defs.define_constant('Prime::PseudoPrimeGenerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('ubound')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('rewind')

    klass.define_instance_method('succ')

    klass.define_instance_method('upper_bound')

    klass.define_instance_method('upper_bound=') do |method|
      method.define_argument('ubound')
    end

    klass.define_instance_method('with_index') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('with_object') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('Prime::PseudoPrimeGenerator::Enumerator') do |klass|
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

  defs.define_constant('Prime::PseudoPrimeGenerator::SortedElement') do |klass|
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

  defs.define_constant('Prime::SortedElement') do |klass|
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

  defs.define_constant('Prime::TrialDivision') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Singleton', RubyLint.registry))

    klass.define_method('instance')

    klass.define_instance_method('[]') do |method|
      method.define_argument('index')
    end

    klass.define_instance_method('cache')

    klass.define_instance_method('initialize')

    klass.define_instance_method('primes')

    klass.define_instance_method('primes_so_far')
  end

  defs.define_constant('Prime::TrialDivision::SingletonClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('clone')
  end

  defs.define_constant('Prime::TrialDivisionGenerator') do |klass|
    klass.inherits(defs.constant_proxy('Prime::PseudoPrimeGenerator', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('next')

    klass.define_instance_method('rewind')

    klass.define_instance_method('succ')
  end

  defs.define_constant('Prime::TrialDivisionGenerator::Enumerator') do |klass|
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

  defs.define_constant('Prime::TrialDivisionGenerator::SortedElement') do |klass|
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
end
