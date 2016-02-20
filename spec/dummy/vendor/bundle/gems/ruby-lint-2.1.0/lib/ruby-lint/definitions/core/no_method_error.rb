# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('NoMethodError') do |defs|
  defs.define_constant('NoMethodError') do |klass|
    klass.inherits(defs.constant_proxy('NameError', RubyLint.registry))

    klass.define_instance_method('args')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arguments')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')
  end
end
