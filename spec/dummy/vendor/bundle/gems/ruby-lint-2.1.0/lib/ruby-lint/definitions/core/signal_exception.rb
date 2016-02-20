# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('SignalException') do |defs|
  defs.define_constant('SignalException') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('signo')
      method.define_optional_argument('signm')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signm')

    klass.define_instance_method('signo')
  end
end
