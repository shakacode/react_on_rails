# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Fiber') do |defs|
  defs.define_constant('Fiber') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('callable')
    end

    klass.define_method('current')

    klass.define_method('new') do |method|
      method.define_optional_argument('size')

      method.returns { |object| object.instance }
    end

    klass.define_method('yield') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('alive?')

    klass.define_instance_method('resume') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('transfer') do |method|
      method.define_rest_argument('args')
    end
  end
end
