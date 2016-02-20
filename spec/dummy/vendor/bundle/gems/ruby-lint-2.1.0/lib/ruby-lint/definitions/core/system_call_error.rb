# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('SystemCallError') do |defs|
  defs.define_constant('SystemCallError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_method('errno_error') do |method|
      method.define_argument('message')
      method.define_argument('errno')
    end

    klass.define_method('exception') do |method|
      method.define_optional_argument('message')
      method.define_optional_argument('errno')
    end

    klass.define_method('new') do |method|
      method.define_optional_argument('message')
      method.define_optional_argument('errno')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('errno')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end
end
