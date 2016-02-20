# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Delegator') do |defs|
  defs.define_constant('Delegator') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Kernel', RubyLint.registry))

    klass.define_method('const_missing') do |method|
      method.define_argument('n')
    end

    klass.define_method('delegating_block') do |method|
      method.define_argument('mid')
    end

    klass.define_method('public_api')

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('__getobj__')

    klass.define_instance_method('__setobj__') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('obj')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('m')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('protected_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('public_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('taint')

    klass.define_instance_method('trust')

    klass.define_instance_method('untaint')

    klass.define_instance_method('untrust')
  end

  defs.define_constant('Delegator::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
