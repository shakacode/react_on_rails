# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('SizedQueue') do |defs|
  defs.define_constant('SizedQueue') do |klass|
    klass.inherits(defs.constant_proxy('Queue', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('deq') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('enq') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('max')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('max')

    klass.define_instance_method('max=') do |method|
      method.define_argument('max')
    end

    klass.define_instance_method('num_waiting')

    klass.define_instance_method('pop') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('shift') do |method|
      method.define_rest_argument('args')
    end
  end
end
