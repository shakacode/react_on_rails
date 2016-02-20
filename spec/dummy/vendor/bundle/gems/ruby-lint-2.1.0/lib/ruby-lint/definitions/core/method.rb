# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Method') do |defs|
  defs.define_constant('Method') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Unmarshalable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('arity')

    klass.define_instance_method('call') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('defined_in')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('executable')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('receiver')
      method.define_argument('defined_in')
      method.define_argument('executable')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('name')

    klass.define_instance_method('owner')

    klass.define_instance_method('parameters')

    klass.define_instance_method('receiver')

    klass.define_instance_method('source')

    klass.define_instance_method('source_location')

    klass.define_instance_method('to_proc')

    klass.define_instance_method('to_s')

    klass.define_instance_method('unbind')
  end
end
