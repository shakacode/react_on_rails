# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('OpenStruct') do |defs|
  defs.define_constant('OpenStruct') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('delete_field') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('mid')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('modifiable')

    klass.define_instance_method('new_ostruct_member') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('table')

    klass.define_instance_method('to_h')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('OpenStruct::InspectKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
