# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('WeakRef') do |defs|
  defs.define_constant('WeakRef') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_argument('obj')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('__getobj__')

    klass.define_instance_method('__object__')

    klass.define_instance_method('__setobj__') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('respond_to_missing?') do |method|
      method.define_argument('method')
      method.define_argument('include_private')
    end

    klass.define_instance_method('weakref_alive?')
  end

  defs.define_constant('WeakRef::RefError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end
end
