# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('ConditionVariable') do |defs|
  defs.define_constant('ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('initialize')

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_argument('mutex')
      method.define_optional_argument('timeout')
    end
  end
end
