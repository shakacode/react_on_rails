# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Binding') do |defs|
  defs.define_constant('Binding') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('self_context') do |method|
      method.define_argument('recv')
      method.define_argument('variables')
    end

    klass.define_method('setup') do |method|
      method.define_argument('variables')
      method.define_argument('code')
      method.define_argument('constant_scope')
      method.define_optional_argument('recv')
      method.define_optional_argument('location')
    end

    klass.define_instance_method('compiled_code')

    klass.define_instance_method('compiled_code=')

    klass.define_instance_method('constant_scope')

    klass.define_instance_method('constant_scope=')

    klass.define_instance_method('eval') do |method|
      method.define_argument('expr')
      method.define_optional_argument('filename')
      method.define_optional_argument('lineno')
    end

    klass.define_instance_method('from_proc?')

    klass.define_instance_method('line_number')

    klass.define_instance_method('location')

    klass.define_instance_method('location=')

    klass.define_instance_method('proc_environment')

    klass.define_instance_method('proc_environment=')

    klass.define_instance_method('self')

    klass.define_instance_method('self=')

    klass.define_instance_method('variables')

    klass.define_instance_method('variables=')
  end
end
