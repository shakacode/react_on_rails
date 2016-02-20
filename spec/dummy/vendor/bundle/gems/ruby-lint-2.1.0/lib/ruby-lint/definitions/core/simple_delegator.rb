# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('SimpleDelegator') do |defs|
  defs.define_constant('SimpleDelegator') do |klass|
    klass.inherits(defs.constant_proxy('Delegator', RubyLint.registry))

    klass.define_instance_method('__getobj__')

    klass.define_instance_method('__setobj__') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('SimpleDelegator::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
