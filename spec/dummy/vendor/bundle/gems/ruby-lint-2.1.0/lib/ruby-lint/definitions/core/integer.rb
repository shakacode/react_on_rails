# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Integer') do |defs|
  defs.define_constant('Integer') do |klass|
    klass.inherits(defs.constant_proxy('Numeric', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Precision', RubyLint.registry))

    klass.define_method('each_prime') do |method|
      method.define_argument('ubound')
      method.define_block_argument('block')
    end

    klass.define_method('from_prime_division') do |method|
      method.define_argument('pd')
    end

    klass.define_method('induced_from') do |method|
      method.define_argument('obj')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('&') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('**') do |method|
      method.define_argument('exp')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('index')
    end

    klass.define_instance_method('^') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('ceil')

    klass.define_instance_method('chr') do |method|
      method.define_optional_argument('enc')
    end

    klass.define_instance_method('denominator')

    klass.define_instance_method('downto') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('even?')

    klass.define_instance_method('floor')

    klass.define_instance_method('gcd') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('gcdlcm') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('integer?')

    klass.define_instance_method('lcm') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('magnitude')

    klass.define_instance_method('next')

    klass.define_instance_method('numerator')

    klass.define_instance_method('odd?')

    klass.define_instance_method('ord')

    klass.define_instance_method('pred')

    klass.define_instance_method('prime?')

    klass.define_instance_method('prime_division') do |method|
      method.define_optional_argument('generator')
    end

    klass.define_instance_method('rationalize') do |method|
      method.define_optional_argument('eps')
    end

    klass.define_instance_method('round') do |method|
      method.define_optional_argument('ndigits')
    end

    klass.define_instance_method('succ')

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('times')

    klass.define_instance_method('to_bn')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_int')

    klass.define_instance_method('to_r')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('truncate')

    klass.define_instance_method('upto') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('|') do |method|
      method.define_argument('other')
    end
  end
end
