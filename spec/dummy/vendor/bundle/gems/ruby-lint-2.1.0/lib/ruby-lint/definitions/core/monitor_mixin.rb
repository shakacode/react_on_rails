# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('MonitorMixin') do |defs|
  defs.define_constant('MonitorMixin') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extend_object') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('mon_enter')

    klass.define_instance_method('mon_exit')

    klass.define_instance_method('mon_synchronize')

    klass.define_instance_method('mon_try_enter')

    klass.define_instance_method('new_cond')

    klass.define_instance_method('synchronize')

    klass.define_instance_method('try_mon_enter')
  end

  defs.define_constant('MonitorMixin::ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('monitor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('wait_until')

    klass.define_instance_method('wait_while')
  end

  defs.define_constant('MonitorMixin::ConditionVariable::Timeout') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end
end
