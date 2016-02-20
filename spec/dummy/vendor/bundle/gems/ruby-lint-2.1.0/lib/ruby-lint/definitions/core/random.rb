# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Random') do |defs|
  defs.define_constant('Random') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new_seed')

    klass.define_method('rand') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_method('srand') do |method|
      method.define_optional_argument('seed')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('bytes') do |method|
      method.define_argument('length')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('seed')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('rand') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('seed')
  end
end
