# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Proc') do |defs|
  defs.define_constant('Proc') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Unmarshalable', RubyLint.registry))

    klass.define_method('__allocate__')

    klass.define_method('__from_block__') do |method|
      method.define_argument('env')
    end

    klass.define_method('__from_method__') do |method|
      method.define_argument('meth')
    end

    klass.define_method('allocate')

    klass.define_method('from_method') do |method|
      method.define_argument('meth')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('===') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('__yield__') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('arity')

    klass.define_instance_method('binding')

    klass.define_instance_method('block')

    klass.define_instance_method('block=')

    klass.define_instance_method('bound_method')

    klass.define_instance_method('bound_method=')

    klass.define_instance_method('call') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('call_on_object') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('call_prim') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('clone')

    klass.define_instance_method('curry') do |method|
      method.define_optional_argument('curried_arity')
    end

    klass.define_instance_method('dup')

    klass.define_instance_method('inspect')

    klass.define_instance_method('lambda?')

    klass.define_instance_method('lambda_style!')

    klass.define_instance_method('parameters')

    klass.define_instance_method('ruby_method')

    klass.define_instance_method('ruby_method=')

    klass.define_instance_method('source_location')

    klass.define_instance_method('to_proc')

    klass.define_instance_method('to_s')

    klass.define_instance_method('yield') do |method|
      method.define_rest_argument('args')
    end
  end
end
